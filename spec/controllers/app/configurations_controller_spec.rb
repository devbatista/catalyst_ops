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

    it "renderiza index quando empresa é inválida" do
      patch :update_company, params: {
        company: {
          name: "",
          document: company.document,
          phone: company.phone,
          street: company.street,
          number: company.number,
          neighborhood: company.neighborhood,
          city: company.city,
          state: company.state,
          zip_code: company.zip_code
        }
      }

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response).not_to be_redirect
        expect(flash[:alert]).to be_present
        expect(company.reload.name).not_to eq("")
      end
    end

    it "ignora flags operacionais quando usuário não é responsável" do
      other_manager = create(:user, :gestor, company: company, active: true)
      company.update!(responsible: other_manager)

      patch :update_company, params: {
        company: {
          name: "Empresa Sem Flags",
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
        expect(company.reload.name).to eq("Empresa Sem Flags")
        expect(company.allow_order_service_without_budget).to be(false)
        expect(company.allow_simultaneous_order_services).to be(false)
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

    it "redireciona com erro quando promoção falha na persistência" do
      technician = create(:user, :tecnico, company: company, active: true)
      allow_any_instance_of(User).to receive(:update).and_return(false)
      allow_any_instance_of(User).to receive_message_chain(:errors, :full_messages, :to_sentence).and_return("Role inválida")

      post :promote_manager, params: { user_id: technician.id }

      aggregate_failures do
        expect(response).to redirect_to(app_configurations_path)
        expect(flash[:alert]).to eq("Role inválida")
        expect(technician.reload).to be_tecnico
      end
    end
  end

  describe "configurações de PDF" do
    let(:plan) { create(:plan, :profissional) }
    let(:company) { create(:company, plan: plan, active: true) }
    let!(:subscription) { create(:subscription, company: company, subscription_plan: plan, status: :active) }
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

    it "atualiza configurações de PDF com sucesso em HTML" do
      patch :update_pdf_settings, params: {
        company_pdf_setting: {
          document_type: "order_service",
          accent_color: "#abcdef",
          header_subtitle: "Subtítulo do PDF",
          customization_enabled: "1"
        }
      }

      setting = company.reload.order_service_pdf_setting

      aggregate_failures do
        expect(response).to redirect_to(app_configurations_path(tab: "pdf"))
        expect(flash[:notice]).to eq("Configurações do PDF atualizadas com sucesso.")
        expect(setting.accent_color).to eq("ABCDEF")
        expect(setting.header_subtitle).to eq("Subtítulo do PDF")
        expect(setting.customization_enabled).to be(true)
      end
    end

    it "retorna no content ao atualizar configurações de PDF por JSON" do
      patch :update_pdf_settings, params: {
        company_pdf_setting: {
          document_type: "budget",
          accent_color: "123456"
        }
      }, format: :json

      aggregate_failures do
        expect(response).to have_http_status(:no_content)
        expect(company.reload.budget_pdf_setting.accent_color).to eq("123456")
      end
    end

    it "renderiza index quando configurações de PDF são inválidas" do
      patch :update_pdf_settings, params: {
        company_pdf_setting: {
          document_type: "order_service",
          accent_color: "invalida"
        }
      }

      aggregate_failures do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).not_to be_redirect
        expect(flash[:alert]).to include("Accent color")
      end
    end

    it "gera preview de PDF para ordem de serviço" do
      order_service = create(:order_service, company: company, client: create(:client, company: company))
      pdf_builder = instance_double(Cmd::Pdf::Create, generate_pdf_data: "%PDF ordem")
      allow(Cmd::Pdf::Create).to receive(:new).with(order_service).and_return(pdf_builder)

      get :preview_pdf_settings, params: { document_type: "order_service" }

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("application/pdf")
        expect(response.headers["Content-Disposition"]).to include("inline")
      end
    end

    it "gera preview de PDF para orçamento" do
      budget = create(:budget, company: company, client: create(:client, company: company))
      pdf_builder = instance_double(Cmd::Pdf::CreateBudget, generate_pdf_data: "%PDF orçamento")
      allow(Cmd::Pdf::CreateBudget).to receive(:new).with(budget).and_return(pdf_builder)

      get :preview_pdf_settings, params: { document_type: "budget" }

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("application/pdf")
        expect(response.headers["Content-Disposition"]).to include("inline")
      end
    end

    it "bloqueia preview quando não existe registro base" do
      get :preview_pdf_settings, params: { document_type: "budget" }

      aggregate_failures do
        expect(response).to redirect_to(app_configurations_path(tab: "pdf"))
        expect(flash[:alert]).to eq("Crie ao menos um orçamento para visualizar o PDF.")
      end
    end

    it "remove logo do PDF com sucesso" do
      setting = create(:company_pdf_setting, company: company, document_type: "order_service")
      allow(company).to receive(:pdf_customization_available?).and_return(true)
      allow(user).to receive(:company).and_return(company)
      allow(company).to receive(:pdf_setting_for).with("order_service").and_return(setting)
      allow(setting.logo).to receive(:purge)

      delete :remove_pdf_logo, params: { document_type: "order_service" }

      aggregate_failures do
        expect(response).to redirect_to(app_configurations_path(tab: "pdf"))
        expect(flash[:notice]).to eq("Logo removida com sucesso.")
        expect(setting.logo).to have_received(:purge)
      end
    end

    it "bloqueia remoção de logo para tipo inválido" do
      delete :remove_pdf_logo, params: { document_type: "invalido" }

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

      it "não agenda quando a assinatura não está ativa" do
        create(:subscription, company: company, status: :pending)

        patch :cancel_subscription

        aggregate_failures do
          expect(response).to redirect_to(app_configurations_path)
          expect(flash[:alert]).to eq("Assinatura não está ativa para cancelamento.")
          expect(Subscriptions::CancellationMailer).not_to have_received(:with)
        end
      end

      it "redireciona quando não existe assinatura atual" do
        patch :cancel_subscription

        aggregate_failures do
          expect(response).to redirect_to(app_configurations_path)
          expect(flash[:alert]).to eq("Nenhuma assinatura ativa encontrada.")
        end
      end

      it "redireciona com erros quando agendamento falha" do
        subscription = create(:subscription, company: company, status: :active)
        allow_any_instance_of(Subscription).to receive(:schedule_cancellation!) do |record|
          record.errors.add(:base, "Falha ao agendar")
          raise ActiveRecord::RecordInvalid, record
        end

        patch :cancel_subscription

        aggregate_failures do
          expect(response).to redirect_to(app_configurations_path)
          expect(flash[:alert]).to eq("Falha ao agendar")
          expect(subscription.reload.cancel_at_period_end).to be(false)
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

      it "redireciona com erros quando retomada falha" do
        subscription = create(
          :subscription,
          company: company,
          status: :active,
          cancel_at_period_end: true,
          cancel_effective_on: Date.new(2026, 6, 10)
        )
        allow_any_instance_of(Subscription).to receive(:resume_cancellation!) do |record|
          record.errors.add(:base, "Falha ao reativar")
          raise ActiveRecord::RecordInvalid, record
        end

        patch :resume_subscription

        aggregate_failures do
          expect(response).to redirect_to(app_configurations_path)
          expect(flash[:alert]).to eq("Falha ao reativar")
          expect(subscription.reload.cancel_at_period_end).to be(true)
        end
      end
    end
  end
end
