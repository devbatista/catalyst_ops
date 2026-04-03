class App::FinancialController < ApplicationController
  def index
    authorize! :read, :financial

    @filters = {
      status: params[:status].presence || "all",
    }

    base_scope = current_user.company.order_services
                             .includes(:client, :service_items, :users)
                             .where.not(status: :cancelada)

    @realized_orders = base_scope.finalizada.order(updated_at: :desc)
    @pending_orders = base_scope.where(status: [:pendente, :agendada, :em_andamento, :concluida, :atrasada])
                                .order(updated_at: :desc)

    @realized_total = order_services_total(@realized_orders)
    @pending_total = order_services_total(@pending_orders)
    @overall_total = @realized_total + @pending_total
    @finalized_orders_count = @realized_orders.count
    @pending_orders_count = @pending_orders.count

    @orders = case @filters[:status]
              when "realized"
                @realized_orders
              when "pending"
                @pending_orders
              else
                base_scope.order(updated_at: :desc)
              end
    @orders = @orders.page(params[:page]).per(params[:per] || 10)
  end

  private

  def order_services_total(scope)
    scope.to_a.sum(&:total_value)
  end
end
