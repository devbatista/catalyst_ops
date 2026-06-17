class Mobile::V1::BaseController < ActionController::API
  before_action :authenticate_mobile_user!
  around_action :with_mobile_current_context
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  attr_reader :current_mobile_session
  attr_reader :current_mobile_user

  private

  def authenticate_mobile_user!
    token = bearer_token
    return render_unauthorized("Token de acesso não informado.") if token.blank?

    session = MobileApiSession.find_active_by_raw_token(token)
    return render_unauthorized("Token inválido ou expirado.") if session.blank?

    user = session.user
    return render_unauthorized("Usuário inativo.") unless user.active?
    return render_unauthorized("Acesso da empresa está desativado.") unless user.access_enabled?

    @current_mobile_session = session
    @current_mobile_user = user
    touch_mobile_session_usage
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    return if header.blank?

    scheme, token = header.split(" ", 2)
    return if scheme.to_s.downcase != "bearer"

    token
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end

  def render_not_found
    render json: { error: "Registro não encontrado." }, status: :not_found
  end

  def mobile_company
    current_mobile_user&.company
  end

  def mobile_order_services_scope
    mobile_company.order_services.by_technician(current_mobile_user.id)
  end

  def mobile_user_payload(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: formatted_phone(user.phone),
      role: mobile_role_label(user),
      roleKey: user.role,
      initials: initials_for(user.name),
      company: {
        id: user.company_id,
        name: user.company&.name
      }
    }
  end

  def mobile_order_service_payload(order_service, detailed: false)
    client = order_service.client
    technician_names = order_service.users.map(&:name)
    payload = {
      id: order_service.id,
      code: mobile_order_code(order_service),
      title: order_service.title,
      client: client&.name,
      clientId: client&.id,
      scheduledAt: iso8601(order_service.scheduled_at),
      createdAt: iso8601(order_service.created_at),
      deadlineAt: iso8601(order_service.expected_end_at),
      startedAt: iso8601(order_service.started_at),
      finishedAt: iso8601(order_service.finished_at),
      technician: technician_names.first,
      technicians: technician_names,
      totalValueCents: money_cents(order_service.total_value),
      totalValue: money_label(order_service.total_value),
      status: mobile_status_key(order_service.status),
      statusKey: order_service.status,
      statusLabel: mobile_status_label(order_service.status),
      address: client_address(client),
      priority: mobile_priority(order_service),
      description: order_service.description,
      notes: order_service.observations,
      observations: order_service.observations
    }

    return payload unless detailed

    payload.merge(
      rejectionReason: order_service.rejection_reason,
      attachments: mobile_attachments_payload(order_service),
      items: order_service.service_items.order(:created_at).map { |item| mobile_service_item_payload(item) },
      financial: {
        subtotalValueCents: money_cents(order_service.subtotal_value),
        subtotalValue: money_label(order_service.subtotal_value),
        discountType: order_service.discount_type,
        discountValue: order_service.discount_value.to_s,
        discountAmountCents: money_cents(order_service.discount_amount),
        discountAmount: money_label(order_service.discount_amount),
        totalValueCents: money_cents(order_service.total_value),
        totalValue: money_label(order_service.total_value)
      }
    )
  end

  def mobile_audit(action:, resource: nil, metadata: {}, actor: nil, company: nil)
    resolved_actor = actor || current_mobile_user
    resolved_company = company || resolved_actor&.company || mobile_company

    Audit::Log.call(
      action: action,
      actor: resolved_actor,
      company: resolved_company,
      resource: resource,
      metadata: metadata
    )
  end

  def pagination_params(default_per: 20, max_per: 100)
    page = [params[:page].to_i, 1].max
    per = params[:per].to_i
    per = default_per if per <= 0
    per = max_per if per > max_per
    [page, per]
  end

  def render_paginated(data:, collection:)
    render json: {
      data: data,
      meta: {
        current_page: collection.current_page,
        total_pages: collection.total_pages,
        total_count: collection.total_count,
        per_page: collection.limit_value
      }
    }, status: :ok
  end

  def touch_mobile_session_usage
    return if current_mobile_session.blank?

    current_mobile_session.update_column(:last_used_at, Time.current)
  end

  def mobile_status_label(status)
    {
      "pendente" => "Pendente",
      "agendada" => "Agendada",
      "em_andamento" => "Em andamento",
      "concluida" => "Concluída",
      "finalizada" => "Finalizada",
      "cancelada" => "Cancelada",
      "atrasada" => "Atrasada"
    }.fetch(status.to_s, status.to_s.humanize)
  end

  def mobile_status_key(status)
    {
      "pendente" => "pending",
      "agendada" => "scheduled",
      "em_andamento" => "in_progress",
      "concluida" => "completed",
      "finalizada" => "finalized",
      "cancelada" => "cancelled",
      "atrasada" => "overdue"
    }.fetch(status.to_s, status.to_s)
  end

  def normalize_mobile_status(status)
    normalized = status.to_s.strip.downcase
                       .tr("áàãâéêíóôõúç", "aaaaeeiooouc")
                       .gsub(/\s+/, "_")

    {
      "pending" => "pendente",
      "pendente" => "pendente",
      "scheduled" => "agendada",
      "agendada" => "agendada",
      "in_progress" => "em_andamento",
      "em_andamento" => "em_andamento",
      "completed" => "concluida",
      "concluida" => "concluida",
      "finalized" => "finalizada",
      "finalizada" => "finalizada",
      "cancelled" => "cancelada",
      "canceled" => "cancelada",
      "cancelada" => "cancelada",
      "overdue" => "atrasada",
      "atrasada" => "atrasada"
    }[normalized]
  end

  def mobile_order_code(order_service)
    "OS-#{order_service.code}"
  end

  def money_cents(value)
    (value.to_d * 100).round.to_i
  end

  def money_label(value)
    "R$ #{format('%.2f', value.to_d).tr('.', ',')}"
  end

  def iso8601(value)
    value&.iso8601
  end

  def initials_for(name)
    name.to_s.split.map { |part| part[0] }.compact.first(2).join.upcase
  end

  def formatted_phone(phone)
    digits = phone.to_s.gsub(/\D/, "")
    return nil if digits.blank?
    return "+55 #{digits[0, 2]} #{digits[2, 5]}-#{digits[7, 4]}" if digits.length == 11
    return "+55 #{digits[0, 2]} #{digits[2, 4]}-#{digits[6, 4]}" if digits.length == 10

    phone
  end

  def mobile_role_label(user)
    {
      "admin" => "Administrador",
      "gestor" => "Gestor",
      "tecnico" => "Técnico"
    }.fetch(user.role.to_s, user.role.to_s.humanize)
  end

  def client_address(client)
    client&.addresses&.first&.full_address
  end

  def mobile_priority(order_service)
    return "Alta" if order_service.atrasada?
    return "Média" if order_service.scheduled_at.present? && order_service.scheduled_at <= 1.day.from_now

    "Normal"
  end

  def mobile_attachments_payload(order_service)
    order_service.attachments.map do |attachment|
      {
        id: attachment.id,
        name: attachment.filename.to_s,
        url: rails_blob_url(attachment, host: request.host, protocol: request.protocol)
      }
    end
  end

  def mobile_service_item_payload(item)
    total = item.quantity.to_d * item.unit_price.to_d

    {
      id: item.id,
      description: item.description,
      quantity: item.quantity,
      unitPriceCents: money_cents(item.unit_price),
      unitPrice: money_label(item.unit_price),
      totalCents: money_cents(total),
      total: money_label(total)
    }
  end

  def with_mobile_current_context
    Current.user = current_mobile_user
    Current.request_id = request.request_id
    Current.ip_address = request.remote_ip
    Current.user_agent = request.user_agent
    Current.source = "mobile"
    yield
  ensure
    Current.reset
  end
end
