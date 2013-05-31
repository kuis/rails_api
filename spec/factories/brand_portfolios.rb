# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :brand_portfolio do
    sequence(:name) {|n| "Test Brand Portfolio #{n}" }
    active false
    company_id 1
    created_by_id 1
    updated_by_id 1
  end
end
