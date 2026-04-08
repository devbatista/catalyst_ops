class App::OrderServicesController < ApplicationController
  load_and_authorize_resource
  
  before_action :set_other_resources, only: [:edit, :update, :schedule]
  before_action :set_attachment_on_update, only: [:update]
  before_action :can_add_order_service, only: [:create]
  before_action :ensure_direct_order_service_creation_enabled, only: [:new, :create]
  before_action :ensure_technician_only_updates_allowed_fields, only: [:update]
  before_action :restrict_status_update_for_technician, only: [:update_status]
  before_action :restrict_overdue_reschedule_for_technician, only: [:schedule, :perform_schedule]
  before_action :ensure_schedulable_status, only: [:schedule, :perform_schedule]
  
  def index
    @order_services = case current_user.role
    when "admin"
      @order_services.includes(:client, :users)
    when "gestor"
      @order_services.joins(:client)
                     .where(clients: { company_id: current_user.company_id })
                     .includes(:client, :users)
    when "tecnico"
      current_user.order_services.includes(:client)
    end.order(created_at: :desc).page(params[:page]).per(params[:per] || 10)

    if params[:code].present?
      @order_services = @order_services.where(code: params[:code])
    end

    if params[:status].present?
      allowed_statuses = OrderService.statuses.keys
      @order_services = @order_services.where(status: params[:status]) if allowed_statuses.include?(params[:status])
    end
  end

  def show
    @service_items = @order_service.service_items.order(:id)
  end

  def unassigned
    authorize! :read, OrderService

    @order_services = current_user.company.order_services
                                          .includes(:client)
                                          .unassigned
                                          .order(created_at: :desc)
                                          .page(params[:page])
                                          .per(params[:per] || 10)
  end
  
  def overdue
    authorize! :read, OrderService

    @order_services = current_user.company.order_services
                                          .includes(:client)
                                          .overdue
                                          .order(created_at: :desc)
                                          .page(params[:page])
                                          .per(params[:per] || 10)
  end

  def create
    @order_service.created_without_budget = true

    if @order_service.update(order_service_params_with_auto_schedule_status)
      redirect_to app_order_service_url(@order_service), notice: "Ordem de serviço criada com sucesso."
    else
      set_other_resources
      flash.now[:alert] = @order_service.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def new
    @order_service.created_without_budget = true
    set_other_resources
    prefill_client_from_params
  end

  def edit; end

  def update
    if @order_service.update(order_service_params_with_auto_schedule_status)
      set_simultaneous_conflicts_warning
      purge_marked_attachments
      if @attachments.present?
        add_attachs
      else
        redirect_to app_order_service_url(@order_service), notice: "Ordem de serviço atualizada com sucesso."
      end
    else
      @clients = Client.order(:name)
      flash.now[:alert] = @order_service.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order_service.destroy
    redirect_to app_order_services_url, notice: "Ordem de serviço removida com sucesso."
  end

  def schedule;end

  def perform_schedule
    begin
      if @order_service.update(schedule_params)
        set_simultaneous_conflicts_warning
        redirect_to app_order_service_path(@order_service), notice: 'Ordem de Serviço agendada com sucesso.'
      else
        set_other_resources
        flash.now[:alert] = @order_service.errors.full_messages.join(', ')
        render :schedule, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordInvalid => e
      set_other_resources
      all_errors = @order_service.errors.full_messages + (e.record&.errors&.full_messages || [])
      flash.now[:alert] = all_errors.uniq.join(', ')
      render :schedule, status: :unprocessable_entity
    end
  end

  def update_status
    target_status = params[:status].to_s

    unless allowed_status_transition?(target_status)
      return redirect_to app_order_service_url(@order_service), alert: "Transição de status inválida."
    end

    if target_status == "agendada"
      redirect_to schedule_app_order_service_path(@order_service)
    else
      if @order_service.update(status: target_status)
        redirect_to app_order_service_url(@order_service), notice: "Status atualizado com sucesso."
      else
        redirect_to app_order_service_url(@order_service), alert: @order_service.errors.full_messages.join(', ')
      end
    end
  end

  def generate_pdf
    pdf_data = Cmd::Pdf::Create.new(@order_service).generate_pdf_data
    send_data pdf_data,
              filename: "ordem_servico_#{@order_service.id}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end

  def attachments
    @order_service = OrderService.find(params[:id])
    render partial: "app/order_services/attachments", locals: { order_service: @order_service }
  end

  def purge_attachment
    attachment = @order_service.attachments.find(params[:attachment_id])
    attachment.purge
    respond_to do |format|
      format.html { head :ok } # para JS
      format.json { head :ok }
    end
  end

  private

  def order_service_params
    if current_user.gestor?
      params.require(:order_service).permit(
        :title,
        :description,
        :client_id,
        :scheduled_at,
        :expected_end_at,
        :signed_by_client,
        :observations,
        :budget_waiver_reason,
        :budget_waiver_authorized_by,
        :discount_type,
        :discount_value,
        :discount_reason,
        remove_attachment_ids: [],
        attachments: [],
        user_ids: [],
        service_items_attributes: [
          :id, :description, :quantity, :unit_price, :_destroy,
        ],
      )
    else
      params.require(:order_service).permit(
        :observations,
        remove_attachment_ids: [],
        attachments: []
      )
    end
  end

  def order_service_params_with_auto_schedule_status
    permitted_params = order_service_params.except(:remove_attachment_ids)
    return permitted_params unless should_set_status_as_scheduled?(permitted_params)

    permitted_params.merge(status: :agendada)
  end

  def should_set_status_as_scheduled?(permitted_params)
    return false unless current_user.gestor?
    return false unless @order_service.pendente? || @order_service.atrasada?

    scheduled_at_present_after_update?(permitted_params) && technicians_present_after_update?(permitted_params)
  end

  def scheduled_at_present_after_update?(permitted_params)
    if permitted_params.key?(:scheduled_at)
      permitted_params[:scheduled_at].present?
    else
      @order_service.scheduled_at.present?
    end
  end

  def technicians_present_after_update?(permitted_params)
    if permitted_params.key?(:user_ids)
      Array(permitted_params[:user_ids]).reject(&:blank?).any?
    else
      @order_service.user_ids.any?
    end
  end

  def schedule_params
    params.require(:order_service)
          .permit(:scheduled_at, :expected_end_at, user_ids: [])
          .merge(status: :agendada)
  end

  def set_other_resources
    @clients = current_user.clients.order(:name)
    @technicians = current_user.company.users.active.where("role = ? OR can_be_technician = ?", User.roles[:tecnico], true)
    @order_service&.service_items ||= []
  end

  def prefill_client_from_params
    return if params[:client_id].blank?
    return unless current_user.clients.exists?(id: params[:client_id])

    @order_service.client_id = params[:client_id]
  end

  def set_attachment_on_update
    return unless params[:order_service].present?

    if params[:order_service][:attachments].is_a?(Array)
      params[:order_service][:attachments].reject!(&:blank?)
      @attachments = params[:order_service].delete(:attachments)
    end
  end

  def add_attachs
    invalid_attachments = []

    @attachments.each do |file|
      @order_service.attachments.attach(file)
      @order_service.valid?

      if @order_service.errors[:attachments].any?
        last_attachment = @order_service.attachments.last
        last_attachment.purge if last_attachment.present?
        invalid_attachments << file.original_filename
      end
    end

    if invalid_attachments.any?
      @clients = Client.order(:name)
      flash.now[:alert] = @order_service.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    else
      redirect_to app_order_service_url(@order_service), notice: "Ordem de serviço atualizada com sucesso."
    end
  end

  def can_add_order_service
    unless current_user.company.can_create_order?
      redirect_to app_order_services_path, alert: "Limite de ordens de serviço atingido para o seu plano atual."
    end
  end

  def ensure_direct_order_service_creation_enabled
    return if current_user.company.allow_order_service_without_budget?

    redirect_to new_app_budget_path(client_id: params.dig(:order_service, :client_id)),
                alert: "Sua empresa não permite criar OS sem orçamento. Crie um orçamento primeiro."
  end

  def ensure_technician_only_updates_allowed_fields
    return unless current_user.tecnico?

    return unless params[:order_service].present?

    allowed_params = %w[observations attachments]
    datetime_params = %w[scheduled_at expected_end_at]
    submitted = params[:order_service]

    updated_datetimes = changed_attr_datetimes?

    assignable_submitted = submitted.to_unsafe_h.except("remove_attachment_ids")
    @order_service.assign_attributes(assignable_submitted)
    changed = @order_service.changed - allowed_params - datetime_params

    if changed.any? || updated_datetimes
      redirect_to app_order_service_url, alert: "Você só tem permissão para alterar observações e anexos."
    end
  end

  def purge_marked_attachments
    attachment_ids = Array(params.dig(:order_service, :remove_attachment_ids)).reject(&:blank?).uniq
    return if attachment_ids.empty?

    @order_service.attachments.where(id: attachment_ids).find_each(&:purge)
  end

  def changed_attr_datetimes?
    return false unless params[:order_service].present?

    scheduled_raw = params[:order_service][:scheduled_at]
    expected_raw = params[:order_service][:expected_end_at]

    scheduled_updated = scheduled_raw.present? && @order_service.scheduled_at != Time.zone.parse(scheduled_raw)
    expected_updated = expected_raw.present? && @order_service.expected_end_at != Time.zone.parse(expected_raw)

    scheduled_updated || expected_updated
  end

  def set_simultaneous_conflicts_warning
    conflicts = simultaneous_assignment_conflicts
    return if conflicts.empty?

    details = conflicts.map do |conflict|
      "Técnico #{conflict[:technician_name]} também está na OS ##{conflict[:order_service_code]} "\
      "(#{I18n.l(conflict[:scheduled_at], format: :short)} - #{I18n.l(conflict[:expected_end_at], format: :short)})"
    end

    flash[:warning] = "Atenção: conflito de agenda detectado. #{details.join(' | ')}"
  end

  def simultaneous_assignment_conflicts
    return [] unless @order_service.company&.allow_simultaneous_order_services?
    return [] if @order_service.scheduled_at.blank? || @order_service.expected_end_at.blank?

    @order_service.users.includes(assignments: :order_service).flat_map do |technician|
      technician.assignments
                .joins(:order_service)
                .where.not(order_services: { status: [:concluida, :cancelada] })
                .where.not(order_service_id: @order_service.id)
                .where(
                  "(order_services.scheduled_at, order_services.expected_end_at) OVERLAPS (?, ?)",
                  @order_service.scheduled_at - 1.hour,
                  @order_service.expected_end_at + 1.hour
                )
                .map do |assignment|
                  {
                    technician_name: technician.name,
                    order_service_code: assignment.order_service.code,
                    scheduled_at: assignment.order_service.scheduled_at,
                    expected_end_at: assignment.order_service.expected_end_at
                  }
                end
    end.uniq
  end

  def restrict_status_update_for_technician
    return if current_user.gestor?

    if params[:status].present? && %w[finalizada cancelada].include?(params[:status])
      redirect_to app_order_service_url, alert: "Você não tem permissão para atualizar o status para '#{params[:status]}'."
    end
  end

  def restrict_overdue_reschedule_for_technician
    return if current_user.gestor?
    return unless @order_service.atrasada?

    redirect_to app_order_service_url(@order_service),
                alert: "Somente gestores podem reagendar uma ordem de serviço atrasada."
  end

  def allowed_status_transition?(target_status)
    return false if target_status.blank?

    return @order_service.pendente? if target_status == "agendada"

    @order_service.next_possible_statuses.include?(target_status)
  end

  def ensure_schedulable_status
    return if @order_service.pendente? || @order_service.atrasada?

    redirect_to app_order_service_url(@order_service), alert: "Só é possível agendar ordens pendentes ou atrasadas."
  end

end
