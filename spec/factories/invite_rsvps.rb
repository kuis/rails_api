# == Schema Information
#
# Table name: invite_rsvps
#
#  id                               :integer          not null, primary key
#  invite_id                        :integer
#  registrant_id                    :integer
#  date_added                       :date
#  email                            :string(255)
#  mobile_phone                     :string(255)
#  mobile_signup                    :boolean
#  first_name                       :string(255)
#  last_name                        :string(255)
#  attended_previous_bartender_ball :string(255)
#  opt_in_to_future_communication   :boolean
#  primary_registrant_id            :integer
#  bartender_how_long               :string(255)
#  bartender_role                   :string(255)
#  created_at                       :datetime
#  updated_at                       :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :invite_rsvp do
    invite nil
    registrant_id 1
    date_added "2015-01-06"
    email "MyString"
    mobile_phone "MyString"
    mobile_signup false
    first_name "MyString"
    last_name ""
    attended_previous_bartender_ball "MyString"
    opt_in_to_future_communication false
    primary_registrant_id 1
    bartender_how_long "MyString"
    bartender_role "MyString"
  end
end
