class Cliente::BudgetApprovalsController < ApplicationController
  skip_before_action :custom_authenticate_user!
  skip_before_action :block_inactive_company_access
  skip_before_action :ensure_terms_accepted!
  skip_authorization_check
  layout "public"

  before_action :set_budget
  before_action :allow_decided_page_only_once!, only: :show

  def show; end

  def approve
    if @budget.approved_at.present?
      return redirect_to budget_approval_path(token: params[:token], subdomain: "cliente"),
                         notice: "Este orçamento já foi aprovado."
    end

    @budget.approve_and_create_order_service!(approver_role: :cliente)
    redirect_to budget_approval_path(token: params[:token], subdomain: "cliente"),
                notice: "Orçamento aprovado com sucesso."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to budget_approval_path(token: params[:token], subdomain: "cliente"),
                alert: e.record.errors.full_messages.to_sentence
  end

  def reject
    if @budget.rejected_at.present?
      return redirect_to budget_approval_path(token: params[:token], subdomain: "cliente"),
                         notice: "Este orçamento já foi rejeitado."
    end

    @budget.reject!(rejection_reason: params[:rejection_reason])
    redirect_to budget_approval_path(token: params[:token], subdomain: "cliente"),
                notice: "Orçamento rejeitado com sucesso."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to budget_approval_path(token: params[:token], subdomain: "cliente"),
                alert: e.record.errors.full_messages.to_sentence
  end

  private

  def set_budget
    @budget = Budget.find_by_approval_token(params[:token])
    return if @budget.present?

    render plain: "Link inválido ou expirado.", status: :not_found
  end

  def allow_decided_page_only_once!
    return unless @budget.approved_at.present? || @budget.rejected_at.present?

    seen_tokens = session[:cliente_budget_decision_seen_tokens] ||= {}
    token = params[:token].to_s

    if seen_tokens[token]
      render plain: "Este orçamento já foi respondido e este link não está mais disponível.", status: :gone
      return
    end

    seen_tokens[token] = true
  end
end
