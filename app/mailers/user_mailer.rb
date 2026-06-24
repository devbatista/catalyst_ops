class UserMailer < ApplicationMailer
  def welcome_email(user, token)
    @user = user
    @reset_password_url = new_password_url(reset_password_token: token)
    mail(to: @user.email, subject: "Sua conta no CatalystOps foi criada!")
  end

  def signup_confirmation_email(user, confirmation_token)
    @user = user
    @confirmation_url = confirm_signup_url(token: confirmation_token)
    mail(to: @user.email, subject: "Confirme seu cadastro no CatalystOps")
  end

  def starter_welcome_email(user)
    @user = user
    @login_url = login_root_url(subdomain: "login")
    mail(to: @user.email, subject: "Seu plano Starter no CatalystOps está ativo!")
  end

  def signup_welcome_email(user)
    @user = user
    @login_url = login_root_url(subdomain: "login")
    mail(to: @user.email, subject: "Sua conta no CatalystOps foi criada!")
  end

  def reset_password_email(user, token)
    @user = user
    @reset_password_url = new_password_url(subdomain: "login", reset_password_token: token)
    mail(to: @user.email, subject: "Redefinição de senha - CatalystOps")
  end
end
