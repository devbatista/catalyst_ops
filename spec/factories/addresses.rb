FactoryBot.define do
  factory :address do
    street { "MyString" }
    number { "MyString" }
    complement { "MyString" }
    neighborhood { "MyString" }
    zip_code { "MyString" }
    city { "MyString" }
    state { "MyString" }
    country { "MyString" }
    address_type { "MyString" }
    client { nil }
  end
end
