class Admin::SubscriptionReconciliationEventsController < AdminController
  def index
    per_page = params[:per].presence || 10
    scope = SubscriptionReconciliationEvent.includes(:company, :subscription).recent

    if params[:q].present?
      query = "%#{params[:q].strip}%"
      scope = scope.joins(:company, :subscription).where(
        "companies.name ILIKE :q OR subscription_reconciliation_events.gateway_identifier ILIKE :q OR CAST(subscriptions.id AS text) ILIKE :q",
        q: query
      )
    end

    scope = scope.where(result_status: params[:result_status]) if params[:result_status].present?
    scope = scope.where(source_job: params[:source_job]) if params[:source_job].present?

    if params[:divergent].present?
      scope = scope.where(divergent: ActiveModel::Type::Boolean.new.cast(params[:divergent]))
    end

    if params[:resolved].present?
      scope = scope.where(resolved: ActiveModel::Type::Boolean.new.cast(params[:resolved]))
    end

    @subscription_reconciliation_events = scope.page(params[:page]).per(per_page)
    @source_jobs = SubscriptionReconciliationEvent.distinct.order(:source_job).pluck(:source_job)
  end

  def show
    @subscription_reconciliation_event = SubscriptionReconciliationEvent
      .includes(:company, :subscription)
      .find(params[:id])
  end
end
