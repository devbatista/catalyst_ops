require "rails_helper"

RSpec.describe Subscription, type: :model do
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
