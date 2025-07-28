class Client < ApplicationRecord
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :document, presence: true, uniqueness: { case_sensitive: false }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  validates :phone, presence: true, format: { with: /\A[\d\s\-\(\)]+\z/ }, length: { minimum: 10, maximum: 11 }

  validate :document_must_be_valid

  belongs_to :company

  has_many :order_services, dependent: :destroy
  has_many :addresses, dependent: :destroy

  accepts_nested_attributes_for :addresses, allow_destroy: true

  scope :active_clients, -> {
          joins(:order_services)
            .where(order_services: {
                     created_at: 6.months.ago..Time.current,
                   }).distinct
        }
  scope :by_name, ->(name) { where("name ILIKE ?", "%#{name}%") }
  scope :recent, -> { order(created_at: :desc) }

  before_validation :normalize_attributes

  def self.search(query = nil)
    if query.present?
      where(
        "name ILIKE :q OR email ILIKE :q OR phone ILIKE :q OR document ILIKE :q", q: "%#{query}%",
      )
    else
      all
    end
  end

  def active_orders
    order_services.where.not(status: [:concluida, :cancelada])
  end

  def pending_orders_count
    order_services.agendada.count
  end

  def completed_orders_count
    order_services.concluida.count
  end

  def total_orders_value
    order_services.sum { |os| os.total_value }
  end

  def formatted_total_value
    "R$ #{"%.2f" % total_orders_value}"
  end

  def has_active_orders?
    active_orders.any?
  end

  def can_be_deleted?
    !has_active_orders?
  end

  def formatted_document
    return document unless document.present?

    if cpf?
      CPF.new(document).formatted
    elsif cnpj?
      CNPJ.new(document).formatted
    else
      document
    end
  end

  def formatted_phone
    return phone unless phone.present?

    clean_phone = phone.gsub(/\D/, "")

    if clean_phone.length == 11
      clean_phone.gsub(/(\d{2})(\d{5})(\d{4})/, '(\1) \2-\3')
    elsif clean_phone.length == 10
      clean_phone.gsub(/(\d{2})(\d{4})(\d{4})/, '(\1) \2-\3')
    else
      phone
    end
  end

  def cpf?
    !!(document.present? && CPF.valid?(document))
  end

  def cnpj?
    !!(document.present? && CNPJ.valid?(document))
  end

  def document_type
    return "CPF" if cpf?
    return "CNPJ" if cnpj?
    "Indefinido"
  end

  def individual_customer?
    cpf?
  end

  def corporate_customer?
    cnpj?
  end

  private

  def normalize_attributes
    self.name = name.strip.titleize if name.present?
    self.email = email.strip.downcase if email.present?
    self.document = document.gsub(/\D/, '') if document.present?
    self.phone = phone.gsub(/\D/, '') if phone.present?
  end

  def document_must_be_valid
    return unless document.present?

    clean_document = document.gsub(/\D/, "")

    unless CPF.valid?(clean_document) || CNPJ.valid?(clean_document)
      errors.add(:document, "deve ser um CPF ou CNPJ válido")
    end
  end
end
