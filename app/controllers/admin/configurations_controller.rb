class Admin::ConfigurationsController < AdminController
  PROFILE_ID = "profile".freeze

  def index
    load_configuration_dashboard
  end

  def edit
    return render_not_found unless profile_configuration?

    redirect_to admin_configurations_path, notice: "Use a seção Perfil para editar seus dados."
  end

  def update
    return render_not_found unless profile_configuration?

    @admin_user = current_user
    attrs = profile_params.dup

    if attrs[:password].blank?
      attrs.delete(:password)
      attrs.delete(:password_confirmation)
    end

    if @admin_user.update(attrs)
      redirect_to admin_configurations_path, notice: "Perfil atualizado com sucesso."
    else
      load_configuration_dashboard
      flash.now[:alert] = @admin_user.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  private

  def profile_configuration?
    params[:id].to_s == PROFILE_ID
  end

  def render_not_found
    redirect_to admin_configurations_path, alert: "Configuração não encontrada."
  end

  def profile_params
    params.require(:user).permit(:name, :email, :phone, :password, :password_confirmation)
  end

  def load_configuration_dashboard
    @admin_user = current_user
    @platform_settings = build_platform_settings
    @system_overview = build_system_overview
    @service_status = build_service_status
    @sidekiq_metrics = build_sidekiq_metrics
    @integration_status = build_integration_status
    @security_settings = build_security_settings
    @quick_links = build_quick_links
  end

  def build_system_overview
    {
      companies_total: Company.count,
      companies_active: Company.active.count,
      users_active: User.active.count,
      subscriptions_active: Subscription.active_records.count,
      order_services_open: OrderService.where.not(status: [:finalizada, :cancelada]).count
    }
  rescue StandardError
    {
      companies_total: 0,
      companies_active: 0,
      users_active: 0,
      subscriptions_active: 0,
      order_services_open: 0
    }
  end

  def build_service_status
    [
      { name: "Web", status: "online", detail: "Aplicação Rails ativa" },
      { name: "Banco de dados", status: db_online? ? "online" : "offline", detail: db_online? ? "Conectado" : "Sem conexão" },
      { name: "Redis", status: redis_online? ? "online" : "offline", detail: redis_online? ? "Conectado" : "Sem conexão" },
      { name: "Sidekiq", status: sidekiq_online? ? "online" : "offline", detail: sidekiq_online? ? "Processos ativos" : "Sem processos ativos" }
    ]
  end

  def build_sidekiq_metrics
    {
      queue_default: safe_sidekiq_metric { Sidekiq::Queue.new("default").size },
      queue_mailers: safe_sidekiq_metric { Sidekiq::Queue.new("mailers").size },
      retries: safe_sidekiq_metric { Sidekiq::RetrySet.new.size },
      dead: safe_sidekiq_metric { Sidekiq::DeadSet.new.size }
    }
  end

  def build_integration_status
    [
      { name: "Mercado Pago", value: ENV["MP_PRODUCTION_ACCESS_TOKEN"].present? ? "configurado" : "não configurado" },
      { name: "Webhook secret", value: ENV["MP_WEBHOOK_SECRET"].present? ? "configurado" : "não configurado" },
      { name: "SMTP", value: ENV["SMTP_ADDRESS"].present? ? "configurado" : "não configurado" }
    ]
  end

  def build_security_settings
    [
      { key: "Ambiente", value: Rails.env },
      { key: "Assinatura de webhook obrigatória", value: bool_label(ENV.fetch("MP_WEBHOOK_REQUIRE_SIGNATURE", Rails.env.production?)) },
      { key: "Retenção audit_events (dias)", value: ENV.fetch("AUDIT_LOG_RETENTION_DAYS", "180") }
    ]
  end

  def build_quick_links
    [
      { label: "Logs", path: admin_logs_path },
      { label: "Planos", path: admin_plans_path },
      { label: "Cupons", path: admin_coupons_path },
      { label: "Tickets", path: admin_tickets_path },
      { label: "Base de Conhecimento", path: admin_knowledge_base_index_path }
    ]
  end

  def build_platform_settings
    [
      { key: "Host da aplicação", value: ENV.fetch("APP_HOST", "não definido") },
      { key: "Protocolo", value: ENV.fetch("APP_PROTOCOL", "não definido") },
      { key: "Webhook assinado obrigatório", value: bool_label(ENV.fetch("MP_WEBHOOK_REQUIRE_SIGNATURE", Rails.env.production?)) },
      { key: "Retenção de auditoria (dias)", value: ENV.fetch("AUDIT_LOG_RETENTION_DAYS", "180") },
      { key: "Lote limpeza auditoria", value: ENV.fetch("AUDIT_LOG_CLEANUP_BATCH_SIZE", "1000") },
      { key: "SMTP configurado", value: ENV["SMTP_ADDRESS"].present? ? "sim" : "não" }
    ]
  end

  def bool_label(value)
    ActiveModel::Type::Boolean.new.cast(value) ? "sim" : "não"
  end

  def db_online?
    ActiveRecord::Base.connection_pool.with_connection(&:active?)
  rescue StandardError
    false
  end

  def redis_online?
    Sidekiq.redis { |conn| conn.ping == "PONG" }
  rescue StandardError
    false
  end

  def sidekiq_online?
    safe_sidekiq_metric { Sidekiq::ProcessSet.new.size } > 0
  end

  def safe_sidekiq_metric
    require "sidekiq/api"
    yield
  rescue StandardError
    0
  end
end
