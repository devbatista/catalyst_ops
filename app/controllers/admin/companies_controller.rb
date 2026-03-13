class Admin::CompaniesController < AdminController
  def index
    per_page = params[:per].presence || 10
    @companies = Company.search(params[:q]).order(created_at: :desc).page(params[:page]).per(per_page)
  end

  def show
    @company = Company.find(params[:id])
    @tickets = @company.support_tickets.open_status
  end
end