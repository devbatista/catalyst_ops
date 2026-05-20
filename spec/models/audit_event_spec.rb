require "rails_helper"

RSpec.describe AuditEvent, type: :model do
  describe "associações" do
    it { is_expected.to belong_to(:company).optional }
  end

  describe "validações" do
    subject(:audit_event) { build(:audit_event) }

    it { is_expected.to validate_presence_of(:action) }
    it { is_expected.to validate_inclusion_of(:action).in_array(Audit::ActionCatalog::ALL) }
    it { is_expected.to validate_presence_of(:occurred_at) }
    it { is_expected.to validate_inclusion_of(:source).in_array(AuditEvent::SOURCES).allow_blank }
    it { is_expected.to validate_presence_of(:metadata) }

    it "é válido com ação cadastrada no catálogo" do
      audit_event = build(:audit_event, action: Audit::ActionCatalog::ALL.first)

      expect(audit_event).to be_valid
    end

    it "rejeita ação fora do catálogo" do
      audit_event = build(:audit_event, action: "acao.inexistente")

      aggregate_failures do
        expect(audit_event).not_to be_valid
        expect(audit_event.errors.details[:action]).to include(error: :inclusion, value: "acao.inexistente")
      end
    end
  end

  describe "scopes" do
    describe ".recent" do
      it "ordena por ocorrência e criação mais recentes primeiro" do
        older = create(:audit_event, occurred_at: 3.days.ago, created_at: 1.hour.ago)
        newest = create(:audit_event, occurred_at: 1.day.ago, created_at: 3.hours.ago)
        same_occurrence_newer_creation = create(:audit_event, occurred_at: 1.day.ago, created_at: 1.hour.ago)

        result = described_class.where(id: [older.id, newest.id, same_occurrence_newer_creation.id]).recent

        expect(result).to eq([same_occurrence_newer_creation, newest, older])
      end
    end

    describe ".by_action" do
      it "filtra por ação quando informada" do
        expected_event = create(:audit_event, action: "plan.created")
        other_event = create(:audit_event, action: "plan.updated")

        result = described_class.where(id: [expected_event.id, other_event.id]).by_action("plan.created")

        expect(result).to contain_exactly(expected_event)
      end

      it "não aplica filtro quando ação está em branco" do
        event = create(:audit_event, action: "plan.created")

        expect(described_class.where(id: event.id).by_action("")).to contain_exactly(event)
      end
    end

    describe ".by_source" do
      it "filtra por origem quando informada" do
        expected_event = create(:audit_event, source: "admin")
        other_event = create(:audit_event, source: "system")

        result = described_class.where(id: [expected_event.id, other_event.id]).by_source("admin")

        expect(result).to contain_exactly(expected_event)
      end

      it "não aplica filtro quando origem está em branco" do
        event = create(:audit_event, source: "admin")

        expect(described_class.where(id: event.id).by_source(nil)).to contain_exactly(event)
      end
    end

    describe ".by_company" do
      it "filtra por empresa quando informada" do
        company = create(:company)
        expected_event = create(:audit_event, company: company)
        other_event = create(:audit_event, company: create(:company))

        result = described_class.where(id: [expected_event.id, other_event.id]).by_company(company.id)

        expect(result).to contain_exactly(expected_event)
      end

      it "não aplica filtro quando empresa está em branco" do
        event = create(:audit_event, company: create(:company))

        expect(described_class.where(id: event.id).by_company("")).to contain_exactly(event)
      end
    end

    describe ".between" do
      it "filtra eventos dentro do intervalo informado" do
        previous_event = create(:audit_event, occurred_at: Time.zone.local(2026, 5, 9, 12, 0, 0))
        expected_event = create(:audit_event, occurred_at: Time.zone.local(2026, 5, 10, 12, 0, 0))
        next_event = create(:audit_event, occurred_at: Time.zone.local(2026, 5, 11, 12, 0, 0))

        result = described_class.where(id: [previous_event.id, expected_event.id, next_event.id]).between(
          Time.zone.local(2026, 5, 10, 0, 0, 0),
          Time.zone.local(2026, 5, 10, 23, 59, 59)
        )

        expect(result).to contain_exactly(expected_event)
      end

      it "filtra apenas pelo início quando fim está ausente" do
        previous_event = create(:audit_event, occurred_at: 2.days.ago)
        expected_event = create(:audit_event, occurred_at: 1.hour.ago)

        result = described_class.where(id: [previous_event.id, expected_event.id]).between(1.day.ago, nil)

        expect(result).to contain_exactly(expected_event)
      end

      it "filtra apenas pelo fim quando início está ausente" do
        expected_event = create(:audit_event, occurred_at: 2.days.ago)
        next_event = create(:audit_event, occurred_at: 1.hour.ago)

        result = described_class.where(id: [expected_event.id, next_event.id]).between(nil, 1.day.ago)

        expect(result).to contain_exactly(expected_event)
      end
    end
  end
end
