class Admin::DashboardController < AdminController
  def index
    @companies = Company.all
  end
end