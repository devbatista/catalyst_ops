class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  skip_authorization_check

  def new;end

  def create
    user = User.find_by(email: params[:email].to_s.downcase.strip)
    if user&.valid_password?(params[:password])
      sign_in(:user, user)
      
      if user.admin?
        redirect_to admin_root_url(subdomain: 'admin'), 
                    allow_other_host: true, 
                    notice: 'Login realizado com sucesso!'
      else
        redirect_to app_root_url(subdomain: 'app'),
                    allow_other_host: true,
                    notice: 'Login realizado com sucesso!'
      end
    else
      flash.now[:alert] = 'E-mail ou senha inválidos.'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out(current_user)
    redirect_to login_url(subdomain: 'login'), notice: 'Logout realizado com sucesso!'
  end
end