class Admin::PlansController < AdminController
  def index
    per_page = params[:per].presence || 10
    @plans = Plan.order(created_at: :desc).page(params[:page]).per(per_page)
  end

  def show
    @plan = Plan.find(params[:id])
  end
end