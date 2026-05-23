require "rails_helper"

RSpec.describe App::ConfigurationsController, type: :controller do
  describe "perfil e empresa" do
    let(:plan) { create(:plan, max_technicians: 10) }
    let(:company) do
      create(
        :company,
        plan: plan,
        active: true,
        allow_order_service_without_budget: false,
        allow_simultaneous_order_services: false
      )
    end
    let!(:subscription) { create(:subscription, company: company, subscription_plan: plan, status: :active) }
    let(:user) { create(:user, :gestor, company: company, active: true, name: "Nome antigo") }

    before do
      company.update!(responsible: user)
      allow(controller).to receive(:current_user).and_return(user)
    end

    it "atualiza perfil ignorando senha em branco" do
      patch :update_profile, params: {
        user: {
          name: "Nome atualizado",
          phone: "11988887777",
          password: "",
          password_confirmation: ""
        }
      }

      aggregate_failures do
        expect(response).to redirect_to(app_configurations_path)
        expect(flash[:notice]).to eq("Perfil atualizado com sucesso.")
        expect(user.reload.name).to eq("Nome Atualizado")
        expect(user.phone).to eq("11988887777")
      end
    end

    it "renderiza index quando perfil é inválido" do
      patch :update_profile, params: {
        user: {
          name: "",
          phone: "11988887777"
        }
      }

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response).not_to be_redirect
        expect(flash[:alert]).to be_present
      end
    end

    it "permite responsavel alterar flags operacionais da empresa" do
      patch :update_company, params: {
        company: {
          name: "Empresa Atualizada",
          document: company.document,
          phone: company.phone,
          street: company.street,
          number: company.number,
          neighborhood: company.neighborhood,
          city: company.city,
          state: company.state,
          zip_code: company.zip_code,
          allow_order_service_without_budget: "1",
          allow_simultaneous_order_services: "1"
        }
      }

      aggregate_failures do
        expect(response).to redirect_to(app_configurations_path)
        expect(company.reload.name).to eq("Empresa Atualizada")
        expect(company.allow_order_service_without_budget).to be(true)
        expect(company.allow_simultaneous_order_services).to be(true)
      end
    end

    it "promove tecnico da empresa para gestor" do
      technician = create(:user, :tecnico, company: company, active: true)

      post :promote_manager, params: { user_id: technician.id }

      aggregate_failures do
        expect(response).to redirect_to(app_configurations_path)
        expect(flash[:notice]).to eq("Técnico promovido a gestor com sucesso.")
        expect(technician.reload).to be_gestor
      end
    end

    it "rejeita promoção quando usuário não é técnico válido" do
      other_manager = create(:user, :gestor, company: company, active: true)

      post :promote_manager, params: { user_id: other_manager.id }

      aggregate_failures do
        expect(response).to redirect_to(app_configurations_path)
        expect(flash[:alert]).to eq("Selecione um técnico válido para promover.")
        expect(other_manager.reload).to be_gestor
      end
    end
  end

  describe "configurações de PDF" do
    let(:company) { create(:company, active: true) }
    let(:user) { create(:user, :gestor, company: company, active: true) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    it "bloqueia atualização quando plano não permite customização" do
      allow(company).to receive(:pdf_customization_available?).and_return(false)
      allow(user).to receive(:company).and_return(company)

      patch :update_pdf_settings, params: {
        company_pdf_setting: {
          document_type: "order_service"
        }
      }

      aggregate_failures do
        expect(response).to redirect_to(app_configurations_path(tab: "pdf"))
        expect(flash[:alert]).to eq("Personalização dos PDFs disponível apenas nos planos Profissional e Enterprise.")
      end
    end

    it "bloqueia tipo de PDF inválido" do
      allow(company).to receive(:pdf_customization_available?).and_return(true)
      allow(user).to receive(:company).and_return(company)

      patch :update_pdf_settings, params: {
        company_pdf_setting: {
          document_type: "invalido"
        }
      }

      aggregate_failures do
        expect(response).to redirect_to(app_configurations_path(tab: "pdf"))
        expect(flash[:alert]).to eq("Tipo de PDF inválido.")
      end
    end
  end

  describe "cancelamento de assinatura" do
    let(:company) { create(:company, active: true) }
    let(:user) { create(:user, :gestor, company: company, active: true) }
    let(:mailer) { instance_double(Subscriptions::CancellationMailer) }
    let(:delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(Subscriptions::CancellationMailer).to receive(:with).and_return(mailer)
    end

    describe "PATCH #cancel_subscription" do
      it "agenda o cancelamento da assinatura atual" do
        subscription = create(
          :subscription,
          company: company,
          status: :active,
          end_date: Date.new(2026, 6, 10)
        )
        allow(mailer).to receive(:requested_email).and_return(delivery)

        patch :cancel_subscription, params: { cancel_reason: "Vou encerrar" }

        aggregate_failures do
          expect(response).to redirect_to(app_configurations_path)
          expect(flash[:notice]).to include("Cancelamento agendado com sucesso")
          expect(subscription.reload.cancel_at_period_end).to be(true)
          expect(subscription.cancel_effective_on).to eq(Date.new(2026, 6, 10))
          expect(subscription.cancel_reason).to eq("Vou encerrar")
          expect(mailer).to have_received(:requested_email)
          expect(delivery).to have_received(:deliver_later)
        end
      end

      it "não agenda quando a assinatura já está agendada" do
        subscription = create(
          :subscription,
          company: company,
          status: :active,
          cancel_at_period_end: true,
          cancel_effective_on: Date.new(2026, 6, 10)
        )

        patch :cancel_subscription

        aggregate_failures do
          expect(response).to redirect_to(app_configurations_path)
          expect(flash[:alert]).to eq("A assinatura já está agendada para cancelamento.")
          expect(subscription.reload.cancel_at_period_end).to be(true)
          expect(Subscriptions::CancellationMailer).not_to have_received(:with)
        end
      end
    end

    describe "PATCH #resume_subscription" do
      it "reativa a renovação automática" do
        subscription = create(
          :subscription,
          company: company,
          status: :active,
          cancel_at_period_end: true,
          cancel_requested_at: Time.zone.local(2026, 5, 17, 10, 0, 0),
          cancel_effective_on: Date.new(2026, 6, 10),
          cancel_reason: "Vou encerrar"
        )
        allow(mailer).to receive(:reactivated_email).and_return(delivery)

        patch :resume_subscription

        aggregate_failures do
          expect(response).to redirect_to(app_configurations_path)
          expect(flash[:notice]).to eq("Renovação automática reativada com sucesso.")
          expect(subscription.reload.cancel_at_period_end).to be(false)
          expect(subscription.cancel_requested_at).to be_nil
          expect(subscription.cancel_effective_on).to be_nil
          expect(subscription.cancel_reason).to be_nil
          expect(mailer).to have_received(:reactivated_email)
          expect(delivery).to have_received(:deliver_later)
        end
      end

      it "não reativa quando não existe agendamento" do
        create(:subscription, company: company, status: :active, cancel_at_period_end: false)

        patch :resume_subscription

        aggregate_failures do
          expect(response).to redirect_to(app_configurations_path)
          expect(flash[:alert]).to eq("Não existe cancelamento agendado para essa assinatura.")
          expect(Subscriptions::CancellationMailer).not_to have_received(:with)
        end
      end
    end
  end
end
