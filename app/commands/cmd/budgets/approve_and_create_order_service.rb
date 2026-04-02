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

          budget.update!(
            status: :aprovado,
            approved_at: Time.current,
            rejected_at: nil,
            rejection_reason: nil
          )

          order_service = create_order_service!
          budget.update_columns(order_service_id: order_service.id, updated_at: Time.current)

          created_order_service = true
          created = order_service
        end

        if created_order_service && created.present?
          ensure_order_service_created_audit!(created)

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
        parts = [
          "OS criada automaticamente após aprovação do orçamento ##{budget.code} por #{approver_role}."
        ]

        if budget.estimated_delivery_days.present?
          parts << "Prazo de entrega estimado no orçamento: #{budget.estimated_delivery_days} dias."
        end

        parts.join(" ")
      end

      def ensure_order_service_created_audit!(order_service)
        return if order_service.blank?
        return if order_service_created_audit_exists?(order_service)

        Audit::Log.call(
          action: "order_service.created",
          resource: order_service,
          metadata: order_service.auditable_metadata(:created, action: "order_service.created")
        )
      end

      def order_service_created_audit_exists?(order_service)
        scope = AuditEvent.where(
          action: "order_service.created",
          resource_type: "OrderService",
          resource_id: order_service.id.to_s
        )

        return scope.exists? if Current.request_id.blank?

        scope.where(request_id: Current.request_id).exists?
      end
    end
  end
end
