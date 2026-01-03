class MarkOverdueOrderServicesJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform
    order_services = OrderService.to_overdue

    if order_services.any?
      order_services.find_each(batch_size: 50) do |order_service|
        order_service.atrasada!
      end
      Rails.logger.info "[MarkOverdueOrderServicesJob] #{order_services.size} OrderServices marcadas como atrasadas."
    else
      Rails.logger.info "[MarkOverdueOrderServicesJob] Nenhuma OrderService para marcar como atrasada."
    end
  end
end