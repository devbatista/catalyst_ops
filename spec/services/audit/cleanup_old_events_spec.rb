require "rails_helper"

RSpec.describe Audit::CleanupOldEvents do
  describe "#call" do
    it "remove eventos mais antigos que a retenção" do
      old_event = create(:audit_event, occurred_at: 200.days.ago)
      recent_event = create(:audit_event, occurred_at: 10.days.ago)

      result = described_class.new(retention_days: 180, batch_size: 100, dry_run: false).call

      aggregate_failures do
        expect(result[:total_candidates]).to eq(1)
        expect(result[:deleted_count]).to eq(1)
        expect(AuditEvent.exists?(old_event.id)).to be false
        expect(AuditEvent.exists?(recent_event.id)).to be true
      end
    end

    it "contabiliza sem remover quando dry_run está ativo" do
      old_event = create(:audit_event, occurred_at: 200.days.ago)

      result = described_class.new(retention_days: 180, batch_size: 100, dry_run: true).call

      expect(result[:deleted_count]).to eq(1)
      expect(AuditEvent.exists?(old_event.id)).to be true
    end
  end
end
