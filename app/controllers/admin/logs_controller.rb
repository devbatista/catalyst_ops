class Admin::LogsController < AdminController
  PER_PAGE_OPTIONS = [10, 20, 30, 50].freeze

  def index
    @per_page = normalized_per_page
    scope = filtered_scope

    respond_to do |format|
      format.html do
        @logs = scope.page(params[:page]).per(@per_page)
      end
      format.csv do
        send_data generate_csv(scope),
                  filename: "audit-events-#{Time.current.strftime('%Y%m%d-%H%M%S')}.csv",
                  type: "text/csv; charset=utf-8"
      end
    end

    @actions = Audit::ActionCatalog::ALL.sort
    @sources = AuditEvent::SOURCES
    @companies = Company.order(:name).pluck(:name, :id)
  end

  def show
    @log = AuditEvent.includes(:company).find(params[:id])
  end

  private

  def filtered_scope
    scope = AuditEvent.includes(:company).recent

    if params[:q].present?
      query = "%#{params[:q].strip}%"
      scope = scope
        .joins("LEFT JOIN users ON audit_events.actor_type = 'User' AND audit_events.actor_id = users.id::text")
        .where(
          "users.name ILIKE :q OR users.email ILIKE :q OR audit_events.actor_id ILIKE :q OR audit_events.request_id ILIKE :q OR audit_events.resource_id ILIKE :q",
          q: query
        )
    end

    scope = scope.where(action: params[:action_name]) if params[:action_name].present?
    scope = scope.where(source: params[:source]) if params[:source].present?
    scope = scope.where(company_id: params[:company_id]) if params[:company_id].present?
    apply_date_filters(scope)
  end

  def normalized_per_page
    per = params[:per].to_i
    PER_PAGE_OPTIONS.include?(per) ? per : PER_PAGE_OPTIONS.first
  end

  def apply_date_filters(scope)
    from = parse_date(params[:date_from])&.beginning_of_day
    to = parse_date(params[:date_to])&.end_of_day

    filtered_scope = scope
    filtered_scope = filtered_scope.where("occurred_at >= ?", from) if from.present?
    filtered_scope = filtered_scope.where("occurred_at <= ?", to) if to.present?
    filtered_scope
  end

  def parse_date(value)
    return nil if value.blank?

    Date.iso8601(value)
  rescue ArgumentError
    nil
  end

  def generate_csv(scope)
    result = Cmd::Exports::GenerateCsv.new(
      collection: scope,
      template: :admin_logs,
      batch_size: 1000
    ).call

    raise StandardError, result.errors unless result.success?

    result.csv
  end
end
