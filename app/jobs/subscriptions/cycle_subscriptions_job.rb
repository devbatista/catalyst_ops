
class Subscriptions::CycleSubscriptionsJob < ApplicationJob
  sidekiq_options queue: :default, retry: 3

  def perform
    
  end
end