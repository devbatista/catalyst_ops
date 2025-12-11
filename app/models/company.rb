class Company < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :order_services
  has_many :technicians, -> { where(role: :tecnico, active: true) }, class_name: "User"

  belongs_to :responsible, class_name: "User", optional: true
  belongs_to :plan, optional: true

  PAYMENT_METHODS = %w[pix credit_card boleto].freeze
  
  before_validation :normalize_document
  before_validation { self.email = email.to_s.downcase.strip if email.present? }
  
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validates :name, presence: true, length: { minimum: 3 }
  validates :document, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true, format: { with: /\A\d{10,15}\z/, message: "deve conter apenas números" }
  validates :state_registration, length: { maximum: 30 }, allow_blank: true
  validates :municipal_registration, length: { maximum: 30 }, allow_blank: true
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }

  validate :document_must_be_cpf_or_cnpj

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

  def gestores
    users.gestores
  end

  private

  def normalize_document
    self.document = document.to_s.gsub(/\D/, "") if document.present?
  end

  def document_must_be_cpf_or_cnpj
    unless CPF.valid?(document) || CNPJ.valid?(document)
      errors.add(:document, "deve ser um CPF ou CNPJ válido")
    end
  end
end
