# == Schema Information
#
# Table name: activity_results
#
#  id                   :integer          not null, primary key
#  activity_id          :integer
#  form_field_id        :integer
#  value                :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  form_field_option_id :integer
#  hash_value           :hstore
#  scalar_value         :decimal(10, 2)   default(0.0)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :activity_result do
    activity nil
    form_field nil
    value nil
  end
end
