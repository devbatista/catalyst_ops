require "rails_helper"

RSpec.describe WebhookEvent, type: :model do
  describe "validações" do
    subject(:webhook_event) { build(:webhook_event) }

    it { should validate_presence_of(:provider) }
    it { should validate_presence_of(:event_key) }
    it { should validate_inclusion_of(:status).in_array(WebhookEvent::STATUSES) }

    it "impede duplicidade de provider e event_key no banco" do
      event = create(:webhook_event)
      duplicate = build(:webhook_event, provider: event.provider, event_key: event.event_key)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "escopos" do
    it "retorna apenas eventos processados" do
      processed = create(:webhook_event, status: "processed", processed_at: Time.current)
      failed = create(:webhook_event, status: "failed")

      expect(described_class.processed).to include(processed)
      expect(described_class.processed).not_to include(failed)
    end
  end
end
