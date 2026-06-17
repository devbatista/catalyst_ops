module Cmd
  module Pdf
    class CreateOrderServiceReceipt
      VALID_KINDS = %w[recebimento devolucao].freeze

      def initialize(order_service, kind:, generated_by: nil)
        @order_service = order_service
        @kind = kind.to_s
        @generated_by = generated_by
        @company = @order_service.company
        @client = @order_service.client
      end

      def generate_pdf_data
        raise ArgumentError, "Tipo de comprovante inválido" unless VALID_KINDS.include?(@kind)

        pdf = PdfGenerator.new
        accent = "1F6FEB"
        accent_soft = "EAF2FF"
        border = "D6DEE8"
        soft_bg = "F7FAFD"
        text_primary = "0F172A"
        text_muted = "64748B"
        page_width = pdf.bounds.width

        pdf.table(
          [[
            {
              content: "<b>#{document_title}</b>\n<font size='10' color='DCE8FF'>Ordem de Serviço ##{@order_service.code}</font>",
              inline_format: true,
              background_color: accent,
              text_color: "FFFFFF",
              border_color: accent,
              size: 14,
              padding: [10, 12, 8, 12]
            },
            {
              content: "<font size='9'>Emitido em</font>\n<b>#{format_datetime(Time.current)}</b>",
              inline_format: true,
              background_color: accent,
              text_color: "FFFFFF",
              border_color: accent,
              align: :right,
              valign: :center,
              size: 10,
              padding: [10, 12, 8, 12]
            }
          ]],
          width: page_width,
          column_widths: [page_width * 0.72, page_width * 0.28],
          cell_style: { borders: [:top, :bottom, :left, :right] }
        )
        pdf.move_down(6)
        pdf.text "Documento de controle interno para recebimento/devolução de bens do cliente.", size: 9, color: text_muted
        pdf.move_down(10)

        info_rows = [
          ["Empresa", safe(@company&.name), "Cliente", safe(@client&.name)],
          ["Documento cliente", safe(@client&.formatted_document), "Data de emissão", format_datetime(Time.current)],
          ["Status da OS", @order_service.status.to_s.humanize, "Gerado por", safe(@generated_by&.name)],
          ["Técnicos", safe(@order_service.technician_names), "Código OS", @order_service.code.to_s]
        ]

        pdf.table(
          info_rows,
          width: page_width,
          cell_style: { size: 9, padding: [6, 8, 6, 8], border_color: border, text_color: text_primary },
          column_widths: [page_width * 0.2, page_width * 0.3, page_width * 0.2, page_width * 0.3]
        ) do |table|
          table.columns(0).font_style = :bold
          table.columns(2).font_style = :bold
          table.columns(0).background_color = accent_soft
          table.columns(2).background_color = accent_soft
        end

        pdf.move_down(10)
        section_header(pdf, "Bens/Produtos recebidos do cliente", accent, page_width)

        received_rows = [["Item", "Marca/Modelo", "Série", "Qtd", "Estado/Defeito"]]
        @order_service.received_items.order(:created_at).each do |item|
          details = [item.brand, item.model].reject(&:blank?).join(" / ").presence || "-"
          state_issue = [item.condition_notes, item.reported_issue].reject(&:blank?).join(" | ").presence || "-"
          quantity = item.quantity.present? ? item.quantity.to_s : "-"
          received_rows << [safe(item.name), details, safe(item.serial_number), quantity, state_issue]
        end
        received_rows << ["Sem itens recebidos", "-", "-", "-", "-"] if received_rows.size == 1

        pdf.table(
          received_rows,
          header: true,
          width: page_width,
          cell_style: { size: 9, padding: [6, 6, 6, 6], border_color: border, text_color: text_primary },
          row_colors: ["FFFFFF", soft_bg],
          column_widths: [page_width * 0.22, page_width * 0.20, page_width * 0.16, page_width * 0.08, page_width * 0.34]
        ) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = accent_soft
          table.row(0).text_color = "1D4ED8"
          table.columns(3).align = :center
        end

        pdf.move_down(8)
        accessories = @order_service.received_items.where.not(accessories: [nil, ""]).map(&:accessories).join(" | ")
        pdf.table(
          [[
            {
              content: "<b>Acessórios informados:</b> #{safe(accessories)}",
              inline_format: true,
              size: 9,
              text_color: text_muted,
              background_color: "FFFFFF",
              padding: [6, 8, 6, 8]
            }
          ]],
          width: page_width,
          cell_style: { border_color: border }
        )

        pdf.move_down(10)
        declaration_text =
          if @kind == "recebimento"
            "Declaro o recebimento dos bens/produtos descritos neste comprovante para execução do serviço da OS ##{@order_service.code}."
          else
            "Declaro a devolução dos bens/produtos descritos neste comprovante após execução dos serviços da OS ##{@order_service.code}."
          end

        pdf.table(
          [[
            {
              content: "<b>Declaração</b>\n#{declaration_text}",
              inline_format: true,
              size: 10,
              text_color: text_primary,
              background_color: soft_bg,
              padding: [10, 10, 10, 10]
            }
          ]],
          width: page_width,
          cell_style: { border_color: border }
        )

        pdf.move_down(10)
        pdf.stroke_color border
        pdf.stroke_horizontal_rule
        pdf.move_down(6)
        pdf.fill_color text_muted
        pdf.text "Catalyst Ops • #{document_title} • OS ##{@order_service.code}", size: 8, align: :center
        pdf.fill_color "000000"

        pdf.render
      end

      def filename
        prefix = @kind == "devolucao" ? "comprovante_devolucao" : "comprovante_recebimento"
        "#{prefix}_os_#{@order_service.code}.pdf"
      end

      private

      def document_title
        return "Comprovante de Devolução de Bens/Produtos" if @kind == "devolucao"

        "Comprovante de Recebimento de Bens/Produtos"
      end

      def section_header(pdf, title, color, page_width)
        pdf.table(
          [[
            {
              content: "<b>#{title}</b>",
              inline_format: true,
              background_color: color,
              text_color: "FFFFFF",
              border_color: color,
              align: :left,
              size: 10,
              padding: [5, 8, 5, 8]
            }
          ]],
          width: page_width,
          cell_style: { borders: [:top, :bottom, :left, :right] }
        )
      end

      def safe(value)
        value.to_s.strip.presence || "-"
      end

      def format_datetime(value)
        return "-" if value.blank?

        I18n.l(value, format: :short)
      end

      def brl(value)
        ActionController::Base.helpers.number_to_currency(
          value.to_d,
          unit: "R$ ",
          separator: ",",
          delimiter: "."
        )
      end
    end
  end
end
