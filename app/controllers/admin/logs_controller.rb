class Admin::LogsController < AdminController
  def index
    per_page = params[:per].presence || 10
    scope = AuditEvent.includes(:company).recent

    if params[:q].present?
      query = "%#{params[:q].strip}%"
      scope = scope
        .joins("LEFT JOIN users ON audit_events.actor_type = 'User' AND audit_events.actor_id = users.id::text")
        .where(
          "users.name ILIKE :q OR users.email ILIKE :q OR audit_events.actor_id ILIKE :q",
          q: query
        )
    end

    scope = scope.where(action: params[:action_name]) if params[:action_name].present?
    scope = scope.where(source: params[:source]) if params[:source].present?
    scope = scope.where(company_id: params[:company_id]) if params[:company_id].present?
    scope = apply_date_filters(scope)

    @logs = scope.page(params[:page]).per(per_page)
    @actions = Audit::ActionCatalog::ALL.sort
    @sources = AuditEvent::SOURCES
    @companies = Company.order(:name).pluck(:name, :id)
  end

  def show
    @log = AuditEvent.includes(:company).find(params[:id])
  end

  private

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
end
