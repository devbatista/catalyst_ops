class Admin::CouponsController < AdminController
  before_action :set_coupon, only: %i[show edit update destroy]

  def index
    per_page = params[:per].presence || 10
    @coupons = Coupon.order(created_at: :desc)

    if params[:q].present?
      query = "%#{params[:q].to_s.strip}%"
      @coupons = @coupons.where("code ILIKE :q OR name ILIKE :q", q: query)
    end

    if params[:status].present? && %w[active inactive].include?(params[:status])
      @coupons = @coupons.where(active: params[:status] == "active")
    end

    if params[:benefit_type].present? && Coupon::BENEFIT_TYPES.include?(params[:benefit_type])
      @coupons = @coupons.where(benefit_type: params[:benefit_type])
    end

    @coupons = @coupons.page(params[:page]).per(per_page)
  end

  def show
  end

  def new
    @coupon = Coupon.new(
      active: true,
      benefit_type: "discount",
      discount_type: "percentage",
      first_cycle_only: true
    )
  end

  def create
    @coupon = Coupon.new(coupon_params)

    if @coupon.save
      redirect_to admin_coupon_path(@coupon), notice: "Cupom criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @coupon.update(coupon_params)
      redirect_to admin_coupon_path(@coupon), notice: "Cupom atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @coupon.destroy!
    redirect_to admin_coupons_path, notice: "Cupom excluído com sucesso."
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to admin_coupon_path(@coupon), alert: "Não foi possível excluir este cupom pois ele possui resgates vinculados."
  end

  private

  def set_coupon
    @coupon = Coupon.find(params[:id])
  end

  def coupon_params
    params.require(:coupon).permit(
      :code,
      :name,
      :description,
      :active,
      :benefit_type,
      :discount_type,
      :discount_value,
      :max_redemptions,
      :valid_from,
      :valid_until,
      :first_cycle_only,
      :trial_frequency,
      :trial_frequency_type
    )
  end
end
