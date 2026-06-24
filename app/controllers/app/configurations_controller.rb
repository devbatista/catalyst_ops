class App::ConfigurationsController < ApplicationController
  skip_authorization_check
  before_action :set_subscription_for_management, only: [:cancel_subscription, :resume_subscription]
  before_action :authorize_subscription_management, only: [:cancel_subscription, :resume_subscription]

  def index; end

  def update_profile
    user_params = profile_params.dup
    if user_params[:password].blank?
      user_params.delete(:password)
      user_params.delete(:password_confirmation)
    end

    if current_user.update(user_params)
      redirect_to app_configurations_path, notice: "Perfil atualizado com sucesso."
    else
      flash.now[:alert] = current_user.errors.full_messages.to_sentence
      render :index
    end
  end

  def update_company
    company = current_user.company

    if company.update(company_params)
      redirect_to app_configurations_path, notice: "Dados da empresa atualizados com sucesso."
    else
      flash.now[:alert] = company.errors.full_messages.to_sentence
      render :index
    end
  end

  def update_pdf_settings
    unless current_user.company.pdf_customization_available?
      redirect_to app_configurations_path(tab: "pdf"), alert: "Personalização dos PDFs disponível apenas nos planos Profissional e Enterprise."
      return
    end

    document_type = params.dig(:company_pdf_setting, :document_type).to_s
    unless CompanyPdfSetting::DOCUMENT_TYPES.include?(document_type)
      redirect_to app_configurations_path(tab: "pdf"), alert: "Tipo de PDF inválido."
      return
    end

    pdf_setting = current_user.company.pdf_setting_or_default(document_type)
    pdf_setting.logo.purge if ActiveModel::Type::Boolean.new.cast(params.dig(:company_pdf_setting, :remove_logo))

    if pdf_setting.update(pdf_setting_params)
      if request.xhr? || request.format.json?
        head :no_content
      else
        redirect_to app_configurations_path(tab: "pdf"), notice: "Configurações do PDF atualizadas com sucesso."
      end
    else
      @active_config_tab = "pdf"
      flash.now[:alert] = pdf_setting.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  def preview_pdf_settings
    unless current_user.company.pdf_customization_available?
      redirect_to app_configurations_path(tab: "pdf"), alert: "Personalização dos PDFs disponível apenas nos planos Profissional e Enterprise."
      return
    end

    document_type = params[:document_type].to_s
    unless CompanyPdfSetting::DOCUMENT_TYPES.include?(document_type)
      redirect_to app_configurations_path(tab: "pdf"), alert: "Tipo de PDF inválido."
      return
    end

    record = preview_pdf_record(document_type)
    unless record
      redirect_to app_configurations_path(tab: "pdf"), alert: "Crie ao menos um #{preview_pdf_record_name(document_type)} para visualizar o PDF."
      return
    end

    pdf_data = preview_pdf_data(document_type, record)

    send_data pdf_data,
              filename: preview_pdf_filename(document_type, record),
              type: "application/pdf",
              disposition: "inline"
  end

  def remove_pdf_logo
    unless current_user.company.pdf_customization_available?
      redirect_to app_configurations_path(tab: "pdf"), alert: "Personalização dos PDFs disponível apenas nos planos Profissional e Enterprise."
      return
    end

    document_type = params[:document_type].to_s
    unless CompanyPdfSetting::DOCUMENT_TYPES.include?(document_type)
      redirect_to app_configurations_path(tab: "pdf"), alert: "Tipo de PDF inválido."
      return
    end

    pdf_setting = current_user.company.pdf_setting_for(document_type)
    pdf_setting&.logo&.purge

    redirect_to app_configurations_path(tab: "pdf"), notice: "Logo removida com sucesso."
  end

  def promote_manager
    company = current_user.company
    user = company.users.find_by(id: params[:user_id])
    if user && user.role == "tecnico"
      if user.update(role: "gestor")
        redirect_to app_configurations_path, notice: "Técnico promovido a gestor com sucesso."
      else
        redirect_to app_configurations_path, alert: user.errors.full_messages.to_sentence
      end
    else
      redirect_to app_configurations_path, alert: "Selecione um técnico válido para promover."
    end
  end

  def cancel_subscription
    return redirect_to app_configurations_path, alert: "O plano Starter não possui cancelamento de assinatura." if @subscription.free_plan?
    return redirect_to app_configurations_path, alert: "Assinatura não está ativa para cancelamento." unless @subscription.active?
    return redirect_to app_configurations_path, alert: "A assinatura já está agendada para cancelamento." if @subscription.cancel_at_period_end?

    @subscription.schedule_cancellation!(reason: params[:cancel_reason])
    Subscriptions::CancellationMailer.with(subscription: @subscription).requested_email.deliver_later

    redirect_to app_configurations_path,
      notice: "Cancelamento agendado com sucesso. A assinatura permanecerá ativa até #{helpers.l(@subscription.cancel_effective_on, format: :short)}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to app_configurations_path, alert: e.record.errors.full_messages.to_sentence
  end

  def resume_subscription
    return redirect_to app_configurations_path, alert: "Não existe cancelamento agendado para essa assinatura." unless @subscription.cancel_at_period_end?

    @subscription.resume_cancellation!
    Subscriptions::CancellationMailer.with(subscription: @subscription).reactivated_email.deliver_later

    redirect_to app_configurations_path, notice: "Renovação automática reativada com sucesso."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to app_configurations_path, alert: e.record.errors.full_messages.to_sentence
  end

  private

  def profile_params
    params.require(:user).permit(:name, :phone, :password, :password_confirmation)
  end

  def company_params
    permitted = params.require(:company).permit(
      :name, :document, :phone, :street, :number, :complement,
      :neighborhood, :city, :state, :zip_code
    )

    if current_user.id == current_user.company&.responsible_id
      permitted[:allow_order_service_without_budget] = params[:company][:allow_order_service_without_budget]
      permitted[:allow_simultaneous_order_services] = params[:company][:allow_simultaneous_order_services]
    end

    permitted
  end

  def pdf_setting_params
    params.require(:company_pdf_setting).permit(
      :accent_color,
      :header_text_color,
      :document_type,
      :customization_enabled,
      :remove_logo,
      :logo,
      :header_subtitle,
      :document_note,
      :footer_text,
      :show_company_data,
      :show_client_data,
      :show_service_description,
      :show_service_items,
      :show_observations,
      :show_discount_reason
    )
  end

  def preview_pdf_record(document_type)
    case document_type
    when "order_service"
      current_user.company.order_services.recent.first
    when "budget"
      current_user.company.budgets.recent.first
    end
  end

  def preview_pdf_data(document_type, record)
    case document_type
    when "order_service"
      Cmd::Pdf::Create.new(record).generate_pdf_data
    when "budget"
      Cmd::Pdf::CreateBudget.new(record).generate_pdf_data
    end
  end

  def preview_pdf_filename(document_type, record)
    case document_type
    when "order_service"
      "preview_ordem_servico_#{record.code}.pdf"
    when "budget"
      "preview_orcamento_#{record.code}.pdf"
    end
  end

  def preview_pdf_record_name(document_type)
    document_type == "budget" ? "orçamento" : "ordem de serviço"
  end

  def set_subscription_for_management
    @subscription = current_user.company&.current_subscription
    return if @subscription.present?

    redirect_to app_configurations_path, alert: "Nenhuma assinatura ativa encontrada."
  end

  def authorize_subscription_management
    return if performed?

    authorize! :manage, @subscription
  end
end
