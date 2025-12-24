class App::ConfigurationsController < ApplicationController
  skip_authorization_check 
  
  def index; end

  def update_profile
    user_params = profile_params.dup
    if user_params[:password].blank?
      user_params.delete(:password)
      user_params.delete(:password_confirmation)
    end

    if current_user.update(user_params)
      redirect_to app_configurations_path, notice: "Perfil atualizado com sucesso."
    else
      flash.now[:alert] = current_user.errors.full_messages.to_sentence
      render :index
    end
  end

  def update_company
    company = current_user.company

    if company.update(company_params)
      redirect_to app_configurations_path, notice: "Dados da empresa atualizados com sucesso."
    else
      flash.now[:alert] = company.errors.full_messages.to_sentence
      render :index
    end
  end

  def promote_manager
    company = current_user.company
    user = company.users.find_by(id: params[:user_id])
    if user && user.role == "tecnico"
      user.update(role: "gestor")
      redirect_to app_configurations_path, notice: "Técnico promovido a gestor com sucesso."
    else
      redirect_to app_configurations_path, alert: "Selecione um técnico válido para promover."
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :email, :phone, :password, :password_confirmation)
  end

  def company_params
    params.require(:company).permit(
      :name, :document, :email, :phone, :street, :number, :complement,
      :neighborhood, :city, :state, :zip_code
    )
  end
end