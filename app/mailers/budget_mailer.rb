class BudgetMailer < ApplicationMailer
  def approval_request_to_client(budget, token, sender_name: nil)
    @budget = budget
    @client = budget.client
    @sender_name = sender_name.presence || "Responsável"
    @company_name = budget.company&.name.to_s
    @approval_url = budget_approval_url(token: token, subdomain: "cliente")

    mail(to: @client.email, subject: "Aprovação do Orçamento ##{@budget.code}")
  end
end
