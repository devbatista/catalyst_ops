require "rails_helper"

RSpec.describe "App::OrderServices::ServiceItemsController", type: :request do
  let(:plan) { create(:plan, max_orders: 10) }
  let(:company) do
    create(
      :company,
      plan: plan,
      active: true,
      allow_order_service_without_budget: true,
      terms_version_accepted: TermsOfUse.current_version,
      terms_accepted_at: Time.current
    )
  end
  let!(:subscription) { create(:subscription, company: company, subscription_plan: plan, status: :active) }
  let(:user) { create(:user, :gestor, company: company, active: true) }
  let(:client) { create(:client, company: company) }
  let(:order_service) { create(:order_service, company: company, client: client) }

  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    allow_any_instance_of(ApplicationController).to receive(:verified_request?).and_return(true)

    host! scoped_host_for("app")
    sign_in user
  end

  it "cria item de serviço para a OS" do
    expect do
      post app_order_service_app_service_items_path(order_service), params: {
        service_item: {
          description: "Troca de peça",
          quantity: 2,
          unit_price: 75
        }
      }
    end.to change(order_service.service_items, :count).by(1)

    item = order_service.service_items.reload.last

    aggregate_failures do
      expect(response).to redirect_to(app_order_service_path(order_service))
      expect(item.description).to eq("Troca de peça")
      expect(item.quantity).to eq(2)
      expect(item.unit_price).to eq(75)
    end
  end

  it "atualiza item de serviço" do
    item = create(:service_item, order_service: order_service, description: "Diagnóstico")

    patch app_order_service_app_service_item_path(order_service, item), params: {
      service_item: {
        description: "Diagnóstico completo",
        quantity: 3,
        unit_price: 90
      }
    }

    aggregate_failures do
      expect(response).to redirect_to(app_order_service_path(order_service))
      expect(item.reload.description).to eq("Diagnóstico completo")
      expect(item.quantity).to eq(3)
      expect(item.unit_price).to eq(90)
    end
  end

  it "remove item de serviço" do
    item = create(:service_item, order_service: order_service)

    expect do
      delete app_order_service_app_service_item_path(order_service, item)
    end.to change(ServiceItem, :count).by(-1)

    expect(response).to redirect_to(app_order_service_path(order_service))
  end

  it "não permite alterar item de outra OS pelo aninhamento" do
    other_order_service = create(:order_service, company: company, client: client)
    item = create(:service_item, order_service: other_order_service)

    patch app_order_service_app_service_item_path(order_service, item), params: {
        service_item: { description: "Tentativa inválida" }
    }

    aggregate_failures do
      expect(response).to have_http_status(:not_found)
      expect(item.reload.description).not_to eq("Tentativa inválida")
    end
  end

  def scoped_host_for(subdomain)
    ([subdomain] + Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app") + ["example", "com"]).join(".")
  end
end
