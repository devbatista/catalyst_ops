class Admin::DashboardController < AdminController
  def index
    @active_companies_count = Company.where(active: true).count
    @active_subscriptions_count = Subscription.where(status: :active).count
    @estimated_mrr = Subscription.where(status: :active).sum(:transaction_amount)
    @open_tickets_count = SupportTicket.open_status.count

    @new_companies_this_month = Company.where(created_at: Time.current.all_month).count
    @new_users_this_month = User.where(created_at: Time.current.all_month).count
    @finished_orders_this_month = OrderService.where(status: :finalizada, updated_at: Time.current.all_month).count
    @overdue_orders_count = OrderService.where(status: :atrasada).count

    finalized_status = OrderService.statuses[:finalizada]

    @top_companies = Company
      .left_joins(:order_services)
      .select(
        "companies.*,
         COUNT(order_services.id) AS order_services_count,
         COUNT(CASE WHEN order_services.status = #{finalized_status} THEN 1 END) AS finalized_order_services_count"
      )
      .group("companies.id")
      .order(Arel.sql("COUNT(order_services.id) DESC, companies.created_at DESC"))
      .limit(8)

    @recent_tickets = SupportTicket.includes(:company, :user)
      .order(last_reply_at: :desc, created_at: :desc)
      .limit(8)

    @subscriptions_in_attention = Subscription.includes(:company)
      .where(status: [:pending, :expired, :cancelled])
      .order(updated_at: :desc, created_at: :desc)
      .limit(8)
  end
end
