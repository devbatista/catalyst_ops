class Company < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :technicians, -> { where(role: :tecnico, active: true) }, class_name: "User"

  belongs_to :responsible, class_name: "User", optional: true

  before_validation :normalize_document
  before_validation { self.email = email.to_s.downcase.strip if email.present? }

  validates :name, presence: true, length: { minimum: 3 }
  validates :document, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true, format: { with: /\A\d{10,15}\z/, message: "deve conter apenas números" }
  validates :state_registration, length: { maximum: 30 }, allow_blank: true
  validates :municipal_registration, length: { maximum: 30 }, allow_blank: true
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }

  validate :document_must_be_cpf_or_cnpj

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
