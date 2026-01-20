class Admin::DashboardController < ApplicationController
  skip_authorization_check
  layout "admin"

  def index
    @companies = Company.all
  end
end