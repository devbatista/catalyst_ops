class Mobile::V1::HealthController < Mobile::V1::BaseController
  skip_before_action :authenticate_mobile_user!

  def show
    render json: {
      status: "ok",
      service: "catalystops-mobile-api",
      version: "v1"
    }, status: :ok
  end
end
