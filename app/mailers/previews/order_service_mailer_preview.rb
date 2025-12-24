class OrderServiceMailerPreview < ActionMailer::Preview
  def notify_overdue
    order_service = OrderService.where(status: :atrasada).first || OrderService.first
    OrderServiceMailer.notify_overdue(order_service)
  end

  def notify_client_on_scheduled
    order_service = OrderService.where.not(client_id: nil).first
    OrderServiceMailer.notify_client_on_scheduled(order_service)
  end

  def notify_create
    order_service = OrderService.first
    OrderServiceMailer.notify_create(order_service)
  end
end