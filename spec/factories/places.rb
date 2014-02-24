# == Schema Information
#
# Table name: places
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  reference              :string(400)
#  place_id               :string(100)
#  types                  :string(255)
#  formatted_address      :string(255)
#  latitude               :float
#  longitude              :float
#  street_number          :string(255)
#  route                  :string(255)
#  zipcode                :string(255)
#  city                   :string(255)
#  state                  :string(255)
#  country                :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  administrative_level_1 :string(255)
#  administrative_level_2 :string(255)
#  td_linx_code           :string(255)
#  neighborhood           :string(255)
#  location_id            :integer
#  is_location            :boolean
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :place do
    sequence(:name) {|n| "Place #{n}" }
    sequence(:place_id)
    sequence(:reference) {|n| "$aojnoiweksadk-o19290f0i2ief0-#{n}"}
    formatted_address "123 My Street"
    latitude 1.5
    longitude 1.5
    zipcode "12345"
    city "New York City"
    state "NY"
    country "US"
    do_not_connect_to_api true

    after(:build) {|u| u.types ||= ['establishment'] }
  end
end
