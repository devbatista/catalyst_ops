require "rails_helper"

RSpec.describe "WebHook::MercadoPago", type: :request do
  let(:headers) do
    {
      "CONTENT_TYPE" => "application/json",
      "ACCEPT" => "application/json",
      "HTTP_HOST" => webhook_host,
      "X-Request-Id" => request_id
    }
  end
  let(:request_id) { "mp-request-123" }
  let(:webhook_host) do
    tld_labels = ["example", "com"]
    extra_domain_labels = Array.new(Rails.application.config.action_dispatch.tld_length.to_i - 1, "app")

    (["webhook"] + extra_domain_labels + tld_labels).join(".")
  end

  before do
    allow_any_instance_of(ActionDispatch::HostAuthorization).to receive(:call) do |middleware, env|
      middleware.instance_variable_get(:@app).call(env)
    end

    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("MP_WEBHOOK_SECRET", "").and_return("")
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("MP_WEBHOOK_REQUIRE_SIGNATURE").and_return(nil)

    host! webhook_host
  end

  describe "POST /mp" do
    it "processa webhook de pagamento quando a assinatura existe" do
      subscription = create(
        :subscription,
        status: :pending,
        external_payment_id: "pay_123",
        start_date: nil,
        end_date: nil
      )
      payload = payment_payload(payment_id: "pay_123", status: "approved")
      payment_response = payment_response_for(subscription, payment_id: "pay_123", status: "approved")

      allow(MercadoPago::Subscriptions).to receive(:fetch_payment).and_return(payment_response)

      expect do
        post webhook_url, params: payload.to_json, headers: headers
      end.to change(WebhookEvent, :count).by(1)

      event = WebhookEvent.last

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq("status" => "ok")
        expect(subscription.reload).to be_active
        expect(subscription.external_payment_id).to eq("pay_123")
        expect(subscription.raw_payload).to include("id" => "pay_123", "status" => "approved")
        expect(event).to have_attributes(
          provider: "mercado_pago",
          event_key: "mp-request-123",
          resource_id: "pay_123",
          event_type: "payment",
          status: "processed"
        )
        expect(event.processed_at).to be_present
      end
    end

    it "retorna erro quando o pagamento não encontra assinatura local" do
      payload = payment_payload(payment_id: "pay_sem_assinatura", status: "approved")
      payment_response = {
        "id" => "pay_sem_assinatura",
        "status" => "approved",
        "external_reference" => "empresa_inexistente"
      }

      allow(MercadoPago::Subscriptions).to receive(:fetch_payment).and_return(payment_response)

      post webhook_url, params: payload.to_json, headers: headers

      event = WebhookEvent.last
      json = JSON.parse(response.body)

      aggregate_failures do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json["status"]).to eq("error")
        expect(json["message"]).to include("Assinatura local nao encontrada")
        expect(event).to have_attributes(
          event_key: "mp-request-123",
          resource_id: "pay_sem_assinatura",
          event_type: "payment",
          status: "failed"
        )
        expect(event.error_message).to include("Assinatura local nao encontrada")
      end
    end

    it "mantém a assinatura pendente quando o pagamento ainda está pendente" do
      subscription = create(:subscription, status: :active, external_payment_id: "pay_pendente")
      payload = payment_payload(payment_id: "pay_pendente", status: "pending")
      payment_response = payment_response_for(subscription, payment_id: "pay_pendente", status: "pending")

      allow(MercadoPago::Subscriptions).to receive(:fetch_payment).and_return(payment_response)

      post webhook_url, params: payload.to_json, headers: headers

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(subscription.reload).to be_pending
        expect(WebhookEvent.last).to have_attributes(
          resource_id: "pay_pendente",
          event_type: "payment",
          status: "processed"
        )
      end
    end

    it "cancela a assinatura quando o pagamento é rejeitado" do
      subscription = create(:subscription, status: :active, external_payment_id: "pay_rejeitado")
      payload = payment_payload(payment_id: "pay_rejeitado", status: "rejected")
      payment_response = payment_response_for(subscription, payment_id: "pay_rejeitado", status: "rejected")

      allow(MercadoPago::Subscriptions).to receive(:fetch_payment).and_return(payment_response)

      post webhook_url, params: payload.to_json, headers: headers

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(subscription.reload).to be_cancelled
        expect(subscription.canceled_date).to be_present
        expect(WebhookEvent.last).to have_attributes(
          resource_id: "pay_rejeitado",
          event_type: "payment",
          status: "processed"
        )
      end
    end

    it "processa payload legado usando topic e id de topo" do
      subscription = create(:subscription, status: :pending, external_payment_id: "pay_topico")
      payload = {
        "topic" => "payment",
        "id" => "pay_topico",
        "status" => "approved"
      }
      payment_response = payment_response_for(subscription, payment_id: "pay_topico", status: "approved")

      allow(MercadoPago::Subscriptions).to receive(:fetch_payment).and_return(payment_response)

      post webhook_url, params: payload.to_json, headers: headers

      event = WebhookEvent.last

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(subscription.reload).to be_active
        expect(event).to have_attributes(
          resource_id: "pay_topico",
          event_type: "payment",
          status: "processed"
        )
      end
    end

    it "ignora payload com tipo diferente de payment" do
      payload = {
        "type" => "merchant_order",
        "action" => "updated",
        "data" => { "id" => "order_123" }
      }

      expect(MercadoPago::Subscriptions).not_to receive(:fetch_payment)

      post webhook_url, params: payload.to_json, headers: headers

      event = WebhookEvent.last

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq("status" => "ok")
        expect(event).to have_attributes(
          event_key: "mp-request-123",
          resource_id: "order_123",
          event_type: "merchant_order",
          status: "processed"
        )
      end
    end

    it "retorna erro para payload inválido" do
      expect do
        post webhook_url, params: "{payload-invalido", headers: headers.merge("CONTENT_TYPE" => "text/plain")
      end.not_to change(WebhookEvent, :count)

      aggregate_failures do
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to eq("status" => "invalid_payload")
      end
    end

    it "retorna 200 para processamento novo e 204 para webhook duplicado" do
      subscription = create(:subscription, status: :pending, external_payment_id: "pay_duplicado")
      payload = payment_payload(payment_id: "pay_duplicado", status: "pending")
      payment_response = payment_response_for(subscription, payment_id: "pay_duplicado", status: "pending")

      allow(MercadoPago::Subscriptions).to receive(:fetch_payment).and_return(payment_response)

      post webhook_url, params: payload.to_json, headers: headers

      aggregate_failures "primeira requisição" do
        expect(response).to have_http_status(:ok)
        expect(WebhookEvent.last.status).to eq("processed")
      end

      expect do
        post webhook_url, params: payload.to_json, headers: headers
      end.not_to change(WebhookEvent, :count)

      aggregate_failures "requisição duplicada" do
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_blank
        expect(MercadoPago::Subscriptions).to have_received(:fetch_payment).once
      end
    end

    it "retorna não autorizado quando assinatura obrigatória está ausente" do
      payload = payment_payload(payment_id: "pay_sem_assinatura_hmac", status: "approved")

      allow(ENV).to receive(:fetch).with("MP_WEBHOOK_SECRET", "").and_return("segredo")
      allow(ENV).to receive(:[]).with("MP_WEBHOOK_REQUIRE_SIGNATURE").and_return("true")

      expect(MercadoPago::Subscriptions).not_to receive(:fetch_payment)

      expect do
        post webhook_url, params: payload.to_json, headers: headers
      end.not_to change(WebhookEvent, :count)

      aggregate_failures do
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq("status" => "unauthorized")
      end
    end

    it "processa webhook quando assinatura obrigatória é válida" do
      subscription = create(:subscription, status: :pending, external_payment_id: "pay_assinado")
      payload = payment_payload(payment_id: "pay_assinado", status: "approved")
      payment_response = payment_response_for(subscription, payment_id: "pay_assinado", status: "approved")
      secret = "segredo"

      allow(ENV).to receive(:fetch).with("MP_WEBHOOK_SECRET", "").and_return(secret)
      allow(ENV).to receive(:[]).with("MP_WEBHOOK_REQUIRE_SIGNATURE").and_return("true")
      allow(MercadoPago::Subscriptions).to receive(:fetch_payment).and_return(payment_response)

      post webhook_url, params: payload.to_json, headers: signed_headers_for(payload, secret: secret)

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(subscription.reload).to be_active
        expect(WebhookEvent.last).to have_attributes(
          event_key: request_id,
          resource_id: "pay_assinado",
          event_type: "payment",
          status: "processed"
        )
      end
    end
  end

  def payment_payload(payment_id:, status:)
    {
      "type" => "payment",
      "action" => "payment.updated",
      "data" => {
        "id" => payment_id,
        "status" => status
      }
    }
  end

  def webhook_url
    "http://#{webhook_host}/mp"
  end

  def signed_headers_for(payload, secret:)
    ts = "1716200000"
    data_id = payload.dig("data", "id").to_s.downcase
    manifest = "id:#{data_id};request-id:#{request_id};ts:#{ts};"
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, manifest)

    headers.merge("X-Signature" => "ts=#{ts},v1=#{signature}")
  end

  def payment_response_for(subscription, payment_id:, status:)
    {
      "id" => payment_id,
      "status" => status,
      "external_reference" => subscription.company_id,
      "transaction_amount" => subscription.transaction_amount.to_s,
      "payment_method_id" => "pix",
      "payment_type_id" => "bank_transfer"
    }
  end
end
