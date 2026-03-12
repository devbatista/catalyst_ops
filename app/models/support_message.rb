class SupportMessage < ApplicationRecord
  belongs_to :support_ticket
  belongs_to :user

  has_many_attached :attachments

  validates :body, presence: true

  after_create :touch_ticket_last_reply

  private

  def touch_ticket_last_reply
    support_ticket.update!(last_reply_at: created_at)
  end
end