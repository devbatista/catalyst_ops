module Previews
  class Subscriptions::BoletoMailerPreview < ActionMailer::Preview
    def ticket_email
      company = Company.first || Company.new(name: "Empresa Exemplo", email: "contato@exemplo.com.br")
      Subscriptions::BoletoMailer.with(
        company: company,
        boleto_url: "https://exemplo.com/boleto.pdf",
        boleto_barcode: "34191.79001 01043.510047 91020.150008 1 90040000010000",
        boleto_expiration_date: (Date.today + 7.days).end_of_day.iso8601,
        payment_status: "pending"
      ).ticket_email
    end
  end
end