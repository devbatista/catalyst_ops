class Admin::UsersController < AdminController
  def index
    per_page = params[:per].presence || 10
    scope = User.search(params[:q])

    if params[:role].present?
      scope = scope.where(role: params[:role])
    end

    @users = scope.order(created_at: :desc).page(params[:page]).per(per_page)
  end

  def show
    @user = User.find(params[:id])
  end
end