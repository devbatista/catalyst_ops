require "rails_helper"

RSpec.describe OrderServiceMailer, type: :mailer do
  let(:plan) { create(:plan) }
  let(:company) { create(:company, plan: plan, name: "Empresa Mailer") }
  let!(:subscription) { create(:subscription, company: company, subscription_plan: plan, status: :active) }
  let(:client) { create(:client, company: company, name: "Cliente Mailer", email: "cliente@example.com") }
  let(:order_service) { create(:order_service, company: company, client: client, scheduled_at: 2.days.from_now) }

  before do
    ActionMailer::Base.default_url_options[:host] = "example.com"
    allow(UserMailer).to receive(:welcome_email).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: true))
  end

  describe "#notify_client_on_scheduled" do
    it "envia o agendamento para o cliente da OS" do
      email = described_class.notify_client_on_scheduled(order_service)

      expect(email.to).to eq(["cliente@example.com"])
      expect(email.subject).to eq("Sua ordem de serviço foi atribuída e agendada!")
      expect(email.text_part.decoded).to include(order_service.code.to_s)
    end
  end

  describe "#notify_technical_on_scheduled" do
    it "envia a designação para o técnico" do
      technician = create(:user, :tecnico, company: company, active: true, name: "Técnico Mailer", email: "tecnico@example.com")
      create(:address, client: client, street: "Rua Técnica")

      email = described_class.notify_technical_on_scheduled(order_service, technician)

      expect(email.to).to eq(["tecnico@example.com"])
      expect(email.subject).to eq("ATENÇÃO, Você foi designado para a Ordem de Serviço ##{order_service.code}")
      expect(email.text_part.decoded).to include("Técnico Mailer", client.name, "Rua Técnica")
    end
  end

  describe "#notify_manager_on_complete" do
    it "envia a notificação para todos os gestores da empresa" do
      gestor_a = create(:user, :gestor, company: company, active: true, email: "gestor.a@example.com")
      gestor_b = create(:user, :gestor, company: company, active: true, email: "gestor.b@example.com")
      order_service.update!(finished_at: Time.current)

      email = described_class.notify_manager_on_complete(order_service)

      expect(email.to).to match_array([gestor_a.email, gestor_b.email])
      expect(email.subject).to eq("OS concluída e aguarda finalização!")
      expect(email.body.encoded).to include(order_service.code.to_s)
    end
  end

  describe "#notify_client_on_complete" do
    it "envia ao cliente avisando sobre a conclusão" do
      email = described_class.notify_client_on_complete(order_service)

      expect(email.to).to eq(["cliente@example.com"])
      expect(email.subject).to eq("Sua ordem de serviço foi concluída com sucesso!")
      expect(email.body.encoded).to include(order_service.code.to_s, client.name)
    end
  end

  describe "#notify_client_on_finished" do
    it "envia ao cliente quando a OS é finalizada" do
      email = described_class.notify_client_on_finished(order_service)

      expect(email.to).to eq(["cliente@example.com"])
      expect(email.subject).to eq("Sua ordem de serviço foi finalizada!")
      expect(email.body.encoded).to include(order_service.code.to_s, company.name)
    end
  end

  describe "#notify_overdue" do
    it "envia ao responsável da empresa quando a OS está atrasada" do
      gestor = create(:user, :gestor, company: company, active: true, email: "responsavel@example.com")
      company.update!(responsible: gestor)

      email = described_class.notify_overdue(order_service)

      expect(email.to).to eq(["responsavel@example.com"])
      expect(email.subject).to eq("A ordem de serviço ##{order_service.code} está atrasada!")
      expect(email.body.encoded).to include(gestor.name, order_service.code.to_s)
    end
  end

  describe "#notify_technician_on_finished" do
    it "envia notificação ao técnico após a finalização" do
      technician = create(:user, :tecnico, company: company, active: true, name: "Joao Tecnico", email: "joao.tec@example.com")

      email = described_class.notify_technician_on_finished(order_service, technician)

      expect(email.to).to eq(["joao.tec@example.com"])
      expect(email.subject).to eq("A ordem de serviço ##{order_service.code} foi finalizada!")
      expect(email.body.encoded).to include("Joao Tecnico", order_service.code.to_s)
    end
  end

  describe "#notify_in_progress" do
    it "informa o gestor responsável que a OS está em andamento" do
      gestor = create(:user, :gestor, company: company, active: true, name: "Gestor Em Progresso", email: "gestor.progresso@example.com")
      technician = create(:user, :tecnico, company: company, active: true, name: "Tecnico Em Progresso")
      company.update!(responsible: gestor)
      order_service.users << technician

      email = described_class.notify_in_progress(order_service)

      expect(email.to).to eq(["gestor.progresso@example.com"])
      expect(email.subject).to eq("A ordem de serviço ##{order_service.code} está em andamento!")
      expect(email.body.encoded).to include("Gestor Em Progresso", "Tecnico Em Progresso")
    end
  end

  describe "#send_pdf_to_client" do
    it "anexa o PDF da OS e envia para o cliente" do
      sender = create(:user, :gestor, company: company, active: true, name: "Remetente PDF")
      pdf_double = instance_double(Cmd::Pdf::Create, generate_pdf_data: "PDF_BYTES")
      allow(Cmd::Pdf::Create).to receive(:new).with(order_service).and_return(pdf_double)

      email = described_class.send_pdf_to_client(order_service, sender)

      expect(email.to).to eq(["cliente@example.com"])
      expect(email.subject).to eq("PDF da Ordem de Serviço ##{order_service.code}")
      attachment = email.attachments["ordem_servico_#{order_service.code}.pdf"]
      expect(attachment).to be_present
      expect(attachment.mime_type).to eq("application/pdf")
      html_body = email.html_part.decoded
      expect(html_body).to include(sender.name, company.name)
    end
  end

  describe "#send_receipt_to_client" do
    it "anexa o comprovante de recebimento" do
      sender = create(:user, :gestor, company: company, active: true)
      receipt_double = instance_double(
        Cmd::Pdf::CreateOrderServiceReceipt,
        filename: "comprovante_recebimento_#{order_service.code}.pdf",
        generate_pdf_data: "PDF_BYTES"
      )
      allow(Cmd::Pdf::CreateOrderServiceReceipt).to receive(:new)
        .with(order_service, kind: :recebimento, generated_by: sender)
        .and_return(receipt_double)

      email = described_class.send_receipt_to_client(order_service, sender)

      expect(email.to).to eq(["cliente@example.com"])
      expect(email.subject).to eq("Comprovante de recebimento - OS ##{order_service.code}")
      expect(email.attachments["comprovante_recebimento_#{order_service.code}.pdf"]).to be_present
      html_body = email.html_part&.decoded || email.body.decoded
      expect(html_body).to include("comprovante de recebimento")
    end
  end

  describe "#send_return_receipt_to_client" do
    it "anexa o comprovante de devolução" do
      sender = create(:user, :gestor, company: company, active: true)
      receipt_double = instance_double(
        Cmd::Pdf::CreateOrderServiceReceipt,
        filename: "comprovante_devolucao_#{order_service.code}.pdf",
        generate_pdf_data: "PDF_BYTES"
      )
      allow(Cmd::Pdf::CreateOrderServiceReceipt).to receive(:new)
        .with(order_service, kind: :devolucao, generated_by: sender)
        .and_return(receipt_double)

      email = described_class.send_return_receipt_to_client(order_service, sender)

      expect(email.to).to eq(["cliente@example.com"])
      expect(email.subject).to eq("Comprovante de devolução - OS ##{order_service.code}")
      expect(email.attachments["comprovante_devolucao_#{order_service.code}.pdf"]).to be_present
      html_body = email.html_part&.decoded || email.body.decoded
      expect(html_body).to include("comprovante de devolução")
    end
  end
end
