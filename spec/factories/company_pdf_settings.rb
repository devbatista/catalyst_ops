FactoryBot.define do
  factory :company_pdf_setting do
    association :company
    document_type { "order_service" }
    accent_color { "1F6FEB" }

    trait :budget do
      document_type { "budget" }
    end
  end
end
