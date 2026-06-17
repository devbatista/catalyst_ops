class Mobile::V1::UsersController < Mobile::V1::BaseController
  def me
    mobile_audit(
      action: "mobile.api.users.me.viewed",
      metadata: { user_id: current_mobile_user.id }
    )

    render json: mobile_user_payload(current_mobile_user), status: :ok
  end
end
