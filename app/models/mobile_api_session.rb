class MobileApiSession < ApplicationRecord
  TOKEN_BYTES = 32

  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.issue_for!(user:, expires_at:)
    raw_token = SecureRandom.hex(TOKEN_BYTES)
    create!(
      user: user,
      token_digest: digest(raw_token),
      expires_at: expires_at,
      last_used_at: Time.current
    )

    raw_token
  end

  def self.find_active_by_raw_token(raw_token)
    return nil if raw_token.blank?

    active.find_by(token_digest: digest(raw_token))
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token.to_s)
  end

  def active?
    revoked_at.nil? && expires_at.future?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end
