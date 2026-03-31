class BudgetMailer < ApplicationMailer
  def approval_request_to_client(budget, token, sender_name: nil)
    @budget = budget
    @client = budget.client
    @sender_name = sender_name.presence || "Responsável"
    @company_name = budget.company&.name.to_s
    @approval_url = budget_approval_url(token: token, subdomain: "cliente")
    @approval_expires_at = budget.approval_expires_at

    mail(to: @client.email, subject: "Aprovação do Orçamento ##{@budget.code}")
  end

  def notify_manager_order_service_created(budget, order_service, approver_role:)
    @budget = budget
    @order_service = order_service
    @client = budget.client
    @company = budget.company
    @approver_role = approver_role.to_s
    @app_order_service_url = app_order_service_url(@order_service, subdomain: "app")

    manager_emails = @company.gestores.pluck(:email).uniq
    if manager_emails.blank?
      fallback_email = @company.responsible&.email
      manager_emails = [fallback_email].compact
    end
    return if manager_emails.blank?

    mail(to: manager_emails, subject: "OS ##{@order_service.code} criada a partir do orçamento ##{@budget.code}")
  end
end
