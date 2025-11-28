class TestJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[TestJob] Executando o TestJob com sucesso!"
  end
end