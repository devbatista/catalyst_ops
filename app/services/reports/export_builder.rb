require "csv"
require "fileutils"
require "zip"

module Reports
  class ExportBuilder
    MAX_PERIOD = 6.months
    ORDER_HEADERS = [
      "Codigo", "Cliente", "Status", "Tecnicos", "Criada em", "Agendada para",
      "Inicio", "Fim", "Tempo (h)", "SLA"
    ].freeze
    BUDGET_HEADERS = [
      "Codigo", "Cliente", "Status", "Criado em", "Envio aprovacao", "Aprovado em", "Valor total"
    ].freeze

    CONTENT_TYPES = {
      "csv" => "text/csv; charset=utf-8",
      "xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "pdf" => "application/pdf"
    }.freeze

    attr_reader :report

    def self.call(report)
      new(report).call
    end

    def initialize(report)
      @report = report
      @filters = (report.filters || {}).with_indifferent_access
    end

    def call
      dataset = build_dataset
      format = export_format
      filename = build_filename(format)
      output_path = Rails.root.join("storage", "reports_exports", filename)

      FileUtils.mkdir_p(output_path.dirname)

      case format
      when "csv"
        File.write(output_path, generate_csv(dataset))
      when "xlsx"
        File.binwrite(output_path, generate_xlsx(dataset))
      when "pdf"
        File.binwrite(output_path, generate_pdf(dataset))
      else
        raise ArgumentError, "Formato de exportacao invalido: #{format}"
      end

      { output_path: output_path.to_s, content_type: CONTENT_TYPES.fetch(format) }
    end

    private

    def build_dataset
      source = report.report_type
      range = period_range
      status = @filters[:status]

      if source == "budgets"
        scope = base_budgets_scope.where(created_at: range)
        scope = scope.where(status: status) if status.present? && Budget.statuses.key?(status)
        records = scope.includes(:client).order(created_at: :desc)

        {
          source: source,
          headers: BUDGET_HEADERS,
          rows: records.map { |budget| budget_row(budget) },
          summary: build_budgets_summary(records)
        }
      else
        scope = base_order_services_scope.where(created_at: range)
        scope = scope.where(status: status) if status.present? && OrderService.statuses.key?(status)

        technician_id = @filters[:technician_id].to_s
        if technician_id.present?
          scope = scope.joins(:users).where(users: { id: technician_id })
        end

        records = scope.includes(:client, :users).distinct.order(created_at: :desc)
        {
          source: "service_orders",
          headers: ORDER_HEADERS,
          rows: records.map { |order| order_row(order) },
          summary: build_order_services_summary(records)
        }
      end
    end

    def period_range
      end_date = parse_date(@filters[:end_date]) || Date.current
      start_date = parse_date(@filters[:start_date]) || (end_date - 29.days)
      start_date, end_date = [start_date, end_date].minmax

      max_start_date = (end_date.to_time - MAX_PERIOD).to_date
      start_date = max_start_date if start_date < max_start_date

      start_date.beginning_of_day..end_date.end_of_day
    end

    def parse_date(value)
      return if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def base_order_services_scope
      report.user.admin? ? OrderService.all : report.company.order_services
    end

    def base_budgets_scope
      report.user.admin? ? Budget.all : report.company.budgets
    end

    def order_row(order)
      duration = if order.started_at.present? && order.finished_at.present?
        ((order.finished_at - order.started_at) / 1.hour).round(2)
      end

      sla = if order.expected_end_at.present? && order.finished_at.present?
        order.finished_at <= order.expected_end_at ? "Dentro do SLA" : "Fora do SLA"
      else
        "N/A"
      end

      [
        order.code,
        order.client&.name,
        order.status.humanize,
        order.users.map(&:name).join(", "),
        format_datetime(order.created_at),
        format_datetime(order.scheduled_at),
        format_datetime(order.started_at),
        format_datetime(order.finished_at),
        duration,
        sla
      ]
    end

    def budget_row(budget)
      [
        budget.code,
        budget.client&.name,
        budget.status.humanize,
        format_datetime(budget.created_at),
        format_datetime(budget.approval_sent_at),
        format_datetime(budget.approved_at),
        budget.total_value.to_f
      ]
    end

    def format_datetime(value)
      value.present? ? I18n.l(value, format: :short) : "-"
    end

    def build_order_services_summary(records)
      total = records.size
      finalized = records.count { |order| order.status == "finalizada" }
      canceled = records.count { |order| order.status == "cancelada" }

      {
        "Total OS" => total,
        "Finalizadas" => finalized,
        "Canceladas" => canceled
      }
    end

    def build_budgets_summary(records)
      total = records.size
      approved = records.count { |budget| budget.status == "aprovado" }
      rejected = records.count { |budget| %w[rejeitado cancelado].include?(budget.status) }
      total_value = records.sum { |budget| budget.total_value.to_f }

      {
        "Total orcamentos" => total,
        "Aprovados" => approved,
        "Rejeitados/Cancelados" => rejected,
        "Valor total" => total_value.round(2)
      }
    end

    def generate_csv(dataset)
      CSV.generate(headers: true) do |csv|
        csv << dataset[:headers]
        dataset[:rows].each { |row| csv << row }
        csv << []
        dataset[:summary].each { |key, value| csv << [key, value] }
      end
    end

    def generate_xlsx(dataset)
      sheets = {
        "Relatorio" => [dataset[:headers]] + dataset[:rows],
        "Resumo" => dataset[:summary].map { |key, value| [key, value] }
      }

      build_xlsx_archive(sheets)
    end

    def generate_pdf(dataset)
      Prawn::Document.new(page_size: "A4", page_layout: :landscape) do |pdf|
        pdf.text report.title, size: 16, style: :bold
        pdf.move_down 8
        pdf.text "Gerado em: #{I18n.l(Time.current, format: :short)}", size: 10
        pdf.move_down 10

        table_data = [dataset[:headers]] + dataset[:rows].first(150)
        pdf.table(
          table_data,
          header: true,
          row_colors: %w[F8F9FA FFFFFF],
          cell_style: { size: 8 }
        )

        pdf.move_down 12
        pdf.text "Resumo", style: :bold, size: 11
        dataset[:summary].each do |key, value|
          pdf.text "#{key}: #{value}", size: 10
        end
      end.render
    end

    def export_format
      format = @filters[:export_format].to_s.downcase
      %w[csv xlsx pdf].include?(format) ? format : "csv"
    end

    def build_filename(format)
      timestamp = Time.current.strftime("%Y%m%d%H%M%S")
      source = report.report_type == "service_orders" ? "os" : "orcamentos"
      "report_#{source}_#{report.id}_#{timestamp}.#{format}"
    end

    def build_xlsx_archive(sheets)
      entries = {
        "[Content_Types].xml" => content_types_xml(sheets.keys.size),
        "_rels/.rels" => rels_xml,
        "xl/workbook.xml" => workbook_xml(sheets.keys),
        "xl/_rels/workbook.xml.rels" => workbook_rels_xml(sheets.keys.size),
        "xl/styles.xml" => styles_xml
      }

      sheets.each_with_index do |(sheet_name, rows), index|
        entries["xl/worksheets/sheet#{index + 1}.xml"] = worksheet_xml(sheet_name, rows)
      end

      buffer = Zip::OutputStream.write_buffer do |zip|
        entries.each do |path, content|
          zip.put_next_entry(path)
          zip.write(content)
        end
      end

      buffer.string
    end

    def content_types_xml(sheet_count)
      overrides = (1..sheet_count).map do |index|
        %(<Override PartName="/xl/worksheets/sheet#{index}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>)
      end.join

      <<~XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="xml" ContentType="application/xml"/>
          <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
          <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
          #{overrides}
        </Types>
      XML
    end

    def rels_xml
      <<~XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
        </Relationships>
      XML
    end

    def workbook_xml(sheet_names)
      sheets_xml = sheet_names.each_with_index.map do |name, index|
        %(<sheet name="#{xml_escape(name)}" sheetId="#{index + 1}" r:id="rId#{index + 1}"/>)
      end.join

      <<~XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
                  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <sheets>#{sheets_xml}</sheets>
        </workbook>
      XML
    end

    def workbook_rels_xml(sheet_count)
      relationships = (1..sheet_count).map do |index|
        %(<Relationship Id="rId#{index}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet#{index}.xml"/>)
      end.join

      <<~XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          #{relationships}
          <Relationship Id="rId#{sheet_count + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
        </Relationships>
      XML
    end

    def styles_xml
      <<~XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>
          <fills count="1"><fill><patternFill patternType="none"/></fill></fills>
          <borders count="1"><border/></borders>
          <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
          <cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs>
          <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
        </styleSheet>
      XML
    end

    def worksheet_xml(_sheet_name, rows)
      rows_xml = rows.each_with_index.map do |row, row_index|
        cells_xml = Array(row).each_with_index.map do |value, col_index|
          cell_ref = "#{column_name(col_index)}#{row_index + 1}"
          build_cell_xml(cell_ref, value)
        end.join

        %(<row r="#{row_index + 1}">#{cells_xml}</row>)
      end.join

      <<~XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <sheetData>#{rows_xml}</sheetData>
        </worksheet>
      XML
    end

    def build_cell_xml(cell_ref, value)
      return %(<c r="#{cell_ref}"/>) if value.nil?
      return %(<c r="#{cell_ref}"><v>#{value}</v></c>) if numeric?(value)

      %(<c r="#{cell_ref}" t="inlineStr"><is><t>#{xml_escape(value.to_s)}</t></is></c>)
    end

    def numeric?(value)
      value.is_a?(Numeric) || value.to_s.match?(/\A-?\d+(\.\d+)?\z/)
    end

    def column_name(index)
      value = +""
      i = index
      loop do
        value.prepend((65 + (i % 26)).chr)
        i = (i / 26) - 1
        break if i.negative?
      end
      value
    end

    def xml_escape(value)
      value
        .gsub("&", "&amp;")
        .gsub("<", "&lt;")
        .gsub(">", "&gt;")
        .gsub("\"", "&quot;")
        .gsub("'", "&apos;")
    end
  end
end
