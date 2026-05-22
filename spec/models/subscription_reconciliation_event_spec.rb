require "rails_helper"

RSpec.describe SubscriptionReconciliationEvent, type: :model do
  describe "associações" do
    it { should belong_to(:subscription) }
    it { should belong_to(:company) }
  end

  describe "validações" do
    it { should validate_presence_of(:source_job) }
    it { should validate_presence_of(:payment_method) }
    it { should validate_presence_of(:gateway_identifier) }
    it { should validate_presence_of(:local_status_before) }
    it { should validate_presence_of(:local_status_after) }
    it { should validate_presence_of(:processed_at) }
    it { should validate_inclusion_of(:result_status).in_array(%w[success error]) }
  end

  describe "escopos" do
    let!(:old_event) { create(:subscription_reconciliation_event, processed_at: 2.days.ago) }
    let!(:new_event) { create(:subscription_reconciliation_event, processed_at: 1.hour.ago) }
    let!(:divergent_event) { create(:subscription_reconciliation_event, divergent: true) }
    let!(:error_event) { create(:subscription_reconciliation_event, result_status: "error") }

    it "ordena eventos recentes" do
      expect(described_class.recent.first).to eq(divergent_event.processed_at > error_event.processed_at ? divergent_event : error_event)
    end

    it "filtra divergentes" do
      expect(described_class.divergent).to include(divergent_event)
      expect(described_class.divergent).not_to include(old_event)
    end

    it "filtra erros" do
      expect(described_class.errors).to include(error_event)
      expect(described_class.errors).not_to include(new_event)
    end
  end
end
