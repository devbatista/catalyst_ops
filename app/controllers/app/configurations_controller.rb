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
    params.require(:user).permit(:name, :email, :phone, :password, :password_confirmation)
  end

  def company_params
    permitted = params.require(:company).permit(
      :name, :document, :email, :phone, :street, :number, :complement,
      :neighborhood, :city, :state, :zip_code
    )

    if current_user.id == current_user.company&.responsible_id
      permitted[:allow_order_service_without_budget] = params[:company][:allow_order_service_without_budget]
      permitted[:allow_simultaneous_order_services] = params[:company][:allow_simultaneous_order_services]
    end

    permitted
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
