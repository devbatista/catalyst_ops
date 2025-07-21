class UsersController < ApplicationController
  load_and_authorize_resource
  
  def index
    @users = case current_user.role
            when 'admin'
              @users.order(:name)
            when 'gestor'
              @users.tecnicos.order(:name)
            end
  end

  def show
    @assignments = @user.assignments.includes(:order_service)
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'Usuário atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    permitted = [:name]
    permitted << :role if can?(:manage, User)
    params.require(:user).permit(permitted)
  end
end