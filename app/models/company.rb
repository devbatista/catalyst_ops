class Company < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :order_services
  has_many :technicians, -> { where(role: :tecnico, active: true) }, class_name: "User"
  has_many :subscriptions, dependent: :destroy
  has_one :current_subscription, -> { current }, class_name: "Subscription"

  belongs_to :responsible, class_name: "User", optional: true
  belongs_to :plan, optional: true

  PAYMENT_METHODS = %w[pix credit_card boleto].freeze
  
  before_validation :normalize_document
  before_validation { self.email = email.to_s.downcase.strip if email.present? }
  before_validation :normalize_zip_code
  
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validates :name, presence: true, length: { minimum: 3 }
  validates :document, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true, format: { with: /\A\d{10,15}\z/, message: "deve conter apenas números" }
  validates :state_registration, length: { maximum: 30 }, allow_blank: true
  validates :municipal_registration, length: { maximum: 30 }, allow_blank: true
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
  validates :number,  presence: true, length: { maximum: 20 }
  validates :complement, length: { maximum: 60 }, allow_blank: true
  validates :neighborhood, presence: true, length: { maximum: 80 }
  validates :city,     presence: true, length: { maximum: 80 }
  validates :state,    presence: true, length: { is: 2 }, format: { with: /\A[A-Z]{2}\z/, message: "use UF em maiúsculas, ex: SP" }
  validates :zip_code, presence: true, format: { with: /\A\d{8}\z/, message: "deve conter 8 números" }

  validate :document_must_be_cpf_or_cnpj

  scope :active, -> { where(active: true) }

  def formatted_document
    return document unless document.present?

    cpf_cnpj = normalize_document

    if cpf_cnpj.size == 11
      CPF.new(cpf_cnpj).formatted
    elsif cpf_cnpj.size
      CNPJ.new(cpf_cnpj).formatted
    else
      cpf_cnpj
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

  def formatted_zip_code
    return zip_code unless zip_code.present?
    zip_code.gsub(/(\d{5})(\d{3})/, '\1-\2')
  end

  def full_address
    [street, number, complement.presence, neighborhood, "#{city}/#{state}", formatted_zip_code].compact.join(', ')
  end

  def gestores
    users.gestores
  end

  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end

  def access_enabled?
    active? && adimplente?
  end

  def current_plan
    subscriptions.current.first&.plan  
  end

  def max_technicians
    current_plan&.max_technicians
  end
  
  def max_orders
    current_plan&.max_orders
  end

  def support_level
    current_plan&.support_level
  end

  def can_add_technician?
    return true unless max_technicians.present?
    
    users.tecnicos.active.count < max_technicians
  end

  def can_create_order?
    return true unless max_orders.present?
    order_services.where('created_at >= ?', Time.current.beginning_of_month).count < max_orders
  end

  private

  def normalize_document
    self.document = document.to_s.gsub(/\D/, "") if document.present?
  end

  def normalize_zip_code
    self.zip_code = zip_code.to_s.gsub(/\D/, "") if zip_code.present?
  end

  def document_must_be_cpf_or_cnpj
    unless CPF.valid?(document) || CNPJ.valid?(document)
      errors.add(:document, "deve ser um CPF ou CNPJ válido")
    end
  end

  def adimplente?
    !!current_subscription
  end
end
