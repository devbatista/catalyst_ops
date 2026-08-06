require "rails_helper"

RSpec.describe Admin::UsersController, type: :request do
  let(:admin) { create(:user, :admin, active: true, email: "admin@example.com") }
  let(:user) { create(:user, email: "usuario@example.com") }
  let(:mail_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    allow_any_instance_of(ApplicationController).to receive(:verified_request?).and_return(true)

    host! scoped_host_for("admin")
  end

  describe "POST /users/:id/send_test_email" do
    it "envia e-mail de teste para o usuário com cópia para o admin atual" do
      sign_in admin
      allow(UserMailer).to receive(:test_email).and_return(mail_delivery)

      post send_test_email_admin_user_path(user)

      aggregate_failures do
        expect(UserMailer).to have_received(:test_email).with(user, admin.email)
        expect(mail_delivery).to have_received(:deliver_later)
        expect(response).to redirect_to(admin_user_path(user))
        expect(flash[:notice]).to include("E-mail de teste enviado")
      end
    end

    it "redireciona usuário não admin para login" do
      gestor = create(:user, :gestor, active: true)
      sign_in gestor

      post send_test_email_admin_user_path(user)

      expect(response).to redirect_to(login_root_url(subdomain: "login"))
    end
  end

  def scoped_host_for(subdomain)
    tld_labels = ["example", "com"]
    extra_domain_labels = Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app")
    ([subdomain] + extra_domain_labels + tld_labels).join(".")
  end
end
