class CompaniesController < ApplicationController
  load_and_authorize_resource

  def index
    @companies = Company.all
  end

  def show
  end

  def new
  end

  def create
    if @company.save
      redirect_to @company, notice: "Empresa criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @company.update(company_params)
      redirect_to @company, notice: "Empresa atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @company.destroy
    redirect_to companies_path, notice: "Empresa removida com sucesso."
  end

  private

  def company_params
    params.require(:company).permit(:name, 
                                    :document,
                                    :email,
                                    :phone,
                                    :address,
                                    :state_registration,
                                    :municipal_registration,
                                    :website,
                                    :responsible_id)
  end
end