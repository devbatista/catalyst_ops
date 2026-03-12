class Admin::CompaniesController < AdminController
  def index
    @companies = Company.all
  end

  def show
  end
end