class OrderServiceMailerPreview < ActionMailer::Preview
  def notify_overdue
    order_service = OrderService.where(status: :atrasada).first || OrderService.first

    OrderServiceMailer.notify_overdue(order_service)
  end
end