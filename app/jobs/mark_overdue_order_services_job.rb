class MarkOverdueOrderServicesJob < 
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform
    order_services = OrderService.to_overdue
    order_services.find_each(batch_size: 500) do |order_service|
      order_service.atrasada!
    end
    Rails.logger.info "[MarkOverdueOrderServicesJob] Executando o MarkOverdueOrderServicesJob com sucesso!"
  end
end