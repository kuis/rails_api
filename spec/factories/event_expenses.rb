# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event_expense do
    event nil
    sequence(:name) {|n| "Expense #{n}" }
    amount "9.99"
  end
end
