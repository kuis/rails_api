# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  first_name             :string(255)
#  last_name              :string(255)
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default("")
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  country                :string(4)
#  state                  :string(255)
#  city                   :string(255)
#  created_by_id          :integer
#  updated_by_id          :integer
#  last_activity_at       :datetime
#  invitation_token       :string(60)
#  invitation_sent_at     :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_id          :integer
#  invited_by_type        :string(255)
#

require 'spec_helper'

describe User do
  it { should have_many(:company_users) }

  it { should validate_presence_of(:first_name) }
  it { should validate_presence_of(:last_name) }
  it { should validate_presence_of(:email) }

  it { should allow_mass_assignment_of(:first_name) }
  it { should allow_mass_assignment_of(:last_name) }
  it { should allow_mass_assignment_of(:email) }

  it { should allow_value('guilleva@gmail.com').for(:email) }

  it { should allow_value("Avalidpassword1").for(:password) }
  it { should allow_value("validPassw0rd").for(:password) }
  it { should_not allow_value('Invalidpassword').for(:password).with_message(/should have at least one digit/) }
  it { should_not allow_value('invalidpassword1').for(:password).with_message(/should have at least one upper case letter/) }
  it { should validate_confirmation_of(:password) }

  describe "email uniqness" do
    before do
      @user = FactoryGirl.create(:user)
    end
    it { should validate_uniqueness_of(:email) }
  end

  describe "validations when inviting user" do
    context do
      before { subject.inviting_user = true }
      it { should_not validate_presence_of(:country) }
      it { should_not validate_presence_of(:state) }
      it { should_not validate_presence_of(:city) }
      it { should_not validate_presence_of(:password) }
    end
  end

  describe "validations when accepting an invitation" do
    context do
      before do
        subject.invitation_accepted_at = nil
        subject.accepting_invitation = true
      end
      it { should validate_presence_of(:country) }
      it { should validate_presence_of(:state) }
      it { should validate_presence_of(:city) }
      it { should validate_presence_of(:password) }
    end
  end

  describe "validations when editing a user" do
    context do
      before do
        subject.invitation_accepted_at = Time.now
      end
      it { should validate_presence_of(:country) }
      it { should validate_presence_of(:state) }
      it { should validate_presence_of(:city) }
      it { should_not validate_presence_of(:password) }
    end
  end

  describe "#full_name" do
    let(:user) { FactoryGirl.build(:user, :first_name => 'Juanito', :last_name => 'Perez') }

    it "should return the first_name and last_name concatenated" do
      user.full_name.should == 'Juanito Perez'
    end

    it "should return only the first_name if it doesn't have last_name" do
      user.last_name = nil
      user.full_name.should == 'Juanito'
    end

    it "should return only the last_name if it doesn't have first_name" do
      user.first_name = nil
      user.full_name.should == 'Perez'
    end
  end

  describe "#country_name" do
    it "should return the correct country name" do
      user = FactoryGirl.build(:user, country: 'US')
      user.country_name.should == 'United States'
    end

    it "should return nil if the user doesn't have a country" do
      user = FactoryGirl.build(:user, country: nil)
      user.country_name.should be_nil
    end

    it "should return nil if the user has an invalid country" do
      user = FactoryGirl.build(:user, country: 'XYZ')
      user.country_name.should be_nil
    end
  end

  describe "#state_name" do
    it "should return the correct state name" do
      user = FactoryGirl.build(:user, country: 'US', state: 'FL')
      user.state_name.should == 'Florida'
    end

    it "should return nil if the user doesn't have a state" do
      user = FactoryGirl.build(:user, country: 'US', state: nil)
      user.state_name.should be_nil
    end

    it "should return nil if the user has an invalid state" do
      user = FactoryGirl.build(:user, country: 'US', state: 'XYZ')
      user.state_name.should be_nil
    end
  end

  describe "#deactivate" do
    it "should deactivate the status of the user on the current company" do
      User.current = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
      company = User.current.reload.companies.first
      company = User.current.current_company = company
      user = FactoryGirl.create(:user, company_id: company.id, active: true)
      user.deactivate!
      user.company_users.first.reload.active.should be_false
    end

    it "should activate the status of the user on the current company" do
      User.current = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
      company = User.current.reload.companies.first
      company = User.current.current_company = company
      user = FactoryGirl.create(:user, company_id: company.id, active: false)
      user.activate!
      user.company_users.first.reload.active.should be_true
    end
  end

  describe "#with_text scope" do
    it "should return users that match the string on the first_name, last_name or email" do
      by_name = [
        FactoryGirl.create(:user, first_name: 'Albino', last_name: 'Fonseca'),
        FactoryGirl.create(:user, first_name: 'Alfonsina', last_name: 'Barrantes')
      ]
      by_email = [
        FactoryGirl.create(:user, first_name: 'Julio', last_name: 'Perez', email: 'maracana123@company.com')
      ]
      User.with_text('fon').all.should =~ by_name
      User.with_text('maracana').all.should =~ by_email
    end
  end

  describe "#by_teams scope" do
    it "should return users that belongs to the give teams" do
      users = [
        FactoryGirl.create(:user),
        FactoryGirl.create(:user)
      ]
      other_users = [
        FactoryGirl.create(:user)
      ]
      team = FactoryGirl.create(:team)
      other_team = FactoryGirl.create(:team)
      users.each{|u| team.users << u}
      other_users.each{|u| other_team.users << u}
      User.by_teams(team).all.should =~ users
      User.by_teams(other_team).all.should =~ other_users
      User.by_teams([team, other_team]).all.should =~ users + other_users
    end
  end

  describe "#by_events scope" do
    it "should return users that assigned to the specific events" do
      users = [
        FactoryGirl.create(:user),
        FactoryGirl.create(:user)
      ]
      other_users = [
        FactoryGirl.create(:user)
      ]
      event = FactoryGirl.create(:event)
      other_event = FactoryGirl.create(:event)
      users.each{|u| event.users << u}
      other_users.each{|u| other_event.users << u}
      User.by_events(event).all.should =~ users
      User.by_events(other_event).all.should =~ other_users
      User.by_events([event, other_event]).all.should =~ users + other_users
    end
  end
end
