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
      changed_fields = current_user.previous_changes.slice("name", "email", "phone", "updated_at")
      log_audit_event!(
        action: "user.updated",
        actor: current_user,
        company: current_user.company,
        resource: current_user,
        metadata: {
          user_id: current_user.id,
          role: current_user.role,
          changes: changed_fields,
          source: "app.configurations#update_profile"
        }
      )
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
      previous_role = user.role
      if user.update(role: "gestor")
        log_audit_event!(
          action: "user.role.changed",
          actor: current_user,
          company: company,
          resource: user,
          metadata: {
            user_id: user.id,
            user_email: user.email,
            role_before: previous_role,
            role_after: user.role,
            source: "app.configurations#promote_manager"
          }
        )
        redirect_to app_configurations_path, notice: "Técnico promovido a gestor com sucesso."
      else
        redirect_to app_configurations_path, alert: user.errors.full_messages.to_sentence
      end
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
