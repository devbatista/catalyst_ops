require "rails_helper"

RSpec.describe MercadoPago::Client do
  describe "#request" do
    it "executa GET com Authorization e Content-Type" do
      request = perform_request(method: :get, path: "/v1/test")

      aggregate_failures do
        expect(request).to be_a(Net::HTTP::Get)
        expect(request["Authorization"]).to eq("Bearer token_teste")
        expect(request["Content-Type"]).to eq("application/json")
      end
    end

    it "executa POST com body JSON e chave de idempotência" do
      request = perform_request(method: :post, path: "/v1/payments", body: { amount: 10 })

      aggregate_failures do
        expect(request).to be_a(Net::HTTP::Post)
        expect(request.body).to eq({ amount: 10 }.to_json)
        expect(request["X-Idempotency-Key"]).to be_present
      end
    end

    it "executa PUT" do
      request = perform_request(method: :put, path: "/v1/resource/1", body: { status: "active" })

      expect(request).to be_a(Net::HTTP::Put)
    end

    it "executa DELETE" do
      request = perform_request(method: :delete, path: "/v1/resource/1")

      expect(request).to be_a(Net::HTTP::Delete)
    end

    it "envia query params no GET" do
      request = perform_request(method: :get, path: "/v1/search", params: { limit: 100, status: "active" })

      expect(request.path).to eq("/v1/search?limit=100&status=active")
    end

    it "levanta erro para método não suportado" do
      client = described_class.new(access_token: "token_teste", base_url: "https://api.example.com")

      expect do
        client.request(method: :patch, path: "/v1/test")
      end.to raise_error(ArgumentError, "Unsupported HTTP method: patch")
    end

    it "levanta erro para resposta não 2xx" do
      client = described_class.new(access_token: "token_teste", base_url: "https://api.example.com")
      http = instance_double(Net::HTTP)
      response = http_response(success: false, code: "400", body: '{"message":"erro"}')

      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:request).and_return(response)

      expect do
        client.request(method: :get, path: "/v1/test")
      end.to raise_error(RuntimeError, 'API request failed with code 400: {"message":"erro"}')
    end
  end

  describe "#fetch_plans" do
    it "retorna results quando request entrega JSON bruto" do
      client = described_class.new(access_token: "token_teste", base_url: "https://api.example.com")

      allow(client).to receive(:request).with(
        method: :get,
        path: "/preapproval_plan/search",
        params: { limit: 100, status: "active" }
      ).and_return({ "results" => [{ "id" => "plan_1" }] }.to_json)

      expect(client.fetch_plans).to eq([{ "id" => "plan_1" }])
    end

    it "documenta comportamento atual: falha quando request já retorna Hash parseado" do
      client = described_class.new(access_token: "token_teste", base_url: "https://api.example.com")

      allow(client).to receive(:request).and_return({ "results" => [{ "id" => "plan_1" }] })

      expect { client.fetch_plans }.to raise_error(TypeError)
    end
  end

  def perform_request(method:, path:, body: nil, params: nil)
    client = described_class.new(access_token: "token_teste", base_url: "https://api.example.com")
    http = instance_double(Net::HTTP)
    response = http_response(success: true, body: '{"ok":true}')
    captured_request = nil

    allow(Net::HTTP).to receive(:new).with("api.example.com", 443).and_return(http)
    allow(http).to receive(:use_ssl=).with(true)
    allow(http).to receive(:request) do |request|
      captured_request = request
      response
    end

    client.request(method: method, path: path, body: body, params: params)
    captured_request
  end

  def http_response(success:, code: "200", body: "{}")
    instance_double(Net::HTTPResponse, code: code, body: body).tap do |response|
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(success)
    end
  end
end
