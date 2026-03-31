module Cmd
  module Budgets
    class ApproveAndCreateOrderService
      def initialize(budget:, approver_role:)
        @budget = budget
        @approver_role = approver_role.to_s
      end

      def call
        created_order_service = false
        created = nil

        budget.with_lock do
          return budget.order_service if budget.order_service.present?

          order_service = create_order_service!

          budget.update!(
            status: :aprovado,
            approved_at: Time.current,
            rejected_at: nil,
            rejection_reason: nil,
            order_service: order_service
          )

          created_order_service = true
          created = order_service
        end

        if created_order_service && created.present?
          BudgetMailer.notify_manager_order_service_created(
            budget,
            created,
            approver_role: approver_role
          ).deliver_later
        end

        created
      end

      private

      attr_reader :budget, :approver_role

      def create_order_service!
        order_service = OrderService.create!(
          company: budget.company,
          client: budget.client,
          title: order_service_title,
          description: order_service_description,
          status: :pendente,
          observations: order_service_observations
        )

        budget.service_items.each do |item|
          ServiceItem.create!(
            order_service: order_service,
            description: item.description,
            quantity: item.quantity,
            unit_price: item.unit_price
          )
        end

        order_service
      end

      def order_service_title
        raw_title = budget.title.to_s.strip
        return raw_title if raw_title.length >= 5

        "Orçamento ##{budget.code}"
      end

      def order_service_description
        value = budget.description.to_s.strip
        return value if value.length >= 5

        "Criada automaticamente a partir do orçamento ##{budget.code}."
      end

      def order_service_observations
        "OS criada automaticamente após aprovação do orçamento ##{budget.code} por #{approver_role}."
      end
    end
  end
end
