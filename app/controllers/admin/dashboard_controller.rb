class Admin::DashboardController < AdminController
  def index
    @active_companies_count = Company.active.count
    @active_subscriptions_count = Subscription.active_records.count
    @estimated_mrr = Subscription.estimated_mrr
    @open_tickets_count = SupportTicket.open_status.count

    @new_companies_this_month = Company.created_this_month.count
    @new_users_this_month = User.created_this_month.count
    @finished_orders_this_month = OrderService.finished_this_month.count
    @overdue_orders_count = OrderService.overdue.count

    @top_companies = Company.top_by_order_services(8)
    @recent_tickets = SupportTicket.includes(:company, :user).recent_first.limit(8)
    @subscriptions_in_attention = Subscription.includes(:company).in_attention.limit(8)
  end
end
