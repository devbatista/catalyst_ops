class Admin::SubscriptionsController < AdminController
  def index
    per_page = params[:per].presence || 10
    @subscriptions = Subscription.includes(:plan, :company).order(created_at: :desc).page(params[:page]).per(per_page)
  end

  def show
    @subscription = Subscription.find(params[:id])
  end
end