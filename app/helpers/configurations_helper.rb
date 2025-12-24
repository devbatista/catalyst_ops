module ConfigurationsHelper
  def current_company_plan(user = current_user)
    company = user.company
    subscription = company.subscriptions.find_by(status: :active)
    subscription&.plan || company.plan
  end

  def can_promote_manager?(user = current_user)
    company = user.company
    return false unless user.id == company.responsible_id
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