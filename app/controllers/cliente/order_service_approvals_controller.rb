class Cliente::OrderServiceApprovalsController < ApplicationController
  skip_before_action :custom_authenticate_user!
  skip_before_action :block_inactive_company_access
  skip_before_action :ensure_terms_accepted!
  skip_authorization_check
  layout "public"

  before_action :set_order_service
  before_action :allow_decided_page_only_once!, only: :show

  def show; end

  def approve
    if @order_service.approved_at.present?
      return redirect_to order_service_approval_path(token: params[:token], subdomain: "cliente"),
                         notice: "Este orçamento já foi aprovado."
    end

    if @order_service.approve_by_client!
      redirect_to order_service_approval_path(token: params[:token], subdomain: "cliente"),
                  notice: "Orçamento aprovado com sucesso."
    else
      redirect_to order_service_approval_path(token: params[:token], subdomain: "cliente"),
                  alert: @order_service.errors.full_messages.to_sentence
    end
  end

  def reject
    if @order_service.rejected_at.present?
      return redirect_to order_service_approval_path(token: params[:token], subdomain: "cliente"),
                         notice: "Este orçamento já foi rejeitado."
    end

    if @order_service.reject_by_client!(rejection_reason: params[:rejection_reason])
      redirect_to order_service_approval_path(token: params[:token], subdomain: "cliente"),
                  notice: "Orçamento rejeitado com sucesso."
    else
      redirect_to order_service_approval_path(token: params[:token], subdomain: "cliente"),
                  alert: @order_service.errors.full_messages.to_sentence
    end
  end

  private

  def set_order_service
    @order_service = OrderService.find_by_approval_token(params[:token])
    unless @order_service.present?
      return render plain: "Link inválido ou expirado.", status: :not_found
    end
  end

  def allow_decided_page_only_once!
    return unless @order_service.approved_at.present? || @order_service.rejected_at.present?

    seen_tokens = session[:cliente_order_service_decision_seen_tokens] ||= {}
    token = params[:token].to_s

    if seen_tokens[token]
      render plain: "Este orçamento já foi respondido e este link não está mais disponível.", status: :gone
      return
    end

    seen_tokens[token] = true
  end
end
