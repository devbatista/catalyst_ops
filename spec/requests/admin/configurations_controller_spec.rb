require "rails_helper"

RSpec.describe "Admin::ConfigurationsController", type: :request do
  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    allow_any_instance_of(ApplicationController).to receive(:verified_request?).and_return(true)
    host! scoped_host_for("admin")
    sign_in admin
  end

  let(:admin) { create(:user, :admin, active: true, name: "Admin Config") }

  it "renderiza dashboard de configurações" do
    get "/configurations"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Host da aplicação")
    expect(response.body).to include("Mercado Pago")
  end

  it "atualiza perfil do admin" do
    patch "/configurations/profile", params: { user: { name: "Admin Atualizado", phone: "11988887777" } }

    expect(response).to redirect_to(admin_configurations_path)
    expect(admin.reload.name).to eq("Admin Atualizado")
  end

  it "redireciona configuração inexistente" do
    get "/configurations/invalida/edit"

    expect(response).to redirect_to(admin_configurations_path)
  end

  def scoped_host_for(subdomain)
    ([subdomain] + Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app") + ["example", "com"]).join(".")
  end
end
