class App::TermsOfUseController < ApplicationController
  skip_authorization_check

  def show
    @company = current_user.company
  end

  def update
    @company = current_user.company

    unless params[:accept_terms] == "1"
      flash.now[:alert] = "Você precisa aceitar o contrato para continuar."
      return render :show, status: :unprocessable_entity
    end

    @company.accept_current_terms!(
      user: current_user,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    Audit::Log.call(
      action: "terms.accepted",
      actor: current_user,
      company: @company,
      resource: @company,
      metadata: {
        version: @company.terms_version_accepted,
        accepted_at: @company.terms_accepted_at,
        accepted_ip: @company.terms_accepted_ip,
        accepted_by_user_id: @company.terms_accepted_by_user_id
      }
    )

    redirect_to app_dashboard_path, notice: "Contrato de utilização aceito com sucesso."
  end
end
