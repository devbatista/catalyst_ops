class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  skip_authorization_check

  def new;end

  def create
    user = User.find_by(email: params[:email].to_s.downcase.strip)
    if user&.valid_password?(params[:password])
      sign_in(user)
      # Redireciona para o subdomínio correto conforme o perfil
      target_subdomain = user.admin? ? "admin" : "app"
      redirect_to root_url(subdomain: target_subdomain), notice: "Login realizado com sucesso!"
    else
      flash.now[:alert] = "E-mail ou senha inválidos."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out(current_user)
    redirect_to login_url(subdomain: "login"), notice: "Logout realizado com sucesso!"
  end
end