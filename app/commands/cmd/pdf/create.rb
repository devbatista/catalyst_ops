module Cmd
  module Pdf
    class Create
      def initialize(order_service)
        @order_service = order_service
        @company = @order_service.company
        @client = @order_service.client
        @address = @client.addresses.first
      end

      def generate_pdf_data
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
              content: "<b>Ordem de Serviço</b>\n<font size='10' color='DCE8FF'>Detalhes completos da execução</font>",
              inline_format: true,
              background_color: accent,
              text_color: "FFFFFF",
              border_color: accent,
              size: 15,
              padding: [10, 14, 10, 14],
              valign: :center
            },
            {
              content: "<font size='9'>OS ##{@order_service.code}</font>\n<b>#{format_datetime(Time.current)}</b>",
              inline_format: true,
              background_color: accent,
              text_color: "FFFFFF",
              border_color: accent,
              align: :right,
              valign: :center,
              size: 10,
              padding: [10, 12, 10, 10]
            }
          ]],
          width: page_width,
          column_widths: [ page_width * 0.72, page_width * 0.28 ],
          cell_style: { borders: [:top, :bottom, :left, :right] }
        )
        pdf.move_down(6)
        pdf.text "Documento gerado automaticamente para conferência da execução.", size: 9, color: text_muted
        pdf.move_down(12)

        pdf.table(
          [[
            {
              content: "<b>Dados da Empresa</b>",
              inline_format: true,
              background_color: accent,
              text_color: "FFFFFF",
              border_color: accent,
              align: :center,
              size: 10,
              padding: [5, 8, 5, 8]
            }
          ]],
          width: page_width,
          cell_style: { borders: [:top, :bottom, :left, :right] }
        )
        pdf.table(
          [[
            "<b>Empresa:</b> #{safe(@company&.name)}\n" \
            "<b>Documento:</b> #{safe(@company&.formatted_document)}\n" \
            "<b>Telefone:</b> #{safe(@company&.formatted_phone)}\n" \
            "<b>Email:</b> #{safe(@company&.email)}\n" \
            "<b>Endereço:</b> #{safe(@company&.full_address)}"
          ]],
          width: page_width,
          cell_style: { inline_format: true, size: 10, padding: [8, 10, 8, 10], border_color: border, background_color: "FFFFFF", text_color: text_primary }
        )
        pdf.move_down(10)

        pdf.table(
          [[
            {
              content: "<b>Dados do Cliente</b>",
              inline_format: true,
              background_color: accent,
              text_color: "FFFFFF",
              border_color: accent,
              align: :center,
              size: 10,
              padding: [5, 8, 5, 8]
            }
          ]],
          width: page_width,
          cell_style: { borders: [:top, :bottom, :left, :right] }
        )

        info_data = [
          ["Cliente", safe(@client&.name), "Documento", safe(@client&.formatted_document)],
          ["Título", safe(@order_service.title), "Status", @order_service.status.to_s.humanize],
          ["Criada em", format_datetime(@order_service.created_at), "Agendada para", format_datetime(@order_service.scheduled_at)],
          ["Previsão de término", format_datetime(@order_service.expected_end_at), "Telefone", safe(@client&.formatted_phone)],
          ["E-mail", safe(@client&.email), "Código da OS", @order_service.code.to_s],
          ["Endereço", client_full_address, "Bairro / CEP", client_district_and_zip]
        ]

        pdf.table(
          info_data,
          width: page_width,
          cell_style: { size: 10, padding: [6, 8, 6, 8], border_color: border, text_color: text_primary },
          column_widths: [page_width * 0.2, page_width * 0.3, page_width * 0.2, page_width * 0.3]
        ) do |table|
          table.columns(0).font_style = :bold
          table.columns(2).font_style = :bold
          table.columns(0).background_color = accent_soft
          table.columns(2).background_color = accent_soft
        end
        pdf.move_down(10)

        pdf.table(
          [[
            {
              content: "<b>Descrição do Serviço</b>",
              inline_format: true,
              background_color: accent,
              text_color: "FFFFFF",
              border_color: accent,
              align: :center,
              size: 10,
              padding: [5, 8, 5, 8]
            }
          ]],
          width: page_width,
          cell_style: { borders: [:top, :bottom, :left, :right] }
        )
        pdf.table(
          [[safe(@order_service.description)]],
          width: page_width,
          cell_style: { size: 10, padding: [10, 10, 10, 10], border_color: border, background_color: "FFFFFF" }
        )
        pdf.move_down(12)

        pdf.table(
          [[
            {
              content: "<b>Itens de Serviço</b>",
              inline_format: true,
              background_color: accent,
              text_color: "FFFFFF",
              border_color: accent,
              align: :center,
              size: 10,
              padding: [5, 8, 5, 8]
            }
          ]],
          width: page_width,
          cell_style: { borders: [:top, :bottom, :left, :right] }
        )

        item_rows = [[ "Descrição", "Qtd.", "Valor unitário", "Total" ]]
        @order_service.service_items.order(:created_at).each do |item|
          unit_price = item.unit_price.to_d
          quantity = item.quantity.to_d
          item_rows << [
            safe(item.description),
            item.quantity.to_s,
            brl(unit_price),
            brl(quantity * unit_price)
          ]
        end

        item_rows << [ "Sem itens cadastrados", "-", "-", "-" ] if item_rows.size == 1

        pdf.table(
          item_rows,
          header: true,
          width: page_width,
          cell_style: { size: 10, padding: [8, 10, 8, 10], border_color: border, inline_format: true, text_color: text_primary },
          row_colors: [ "FFFFFF", soft_bg ],
          column_widths: [page_width * 0.42, page_width * 0.12, page_width * 0.23, page_width * 0.23]
        ) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = accent_soft
          table.row(0).text_color = "1D4ED8"
          table.columns(1..3).align = :right
          table.rows(1..-1).columns(0).align = :left
          table.cells.border_width = 1
        end
        pdf.move_down(10)
        totals_data = [
          [{ content: "Subtotal: #{brl(@order_service.subtotal_value)}", align: :right }],
          [{ content: "Desconto: #{brl(@order_service.discount_amount)}", align: :right }],
          [{ content: "Total: #{brl(@order_service.total_value)}", align: :right, font_style: :bold }]
        ]
        pdf.table(
          totals_data,
          width: page_width,
          cell_style: { size: 12, padding: [6, 10, 6, 10], border_color: border, background_color: soft_bg, text_color: text_primary }
        )

        if @order_service.discount_applied? && @order_service.discount_reason.present?
          pdf.move_down(8)
          pdf.table(
            [[{ content: "Motivo do desconto: #{safe(@order_service.discount_reason)}", align: :left }]],
            width: page_width,
            cell_style: { size: 10, padding: [6, 10, 6, 10], border_color: border, background_color: "FFFFFF" }
          )
        end

        if @order_service.observations.present?
          pdf.move_down(12)
          pdf.table(
            [[
              {
                content: "<b>Observações</b>",
                inline_format: true,
                background_color: accent,
                text_color: "FFFFFF",
                border_color: accent,
                align: :center,
                size: 10,
                padding: [5, 8, 5, 8]
              }
            ]],
            width: page_width,
            cell_style: { borders: [:top, :bottom, :left, :right] }
          )
          pdf.table(
            [[safe(@order_service.observations)]],
            width: page_width,
            cell_style: { size: 10, padding: [8, 10, 8, 10], border_color: border, background_color: "FFFFFF", text_color: text_primary }
          )
        end

        pdf.move_down(10)
        pdf.stroke_color border
        pdf.stroke_horizontal_rule
        pdf.move_down(6)
        pdf.fill_color text_muted
        pdf.text "Catalyst Ops • Ordem de Serviço ##{@order_service.code}", size: 8, align: :center
        pdf.fill_color "000000"

        pdf.render
      end

      def attach_pdf
        pdf_data = generate_pdf_data
        @order_service.attachments.attach(
          io: StringIO.new(pdf_data),
          filename: "ordem_servico_#{@order_service.id}.pdf",
          content_type: "application/pdf",
        )
      end

      private

      def safe(value)
        value.to_s.strip.presence || "-"
      end

      def format_datetime(value)
        return "-" if value.blank?

        I18n.l(value, format: :short)
      end

      def client_full_address
        street = safe(@address&.street)
        number = safe(@address&.number)
        city = safe(@address&.city)
        state = safe(@address&.state)
        "#{street}, #{number} - #{city}/#{state}"
      end

      def client_district_and_zip
        neighborhood = safe(@address&.neighborhood)
        zip = safe(@address&.zip_code)
        "#{neighborhood} / #{zip}"
      end

      def brl(value)
        ActionController::Base.helpers.number_to_currency(
          value,
          unit: "R$ ",
          separator: ",",
          delimiter: "."
        )
      end
    end
  end
end
