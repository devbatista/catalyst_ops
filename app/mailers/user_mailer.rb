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

  def reset_password_email(user, token)
    @user = user
    @reset_password_url = new_password_url(subdomain: "login", reset_password_token: token)
    mail(to: @user.email, subject: "Redefinição de senha - CatalystOps")
  end
end
