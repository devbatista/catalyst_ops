class App::ConfigurationsController < ApplicationController
  skip_authorization_check 
  
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

  def upgrade_plan
    company = current_user.company
    subscription = company&.current_subscription
    return redirect_to app_configurations_path, alert: "Nenhuma assinatura ativa encontrada para upgrade." if subscription.blank?

    target_plan = Plan.find_by(id: params[:plan_id], status: "active")
    return redirect_to app_configurations_path, alert: "Plano selecionado não é válido para upgrade." if target_plan.blank?

    unless subscription.can_upgrade_to_plan?(target_plan)
      return redirect_to app_configurations_path, alert: "Upgrade não permitido para o plano selecionado."
    end

    if subscription.has_pending_upgrade_request?
      return redirect_to app_configurations_path, alert: "Já existe uma solicitação de upgrade aguardando confirmação de pagamento."
    end

    payment_method = company.payment_method.to_s
    unless %w[pix boleto].include?(payment_method)
      return redirect_to app_configurations_path, alert: "Upgrade com pró-rata imediato disponível apenas para PIX e boleto no momento."
    end

    proration = subscription.proration_for_upgrade(target_plan)
    if proration[:proration_amount].to_d <= 0
      return redirect_to app_configurations_path, alert: "Não há diferença de valor para gerar cobrança de upgrade."
    end

    result =
      if payment_method == "pix"
        Cmd::MercadoPago::CreatePixPayment.new(company, amount_override: proration[:proration_amount]).call
      else
        Cmd::MercadoPago::CreateBoletoPayment.new(company, amount_override: proration[:proration_amount]).call
      end

    unless result.success?
      return redirect_to app_configurations_path, alert: "Não foi possível gerar a cobrança do upgrade: #{result.errors}"
    end

    payment_id = result.mailer_params[:external_id].to_s
    subscription.register_pending_upgrade!(target_plan: target_plan, proration: proration, payment_id: payment_id)

    if payment_method == "pix"
      Subscriptions::PixMailer.with(result.mailer_params).pix_email.deliver_later
    else
      Subscriptions::BoletoMailer.with(result.mailer_params).ticket_email.deliver_later
    end

    notice = "Solicitação de upgrade registrada para #{target_plan.name}."
    notice += " A ativação do novo plano ocorrerá somente após a confirmação do pagamento pró-rata (#{helpers.number_to_currency(proration[:proration_amount], unit: 'R$')})."
    redirect_to app_configurations_path, notice: notice
  rescue ActiveRecord::RecordInvalid => e
    redirect_to app_configurations_path, alert: e.record.errors.full_messages.to_sentence
  end

  private

  def profile_params
    params.require(:user).permit(:name, :email, :phone, :password, :password_confirmation)
  end

  def company_params
    params.require(:company).permit(
      :name, :document, :email, :phone, :street, :number, :complement,
      :neighborhood, :city, :state, :zip_code
    )
  end
end
