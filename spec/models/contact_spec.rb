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

require 'spec_helper'

describe Contact do
  it { should have_many(:contact_events) }
  it { should validate_presence_of(:first_name) }
  it { should validate_presence_of(:last_name) }

  describe "#full_name" do
    let(:contact) { FactoryGirl.build(:contact, :first_name => 'Juanito', :last_name => 'Perez') }

    it "should return the first_name and last_name concatenated" do
      contact.full_name.should == 'Juanito Perez'
    end

    it "should return only the first_name if it doesn't have last_name" do
      contact.last_name = nil
      contact.full_name.should == 'Juanito'
    end

    it "should return only the last_name if it doesn't have first_name" do
      contact.first_name = nil
      contact.full_name.should == 'Perez'
    end
  end

  describe "#country_name" do
    it "should return the correct country name" do
      contact = FactoryGirl.build(:contact, country: 'US')
      contact.country_name.should == 'United States'
    end

    it "should return nil if the contact doesn't have a country" do
      contact = FactoryGirl.build(:contact, country: nil)
      contact.country_name.should be_nil
    end

    it "should return nil if the contact has an invalid country" do
      contact = FactoryGirl.build(:contact, country: 'XYZ')
      contact.country_name.should be_nil
    end
  end

  describe "#street_address" do
    it "should return both address1+address2" do
      contact = FactoryGirl.build(:contact, street1: 'some street', street2: '2nd floor')
      contact.street_address.should == 'some street, 2nd floor'
    end

    it "should return only address1+address2" do
      contact = FactoryGirl.build(:contact, street1: 'some street', street2: '')
      contact.street_address.should == 'some street'
    end
  end
end
