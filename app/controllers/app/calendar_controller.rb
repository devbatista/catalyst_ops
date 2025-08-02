class App::CalendarController < ApplicationController
  skip_authorization_check

  def index; end

  def events
    order_services = current_user.company.order_services.includes(:users)

    events = order_services.map do |os|
      {
        id: os.id,
        title: "#{os.title} - Técnicos: #{os.users.map(&:name).join(', ')}",
        start: os.scheduled_at
      }
    end

    render json: events
  end
end