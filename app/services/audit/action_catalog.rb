module Audit
  module ActionCatalog
    AUTH = %w[
      auth.login.succeeded
      auth.login.failed
      auth.logout.succeeded
      auth.password_reset.requested
      auth.password_reset.completed
      auth.signup.started
      auth.signup.completed
      auth.signup.confirmed
    ].freeze

    USERS = %w[
      user.created
      user.updated
      user.deleted
      user.role.changed
      technician.created
      technician.updated
      technician.activated
      technician.deactivated
    ].freeze

    CLIENTS = %w[
      client.created
      client.updated
      client.deleted
      client.restored
    ].freeze

    ORDER_SERVICES = %w[
      order_service.created
      order_service.updated
      order_service.deleted
      order_service.status.changed
      order_service.assigned
      order_service.unassigned
      order_service.finished
      order_service.cancelled
      order_service.attachment.added
      order_service.attachment.removed
    ].freeze

    BUDGETS = %w[
      budget.created
      budget.updated
      budget.status.changed
      budget.sent_for_approval
      budget.approved
      budget.rejected
    ].freeze

    COUPONS = %w[
      coupon.created
      coupon.updated
      coupon.deleted
      coupon.applied
      coupon.rejected
    ].freeze

    SUBSCRIPTIONS = %w[
      subscription.created
      subscription.updated
      subscription.status.changed
      subscription.cancellation.scheduled
      subscription.cancellation.resumed
      subscription.payment.generated
      subscription.payment.pending
      subscription.payment.approved
      subscription.payment.failed
      subscription.reconciled
      subscription.reprocess.pending_payment
    ].freeze

    WEBHOOKS = %w[
      webhook.received
      webhook.duplicate
      webhook.signature.valid
      webhook.signature.invalid
      webhook.processed
      webhook.failed
    ].freeze

    MOBILE_API = %w[
      mobile.api.auth.me.viewed
      mobile.api.auth.logout_all.succeeded
      mobile.api.order_services.listed
      mobile.api.order_services.viewed
      mobile.api.budgets.listed
      mobile.api.budgets.viewed
    ].freeze

    SYSTEM = %w[
      job.started
      job.completed
      job.failed
      job.retry_scheduled
      system.deploy.executed
      system.migration.executed
    ].freeze

    GROUPS = {
      auth: AUTH,
      users: USERS,
      clients: CLIENTS,
      order_services: ORDER_SERVICES,
      budgets: BUDGETS,
      coupons: COUPONS,
      subscriptions: SUBSCRIPTIONS,
      webhooks: WEBHOOKS,
      mobile_api: MOBILE_API,
      system: SYSTEM
    }.freeze

    ALL = GROUPS.values.flatten.freeze

    def self.include?(action)
      ALL.include?(action.to_s)
    end
  end
end
