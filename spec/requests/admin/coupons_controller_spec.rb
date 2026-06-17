require "rails_helper"

RSpec.describe "Admin::CouponsController", type: :request do
  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
    allow_any_instance_of(ApplicationController).to receive(:verified_request?).and_return(true)
    host! scoped_host_for("admin")
    sign_in admin
  end

  let(:admin) { create(:user, :admin, active: true) }

  it "lista e filtra cupons" do
    coupon = create(:coupon, code: "BAIXA10", name: "Cupom Baixa")
    create(:coupon, code: "OUTRO20", name: "Outro")

    get "/coupons", params: { q: "BAIXA", status: "active", benefit_type: "discount" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(coupon.code)
    expect(response.body).not_to include("OUTRO20")
  end

  it "cria, edita e atualiza cupom" do
    get "/coupons/new"
    expect(response).to have_http_status(:ok)

    post "/coupons", params: { coupon: coupon_params(code: "NOVO10") }
    coupon = Coupon.find_by!(code: "NOVO10")
    expect(response).to redirect_to(admin_coupon_path(coupon))

    get "/coupons/#{coupon.id}/edit"
    expect(response).to have_http_status(:ok)

    patch "/coupons/#{coupon.id}", params: { coupon: coupon_params(name: "Nome Atualizado") }
    expect(response).to redirect_to(admin_coupon_path(coupon))
    expect(coupon.reload.name).to eq("Nome Atualizado")
  end

  it "restringe acesso para usuário não admin" do
    sign_out admin
    sign_in create(:user, :gestor, active: true)

    get "/coupons"

    expect(response).to redirect_to(login_root_url(subdomain: "login"))
  end

  def coupon_params(code: "CUPOM10", name: "Cupom Teste")
    {
      code: code,
      name: name,
      active: "1",
      benefit_type: "discount",
      discount_type: "percentage",
      discount_value: 10,
      first_cycle_only: "1"
    }
  end

  def scoped_host_for(subdomain)
    ([subdomain] + Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app") + ["example", "com"]).join(".")
  end
end
