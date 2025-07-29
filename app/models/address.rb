class Address < ApplicationRecord
  belongs_to :client

  before_validation :format_zip_code

  validates :street, :number, :neighborhood, :zip_code, :city, :state, :country, presence: true
  validates :street, length: { minimum: 2, maximum: 100 }
  validates :number, length: { maximum: 10 }
  validates :complement, length: { maximum: 50 }, allow_blank: true
  validates :neighborhood, length: { minimum: 2, maximum: 50 }
  validates :zip_code, format: { with: /\A\d{5}-\d{3}\z/, message: "deve estar no formato 00000-000" }
  validates :city, length: { minimum: 2, maximum: 50 }
  validates :state, length: { is: 2 }, format: { with: /\A[A-Z]{2}\z/, message: "deve ser a sigla do estado (ex: SP)" }
  validates :country, length: { minimum: 2, maximum: 50 }
  validates :address_type, inclusion: {
                             in: %w[principal entrega cobranca outros],
                             message: "%{value} não é um tipo válido",
                           }, allow_blank: true

  def full_address
    [
      street,
      number,
      complement.presence,
      neighborhood,
      city,
      state,
      zip_code,
      country,
    ].compact.reject(&:blank?).join(", ")
  end

  private

  def format_zip_code
    return if zip_code.blank?
    digits = zip_code.gsub(/\D/, "")
    self.zip_code = "#{digits[0..4]}-#{digits[5..7]}" if digits.length == 8
  end
end
