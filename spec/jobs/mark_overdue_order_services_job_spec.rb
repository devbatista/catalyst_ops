require "rails_helper"

RSpec.describe MarkOverdueOrderServicesJob, type: :job do
  describe "#perform" do
    it "marca ordens de serviço em atraso" do
      plan = create(:plan)
      company = create(:company, plan: plan)
      create(:subscription, company: company, subscription_plan: plan, status: :active)
      client = create(:client, company: company)
      order_service = create(
        :order_service,
        company: company,
        client: client,
        status: :agendada,
        scheduled_at: 1.day.from_now,
        expected_end_at: 2.days.from_now
      )
      order_service.update_columns(scheduled_at: 2.hours.ago, expected_end_at: 1.hour.ago)

      allow(OrderService).to receive(:to_overdue).and_return(OrderService.where(id: order_service.id))
      allow(Rails.logger).to receive(:info)
      allow(OrderServiceMailer).to receive_message_chain(:notify_overdue, :deliver_later)

      described_class.new.perform

      aggregate_failures do
        expect(order_service.reload).to be_atrasada
        expect(Rails.logger).to have_received(:info).with("[MarkOverdueOrderServicesJob] 1 OrderServices marcadas como atrasadas.")
      end
    end

    it "registra log quando não há ordens de serviço em atraso" do
      allow(OrderService).to receive(:to_overdue).and_return(OrderService.none)
      allow(Rails.logger).to receive(:info)

      described_class.new.perform

      expect(Rails.logger).to have_received(:info).with("[MarkOverdueOrderServicesJob] Nenhuma OrderService para marcar como atrasada.")
    end
  end
end
