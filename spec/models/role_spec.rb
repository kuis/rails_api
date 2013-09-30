# == Schema Information
#
# Table name: roles
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  permissions :text
#  company_id  :integer
#  active      :boolean          default(TRUE)
#  description :text
#

require 'spec_helper'

describe Role do
  it { should belong_to(:company) }

  it { should validate_presence_of(:name) }

  it { should allow_mass_assignment_of(:name) }
  it { should allow_mass_assignment_of(:description) }

  it { should_not allow_mass_assignment_of(:id) }
  it { should_not allow_mass_assignment_of(:is_admin) }
  it { should_not allow_mass_assignment_of(:active) }
  it { should_not allow_mass_assignment_of(:created_at) }
  it { should_not allow_mass_assignment_of(:updated_at) }

  it { should have_many(:company_users) }

  describe "#activate" do
    let(:role) { FactoryGirl.build(:role, active: false) }

    it "should return the active value as true" do
      role.activate!
      role.reload
      role.active.should be_true
    end
  end

  describe "#deactivate" do
    let(:role) { FactoryGirl.build(:role, active: false) }

    it "should return the active value as false" do
      role.deactivate!
      role.reload
      role.active.should be_false
    end
  end
end
