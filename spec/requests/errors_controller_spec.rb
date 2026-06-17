require "rails_helper"

RSpec.describe "ErrorsController", type: :request do
  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end
  end

  it "renderiza páginas de erro com status correto" do
    {
      "/errors/404" => :not_found,
      "/errors/422" => :unprocessable_entity,
      "/errors/500" => :internal_server_error,
      "/errors/503" => :service_unavailable
    }.each do |path, status|
      get path

      expect(response).to have_http_status(status)
      expect(response.body).to include(response.status.to_s)
    end
  end

  it "usa 500 como fallback para código desconhecido permitido pela rota genérica" do
    get "/errors/999"

    expect(response).to have_http_status(:not_found)
  end
end
