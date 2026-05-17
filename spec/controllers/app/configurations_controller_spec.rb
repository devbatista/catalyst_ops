require "rails_helper"

RSpec.describe App::ConfigurationsController, type: :controller do
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
