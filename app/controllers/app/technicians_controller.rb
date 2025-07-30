class App::TechniciansController < ApplicationController
  before_action :set_technician, only: [:show, :edit, :update]
  load_and_authorize_resource class: "User", instance_name: "technician"

  def index
    @technicians = case current_user.role
      when "admin"
        User.where(role: :tecnico).order(:name)
      when "gestor"
        User.where(role: :tecnico, company_id: current_user.company_id).order(:name)
      else
        User.none
      end

    if params[:q].present?
      query = "%#{params[:q]}%"
      @technicians = @technicians.where("name ILIKE ? OR email ILIKE ?", query, query)
    end

    @technicians = @technicians.page(params[:page]).per(params[:per] || 10)
  end

  def show
    @assignments = @technician.assignments.includes(:order_service)
  end

  def edit
  end

  def update
    if @technician.update(user_params)
      redirect_to app_technician_path(@technician), notice: "Técnico atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_technician
    @technician = User.find_by(id: params[:id], role: :técnico)
    redirect_to app_technicians_path, alert: "Técnico não encontrado." unless @technician
  end

  def user_params
    permitted = [:name, :email]
    permitted << :role if can?(:manage, User)
    params.require(:user).permit(permitted)
  end
end
