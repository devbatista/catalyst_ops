class Mobile::V1::OrderServicesController < Mobile::V1::BaseController
  def index
    scope = mobile_order_services_scope
              .includes(:client, :users, :service_items, attachments_attachments: :blob)
    scope = scope.where(status: normalized_status_filter) if normalized_status_filter.present?
    scope = scope.where(scheduled_at: parsed_date.all_day) if parsed_date.present?

    page, per = pagination_params
    order_services = scope.order(created_at: :desc).page(page).per(per)
    mobile_audit(
      action: "mobile.api.order_services.listed",
      metadata: {
        status: normalized_status_filter,
        date: params[:date],
        page: page,
        per: per,
        count: order_services.size
      }
    )

    render_paginated(
      data: order_services.map { |order_service| mobile_order_service_payload(order_service, detailed: true) },
      collection: order_services
    )
  end

  def show
    order_service = mobile_order_services_scope
                    .includes(:client, :users, :service_items, attachments_attachments: :blob)
                    .find(params[:id])
    mobile_audit(
      action: "mobile.api.order_services.viewed",
      resource: order_service,
      metadata: { order_service_id: order_service.id }
    )

    render json: { data: mobile_order_service_payload(order_service, detailed: true) }, status: :ok
  end

  def update
    order_service = mobile_order_services_scope.find(params[:id])
    assign_mobile_order_service_attributes(order_service)

    if order_service.save
      attach_files(order_service)
      mobile_audit(
        action: "mobile.api.order_services.updated",
        resource: order_service,
        metadata: { order_service_id: order_service.id, status: order_service.status }
      )

      render json: { data: mobile_order_service_payload(order_service.reload, detailed: true) }, status: :ok
    else
      render json: { error: order_service.errors.full_messages.to_sentence, errors: order_service.errors.to_hash }, status: :unprocessable_entity
    end
  end

  private

  def normalized_status_filter
    return if params[:status].blank?

    @normalized_status_filter ||= normalize_mobile_status(params[:status])
  end

  def parsed_date
    return if params[:date].blank?

    @parsed_date ||= Date.iso8601(params[:date].to_s)
  rescue ArgumentError
    nil
  end

  def assign_mobile_order_service_attributes(order_service)
    order_service.observations = mobile_order_service_params[:notes] if mobile_order_service_params.key?(:notes)
    order_service.observations = mobile_order_service_params[:observations] if mobile_order_service_params.key?(:observations)

    return if mobile_order_service_params[:status].blank?

    status = normalize_mobile_status(mobile_order_service_params[:status])
    order_service.status = status if status.present?
  end

  def attach_files(order_service)
    files = Array(mobile_order_service_params[:attachments]).reject(&:blank?)
    return if files.blank?

    order_service.attachments.attach(files)
  end

  def mobile_order_service_params
    params.permit(:status, :notes, :observations, attachments: [])
  end
end
