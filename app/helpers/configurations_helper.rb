module ConfigurationsHelper
  def company_responsible?(user = current_user)
    user.company&.responsible_id == user.id
  end

  def current_company_plan(user = current_user)
    company = user.company
    subscription = company.subscriptions.find_by(status: :active)
    subscription&.plan || company.plan
  end

  def can_promote_manager?(user = current_user)
    company = user.company
    return false unless company_responsible?(user)
    plan = current_company_plan(user)
    plan&.name != "Basico"
  end

  def company_managers(user = current_user)
    user.company.users.where(role: :gestor)
  end

  def company_technicians(user = current_user)
    user.company.users.where(role: :tecnico)
  end

  def current_company_subscription(user = current_user)
    user.company.subscriptions.find_by(status: :active)
  end

  def paid_subscription_plans
    Plan.paid.where(status: :active).order(:transaction_amount)
  end

  def configuration_payment_methods
    Company::PAYMENT_METHODS
  end

  def configuration_payment_method_label(method)
    case method.to_s
    when "pix"
      "PIX"
    when "credit_card"
      "Cartão"
    when "boleto"
      "Boleto"
    else
      method.to_s.humanize
    end
  end

  def configuration_payment_method_icon(method)
    {
      "pix" => "bx-money",
      "credit_card" => "bx-credit-card",
      "boleto" => "bx-barcode"
    }[method.to_s] || "bx-credit-card"
  end

  def subscription_badge_class(status)
    case status.to_s
    when "active"
      "success"
    when "pending"
      "warning"
    when "canceled"
      "danger"
    when "expired"
      "secondary"
    else
      "secondary"
    end
  end
end
