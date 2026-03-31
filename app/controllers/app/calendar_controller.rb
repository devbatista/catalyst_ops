class App::CalendarController < ApplicationController
  skip_authorization_check

  def index; end

  def technicians
    render json: accessible_technicians.order(:name).select(:id, :name).map { |t| { id: t.id, name: t.name } }
  end

  def events
    order_services = if current_user.gestor?
      current_user.company.order_services
    else
      current_user.order_services
    end

    technician_ids = params[:technician_ids].to_s.split(",").map(&:strip).reject(&:blank?).uniq

    if technician_ids.present?
      allowed_technician_ids = accessible_technicians.where(id: technician_ids).pluck(:id)

      if allowed_technician_ids.present?
        order_services = order_services.by_technician(allowed_technician_ids)
      end
    end

    events = order_services.includes(:users).distinct.map do |os|
      {
        id: os.id,
        base_title: os.title,
        default_title: "#{os.title} - Técnicos: #{os.users.map(&:name).join(', ')}",
        start: os.scheduled_at,
        end: os.expected_end_at,
        technicians: os.users.map { |user| { id: user.id, name: user.name } },
        url: app_order_service_url(os, subdomain: "app"), allow_other_host: true
      }
    end

    render json: events
  end

  private

  def accessible_technicians
    if current_user.gestor?
      current_user.company&.users&.tecnicos&.active || User.none
    else
      User.where(id: current_user.id)
    end
  end
end
