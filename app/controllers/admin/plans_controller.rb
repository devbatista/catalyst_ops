class Admin::PlansController < AdminController
  before_action :set_plan, only: %i[show edit update]

  def index
    per_page = params[:per].presence || 10
    @plans = Plan.order(created_at: :desc).page(params[:page]).per(per_page)
  end

  def show
  end

  def new
    @plan = Plan.new
  end

  def create
    @plan = Plan.new(plan_params)
    if @plan.save
      redirect_to admin_plan_path(@plan), notice: "Plano criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @plan.update(plan_params)
      redirect_to admin_plan_path(@plan), notice: "Plano atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_plan
    @plan = Plan.find(params[:id])
  end

  def plan_params
    params.require(:plan).permit(
      :name,
      :reason,
      :status,
      :external_id,
      :external_reference,
      :frequency,
      :frequency_type,
      :transaction_amount,
      :init_point,
      :back_url,
      :max_technicians,
      :max_orders,
      :support_level
    )
  end
end