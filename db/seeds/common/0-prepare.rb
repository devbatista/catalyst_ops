puts 'Limpando dados antigos...'

ActiveRecord::Base.connection.disable_referential_integrity do
  AuditEvent.delete_all
  WebhookEvent.delete_all
  SubscriptionReconciliationEvent.delete_all
  Report.delete_all

  Company.update_all(responsible_id: nil)

  SupportMessage.delete_all
  SupportTicket.delete_all
  ServiceItem.delete_all
  Assignment.delete_all
  OrderService.delete_all
  Address.delete_all
  Client.delete_all
  User.delete_all
  Subscription.delete_all
  Company.delete_all
  Plan.delete_all
  KnowledgeBaseArticle.delete_all
end

puts 'Base limpa!'
puts '###################################'
