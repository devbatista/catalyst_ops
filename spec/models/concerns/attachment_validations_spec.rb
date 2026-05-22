require "rails_helper"

RSpec.describe AttachmentValidations, type: :model do
  around do |example|
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = previous_adapter
  end

  before do
    allow(OrderServiceMailer).to receive(:notify_client_on_scheduled).and_return(mail_delivery)
    allow(OrderServiceMailer).to receive(:notify_technical_on_scheduled).and_return(mail_delivery)
  end

  let(:mail_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }
  let(:plan) { create(:plan, max_orders: 10) }
  let(:company) { create(:company, plan: plan) }
  let!(:subscription) { create(:subscription, company: company, subscription_plan: plan) }
  let(:client) { create(:client, company: company) }

  it "permite anexos com tipo aceito e tamanho dentro do limite" do
    order_service = create(:order_service, client: client, company: company)

    order_service.attachments.attach(
      io: StringIO.new("conteudo"),
      filename: "documento.pdf",
      content_type: "application/pdf"
    )

    expect(order_service).to be_valid
  end

  it "rejeita mais de cinco anexos" do
    order_service = create(:order_service, client: client, company: company)

    6.times do |index|
      order_service.attachments.attach(
        io: StringIO.new("arquivo #{index}"),
        filename: "arquivo-#{index}.pdf",
        content_type: "application/pdf"
      )
    end

    expect(order_service).not_to be_valid
    expect(order_service.errors[:attachments]).to include("máximo de 5 arquivos por registro")
  end

  it "rejeita tipo de arquivo não permitido" do
    order_service = create(:order_service, client: client, company: company)

    order_service.attachments.attach(
      io: StringIO.new("script"),
      filename: "script.sh",
      content_type: "application/x-sh"
    )

    expect(order_service).not_to be_valid
    expect(order_service.errors[:attachments]).to be_present
  end
end
