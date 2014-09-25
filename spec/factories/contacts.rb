# == Schema Information
#
# Table name: contacts
#
#  id           :integer          not null, primary key
#  company_id   :integer
#  first_name   :string(255)
#  last_name    :string(255)
#  title        :string(255)
#  email        :string(255)
#  phone_number :string(255)
#  street1      :string(255)
#  street2      :string(255)
#  country      :string(255)
#  state        :string(255)
#  city         :string(255)
#  zip_code     :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :contact do
    company_id 1
    first_name 'Julian'
    last_name 'Guerra'
    title 'Bar Owner'
    email 'somecontact@email.com'
    phone_number '344-23333'
    street1 '12th St.'
    street2 ''
    country 'US'
    state 'CA'
    city 'Hollywood'
    zip_code '43212'
  end
end
