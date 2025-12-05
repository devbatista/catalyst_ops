require "net/http"
require "json"
require "uri"

module MercadoPago
  class Client
    MP_ACCESS_TOKEN = Rails.env.production? ? MP_PRODUCTION_ACCESS_TOKEN : MP_TEST_ACCESS_TOKEN

    def initialize(access_token: MP_ACCESS_TOKEN, base_url: MP_API_BASE)
      @access_token = access_token
      @api_base = base_url
    end

    def request(method:, path:, body: nil, params: nil)
      uri = URI.join(@api_base, path)
      uri.query = URI.encode_www_form(params) if params

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      request_class = case method
                      when :get then Net::HTTP::Get
                      when :post then Net::HTTP::Post
                      when :put then Net::HTTP::Put
                      when :delete then Net::HTTP::Delete
                      else
                        raise ArgumentError, "Unsupported HTTP method: #{method}"
                      end

      request = request_class.new(uri.request_uri)
      request["Authorization"] = "Bearer #{@access_token}"
      request["Content-Type"] = "application/json"
      request.body = body.to_json if body

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "API request failed with code #{response.code}: #{response.body}"
      end

      response
    end

    def fetch_plans
      response = request(method: :get, path: "/preapproval_plan/search", params: { limit: 100 })
      JSON.parse(response.body)["results"]
    end
  end
end