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

  def send_test_email
    @user = User.find(params[:id])

    begin
      UserMailer.test_email(@user, current_user.email).deliver_later
    rescue StandardError => e
      Rails.logger.error("[Admin::UsersController] Falha ao enviar e-mail de teste para usuário #{@user.id}: #{e.class} - #{e.message}")
      redirect_to admin_user_path(@user), alert: "Não foi possível enviar o e-mail de teste."
      return
    end

    redirect_to admin_user_path(@user), notice: "E-mail de teste enviado para #{@user.email} com cópia para #{current_user.email}."
  end
end
