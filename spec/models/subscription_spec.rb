require "rails_helper"

RSpec.describe Subscription, type: :model do
  describe "associações" do
    it { is_expected.to belong_to(:company) }
    it { is_expected.to have_many(:coupon_redemptions).dependent(:restrict_with_exception) }

    it "encontra o plano pelo identificador externo da assinatura" do
      plan = create(:plan)
      subscription = create(:subscription, subscription_plan: plan)

      expect(subscription.plan).to eq(plan)
    end
  end

  describe "validações" do
    it "exige empresa" do
      subscription = build(:subscription, company: nil)

      expect(subscription).not_to be_valid
      expect(subscription.errors[:company]).to be_present
    end

    it "exige identificador do plano no gateway" do
      subscription = build(:subscription, preapproval_plan_id: nil)

      expect(subscription).not_to be_valid
      expect(subscription.errors[:preapproval_plan_id]).to include("não pode ficar em branco")
    end

    it "exige status conhecido" do
      subscription = build(:subscription)

      expect { subscription.status = "desconhecido" }
        .to raise_error(ArgumentError, /'desconhecido' is not a valid status/)
    end
  end

  describe "scopes" do
    describe ".by_status" do
      it "retorna apenas assinaturas com o status informado" do
        active_subscription = create(:subscription, status: :active)
        pending_subscription = create(:subscription, status: :pending)

        result = described_class.by_status(:active)

        expect(result).to include(active_subscription)
        expect(result).not_to include(pending_subscription)
      end
    end

    describe ".recent" do
      it "ordena da assinatura mais recente para a mais antiga" do
        older_subscription = create(:subscription)
        newer_subscription = create(:subscription)
        older_subscription.update_column(:created_at, 2.days.ago)
        newer_subscription.update_column(:created_at, 1.hour.ago)

        expect(described_class.where(id: [older_subscription.id, newer_subscription.id]).recent).to eq(
          [newer_subscription, older_subscription]
        )
      end
    end

    describe ".current" do
      it "retorna somente a assinatura mais recente" do
        older_subscription = create(:subscription)
        newer_subscription = create(:subscription)
        older_subscription.update_column(:created_at, 3.days.ago)
        newer_subscription.update_column(:created_at, 2.hours.ago)

        expect(described_class.where(id: [older_subscription.id, newer_subscription.id]).current.to_a).to eq(
          [newer_subscription]
        )
      end
    end

    describe ".active" do
      it "retorna somente uma assinatura ativa" do
        active_subscription = create(:subscription, status: :active)
        create(:subscription, status: :pending)

        result = described_class.where(id: active_subscription.id).active

        expect(result.to_a).to eq([active_subscription])
      end
    end

    describe ".active_records" do
      it "retorna todas as assinaturas ativas" do
        first_active_subscription = create(:subscription, status: :active)
        second_active_subscription = create(:subscription, status: :active)
        create(:subscription, status: :cancelled)

        result = described_class.where(id: [first_active_subscription.id, second_active_subscription.id]).active_records

        expect(result).to contain_exactly(first_active_subscription, second_active_subscription)
      end
    end

    describe ".in_attention" do
      it "retorna assinaturas pendentes, expiradas e canceladas ordenadas por atualização" do
        pending_subscription = create(:subscription, status: :pending)
        expired_subscription = create(:subscription, status: :expired)
        cancelled_subscription = create(:subscription, status: :cancelled)
        active_subscription = create(:subscription, status: :active)

        pending_subscription.update_columns(updated_at: 3.hours.ago, created_at: 3.hours.ago)
        expired_subscription.update_columns(updated_at: 1.hour.ago, created_at: 1.hour.ago)
        cancelled_subscription.update_columns(updated_at: 2.hours.ago, created_at: 2.hours.ago)

        scoped_ids = [
          pending_subscription.id,
          expired_subscription.id,
          cancelled_subscription.id,
          active_subscription.id
        ]

        expect(described_class.where(id: scoped_ids).in_attention).to eq(
          [expired_subscription, cancelled_subscription, pending_subscription]
        )
      end
    end

    describe ".ready_to_cycle" do
      it "retorna assinaturas ativas não cartão que vencem em sete dias" do
        allow(Date).to receive(:current).and_return(Date.new(2026, 5, 17))
        ready_company = create(:company, payment_method: "boleto")
        credit_card_company = create(:company, payment_method: "credit_card")

        ready_subscription = create(
          :subscription,
          company: ready_company,
          status: :active,
          end_date: Date.new(2026, 5, 24),
          cancel_at_period_end: false
        )
        credit_card_subscription = create(
          :subscription,
          company: credit_card_company,
          status: :active,
          end_date: Date.new(2026, 5, 24)
        )
        scheduled_cancellation_subscription = create(
          :subscription,
          status: :active,
          end_date: Date.new(2026, 5, 24),
          cancel_at_period_end: true
        )
        wrong_date_subscription = create(
          :subscription,
          status: :active,
          end_date: Date.new(2026, 5, 25),
          cancel_at_period_end: false
        )
        pending_subscription = create(
          :subscription,
          status: :pending,
          end_date: Date.new(2026, 5, 24),
          cancel_at_period_end: false
        )
        scoped_ids = [
          ready_subscription.id,
          credit_card_subscription.id,
          scheduled_cancellation_subscription.id,
          wrong_date_subscription.id,
          pending_subscription.id
        ]

        expect(described_class.where(id: scoped_ids).ready_to_cycle).to contain_exactly(ready_subscription)
      end
    end
  end

  describe "#allows_access?" do
    it "permite acesso para assinatura ativa" do
      subscription = build(:subscription, status: :active)

      expect(subscription).to be_allows_access
    end

    it "não permite acesso para assinatura cancelada" do
      subscription = build(:subscription, status: :cancelled)

      expect(subscription).not_to be_allows_access
    end
  end

  describe ".estimated_mrr" do
    it "soma o valor das assinaturas ativas" do
      current_mrr = described_class.estimated_mrr

      create(:subscription, status: :active, transaction_amount: 100.50)
      create(:subscription, status: :active, transaction_amount: 200.25)
      create(:subscription, status: :cancelled, transaction_amount: 999.99)

      expect(described_class.estimated_mrr).to eq(current_mrr + BigDecimal("300.75"))
    end
  end

  describe "transições de status" do
    describe "#activate!" do
      it "ativa a assinatura e limpa dados de cancelamento e expiração" do
        subscription = create(
          :subscription,
          status: :pending,
          cancel_at_period_end: true,
          cancel_requested_at: Time.zone.local(2026, 5, 1, 10, 0, 0),
          cancel_effective_on: Date.new(2026, 5, 20),
          cancel_reason: "Cliente pediu pausa",
          expired_date: Date.new(2026, 5, 2),
          expiration_warning_sent_at: Time.zone.local(2026, 5, 2, 11, 0, 0)
        )
        started_at = Time.zone.local(2026, 5, 17, 9, 0, 0)
        period_end = Date.new(2026, 6, 17)

        allow(Time).to receive(:current).and_return(started_at)
        allow(MercadoPago::Subscriptions).to receive(:compute_period_end)
          .with(started_at, frequency: 1, frequency_type: "months")
          .and_return(period_end)

        subscription.activate!

        aggregate_failures do
          expect(subscription.reload).to be_active
          expect(subscription.start_date).to eq(started_at.to_date)
          expect(subscription.end_date).to eq(period_end)
          expect(subscription.canceled_date).to be_nil
          expect(subscription.cancel_at_period_end).to be(false)
          expect(subscription.cancel_requested_at).to be_nil
          expect(subscription.cancel_effective_on).to be_nil
          expect(subscription.cancel_reason).to be_nil
          expect(subscription.expired_date).to be_nil
          expect(subscription.expiration_warning_sent_at).to be_nil
        end
      end
    end

    describe "#cancel!" do
      it "cancela a assinatura e remove agendamento de cancelamento" do
        subscription = create(:subscription, status: :active, cancel_at_period_end: true)

        subscription.cancel!

        aggregate_failures do
          expect(subscription.reload).to be_cancelled
          expect(subscription.canceled_date).to be_present
          expect(subscription.cancel_at_period_end).to be(false)
        end
      end
    end

    describe "#expire!" do
      it "expira a assinatura e registra a data de expiração" do
        subscription = create(:subscription, status: :active)

        subscription.expire!

        aggregate_failures do
          expect(subscription.reload).to be_expired
          expect(subscription.expired_date).to eq(Date.current)
        end
      end
    end
  end

  describe "sincronização de acesso da empresa" do
    it "ativa a empresa quando a assinatura permite acesso" do
      company = create(:company, active: false)
      subscription = create(:subscription, company: company, status: :active)

      subscription.send(:sync_company_access)

      expect(company.reload).to be_active
    end

    it "desativa a empresa quando a assinatura não permite acesso" do
      company = create(:company, active: true)
      subscription = create(:subscription, company: company, status: :expired)

      subscription.send(:sync_company_access)

      expect(company.reload).not_to be_active
    end
  end

  describe "#upgrade_to_plan!" do
    let(:basico) { create(:plan, name: "Basico", external_reference: "BASICO_TEST", transaction_amount: 99.0) }
    let(:profissional) { create(:plan, :profissional) }
    let(:enterprise) { create(:plan, :enterprise) }
    let(:company) { create(:company, plan: current_plan) }
    let(:subscription) { create(:subscription, company: company, subscription_plan: current_plan, end_date: Date.new(2026, 6, 10)) }

    context "quando o plano atual é Basico" do
      let(:current_plan) { basico }

      it "faz upgrade para Profissional no próximo ciclo" do
        subscription.upgrade_to_plan!(profissional)

        aggregate_failures do
          expect(subscription.reload.preapproval_plan_id).to eq(profissional.external_id)
          expect(subscription.reason).to eq(profissional.reason)
          expect(subscription.transaction_amount).to eq(profissional.transaction_amount)
          expect(company.reload.plan).to eq(profissional)
          expect(subscription.raw_payload["plan_upgrade"]).to include(
            "from" => "Basico",
            "to" => "Profissional",
            "billing_mode" => "next_cycle",
            "effective_on" => "2026-06-10"
          )
        end
      end

      it "faz upgrade para Enterprise no próximo ciclo" do
        subscription.upgrade_to_plan!(enterprise)

        aggregate_failures do
          expect(subscription.reload.preapproval_plan_id).to eq(enterprise.external_id)
          expect(subscription.reason).to eq(enterprise.reason)
          expect(subscription.transaction_amount).to eq(enterprise.transaction_amount)
          expect(company.reload.plan).to eq(enterprise)
          expect(subscription.raw_payload["plan_upgrade"]).to include(
            "from" => "Basico",
            "to" => "Enterprise",
            "billing_mode" => "next_cycle",
            "effective_on" => "2026-06-10"
          )
        end
      end

      it "preserva as chaves existentes do raw_payload" do
        subscription.update!(raw_payload: { "gateway" => { "id" => "abc" } })

        subscription.upgrade_to_plan!(profissional)

        expect(subscription.reload.raw_payload).to include(
          "gateway" => { "id" => "abc" },
          "plan_upgrade" => a_hash_including("to" => "Profissional")
        )
      end

      it "permite sobrescrever a data efetiva" do
        subscription.upgrade_to_plan!(profissional, effective_on: Date.new(2026, 7, 1))

        expect(subscription.reload.raw_payload["plan_upgrade"]["effective_on"]).to eq("2026-07-01")
      end

      it "bloqueia troca para o mesmo plano" do
        expect { subscription.upgrade_to_plan!(basico) }
          .to raise_error(ActiveRecord::RecordInvalid, /downgrade/)

        aggregate_failures do
          expect(subscription.reload.preapproval_plan_id).to eq(basico.external_id)
          expect(company.reload.plan).to eq(basico)
          expect(subscription.raw_payload).not_to have_key("plan_upgrade")
        end
      end
    end

    context "quando o plano atual é Profissional" do
      let(:current_plan) { profissional }

      it "faz upgrade para Enterprise no próximo ciclo" do
        subscription.upgrade_to_plan!(enterprise)

        aggregate_failures do
          expect(subscription.reload.preapproval_plan_id).to eq(enterprise.external_id)
          expect(subscription.reason).to eq(enterprise.reason)
          expect(subscription.transaction_amount).to eq(enterprise.transaction_amount)
          expect(company.reload.plan).to eq(enterprise)
          expect(subscription.raw_payload["plan_upgrade"]).to include(
            "from" => "Profissional",
            "to" => "Enterprise",
            "billing_mode" => "next_cycle",
            "effective_on" => "2026-06-10"
          )
        end
      end

      it "bloqueia downgrade para Basico" do
        expect { subscription.upgrade_to_plan!(basico) }
          .to raise_error(ActiveRecord::RecordInvalid, /downgrade/)

        aggregate_failures do
          expect(subscription.reload.preapproval_plan_id).to eq(profissional.external_id)
          expect(company.reload.plan).to eq(profissional)
          expect(subscription.raw_payload).not_to have_key("plan_upgrade")
        end
      end

      it "bloqueia troca para o mesmo plano" do
        expect { subscription.upgrade_to_plan!(profissional) }
          .to raise_error(ActiveRecord::RecordInvalid, /downgrade/)

        aggregate_failures do
          expect(subscription.reload.preapproval_plan_id).to eq(profissional.external_id)
          expect(company.reload.plan).to eq(profissional)
          expect(subscription.raw_payload).not_to have_key("plan_upgrade")
        end
      end
    end

    context "quando o plano atual é Enterprise" do
      let(:current_plan) { enterprise }

      it "bloqueia downgrade para Profissional" do
        expect { subscription.upgrade_to_plan!(profissional) }
          .to raise_error(ActiveRecord::RecordInvalid, /downgrade/)

        aggregate_failures do
          expect(subscription.reload.preapproval_plan_id).to eq(enterprise.external_id)
          expect(company.reload.plan).to eq(enterprise)
          expect(subscription.raw_payload).not_to have_key("plan_upgrade")
        end
      end
    end

    context "quando o plano de destino é inválido" do
      let(:current_plan) { basico }

      it "gera erro de validação para plano de destino nulo" do
        expect { subscription.upgrade_to_plan!(nil) }
          .to raise_error(ActiveRecord::RecordInvalid, /Plano de destino inválido/)
      end

      it "gera erro de validação para nomes de plano desconhecidos" do
        custom_plan = create(:plan, name: "Custom", external_reference: "CUSTOM_TEST", transaction_amount: 499.0)

        expect { subscription.upgrade_to_plan!(custom_plan) }
          .to raise_error(ActiveRecord::RecordInvalid, /Plano de destino inválido/)
      end
    end

    context "quando a assinatura não tem data de fim" do
      let(:current_plan) { basico }

      it "usa a data atual como data efetiva padrão" do
        allow(Date).to receive(:current).and_return(Date.new(2026, 5, 17))
        subscription.update!(end_date: nil)

        subscription.upgrade_to_plan!(profissional)

        expect(subscription.reload.raw_payload["plan_upgrade"]["effective_on"]).to eq("2026-05-17")
      end
    end
  end
end
