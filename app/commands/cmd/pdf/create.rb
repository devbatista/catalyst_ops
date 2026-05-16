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
        settings = pdf_settings
        accent = settings&.accent_color.presence || default_accent_color
        accent_soft = "EAF2FF"
        border = "D6DEE8"
        soft_bg = "F7FAFD"
        text_primary = "0F172A"
        text_muted = "64748B"
        page_width = pdf.bounds.width
        light_header = light_color?(accent)
        header_text_color = settings&.header_text_color.presence || (light_header ? text_primary : "FFFFFF")
        header_subtitle_color = settings&.header_text_color.presence || (light_header ? text_muted : "DCE8FF")
        header_border = light_header ? border : accent
        header_subtitle = settings&.header_subtitle.presence || "Detalhes completos da execução"
        document_note = settings&.document_note.presence || "Documento gerado automaticamente para conferência da execução."
        footer_text = settings&.footer_text.presence || "Catalyst Ops • Ordem de Serviço ##{@order_service.code}"

        header_row = [
          {
            content: "<b>Ordem de Serviço</b>\n<font size='10' color='#{header_subtitle_color}'>#{inline_safe(header_subtitle)}</font>",
            inline_format: true,
            background_color: accent,
            text_color: header_text_color,
            border_color: header_border,
            size: 15,
            padding: [10, 14, 10, 14],
            valign: :center
          },
          {
            content: "<font size='9'>OS ##{@order_service.code}</font>\n<b>#{format_datetime(Time.current)}</b>",
            inline_format: true,
            background_color: accent,
            text_color: header_text_color,
            border_color: header_border,
            align: :right,
            valign: :center,
            size: 10,
            padding: [10, 12, 10, 10]
          }
        ]
        column_widths = [page_width * 0.72, page_width * 0.28]

        if logo_image(settings)
          header_row.unshift(
            {
              image: logo_image(settings),
              fit: [page_width * 0.16, 42],
              position: :center,
              vposition: :center,
              background_color: "FFFFFF",
              border_color: header_border,
              padding: [8, 10, 8, 10]
            }
          )
          column_widths = [page_width * 0.18, page_width * 0.54, page_width * 0.28]
        end

        pdf.table(
          [header_row],
          width: page_width,
          column_widths: column_widths,
          cell_style: { borders: [:top, :bottom, :left, :right] }
        )
        pdf.move_down(6)
        pdf.text safe(document_note), size: 9, color: text_muted
        pdf.move_down(12)

        if show_company_data?
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
        end

        if show_client_data?
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
        end

        if show_service_description?
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
        end

        if show_service_items?
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
        end
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

        if show_discount_reason? && @order_service.discount_applied? && @order_service.discount_reason.present?
          pdf.move_down(8)
          pdf.table(
            [[{ content: "Motivo do desconto: #{safe(@order_service.discount_reason)}", align: :left }]],
            width: page_width,
            cell_style: { size: 10, padding: [6, 10, 6, 10], border_color: border, background_color: "FFFFFF" }
          )
        end

        if show_observations? && @order_service.observations.present?
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
        pdf.text safe(footer_text), size: 8, align: :center
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

      def pdf_settings
        @pdf_settings ||= begin
          setting = @company&.pdf_setting_for(:order_service)
          setting if @company&.pdf_customization_available? && setting&.enabled?
        end
      end

      def default_accent_color
        "21262E"
      end

      def show_company_data?
        pdf_settings.blank? || pdf_settings.show_company_data?
      end

      def show_client_data?
        pdf_settings.blank? || pdf_settings.show_client_data?
      end

      def show_service_description?
        pdf_settings.blank? || pdf_settings.show_service_description?
      end

      def show_service_items?
        pdf_settings.blank? || pdf_settings.show_service_items?
      end

      def show_discount_reason?
        pdf_settings.blank? || pdf_settings.show_discount_reason?
      end

      def show_observations?
        pdf_settings.blank? || pdf_settings.show_observations?
      end

      def safe(value)
        value.to_s.strip.presence || "-"
      end

      def inline_safe(value)
        ERB::Util.html_escape(safe(value))
      end

      def logo_image(settings)
        return unless settings
        return unless settings.logo.attached?

        @logo_image ||= StringIO.new(settings.logo.download)
      rescue StandardError
        nil
      end

      def light_color?(hex_color)
        hex = hex_color.to_s.delete_prefix("#")
        return false unless hex.match?(/\A[0-9A-Fa-f]{6}\z/)

        red = hex[0..1].to_i(16)
        green = hex[2..3].to_i(16)
        blue = hex[4..5].to_i(16)
        luminance = ((0.299 * red) + (0.587 * green) + (0.114 * blue)) / 255
        luminance > 0.86
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
