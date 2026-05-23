require "rails_helper"

RSpec.describe HomeController, type: :controller do
  before do
    routes.draw { get "index" => "home#index" }
    allow(controller).to receive(:authorize!) do
      controller.instance_variable_set(:@_authorized, true)
    end
  end

  after do
    Rails.application.reload_routes!
  end

  it "redireciona admin para o dashboard administrativo" do
    user = build_stubbed(:user, :admin, active: true)
    controller.define_singleton_method(:admin_dashboard_path) { "/admin" }
    allow(controller).to receive(:current_user).and_return(user)

    get :index

    expect(response).to redirect_to("/admin")
  end

  it "responde sem redirecionar gestor quando rota legada nao existe" do
    user = build_stubbed(:user, :gestor, active: true)
    allow(controller).to receive(:current_user).and_return(user)

    get :index

    aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(response).not_to be_redirect
    end
  end
end
