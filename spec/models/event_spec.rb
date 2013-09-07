# == Schema Information
#
# Table name: events
#
#  id            :integer          not null, primary key
#  campaign_id   :integer
#  company_id    :integer
#  start_at      :datetime
#  end_at        :datetime
#  aasm_state    :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  active        :boolean          default(TRUE)
#  place_id      :integer
#  promo_hours   :decimal(6, 2)    default(0.0)
#  reject_reason :text
#  summary       :text
#

require 'spec_helper'

describe Event do
  it { should belong_to(:company) }
  it { should belong_to(:campaign) }
  it { should have_many(:memberships) }
  it { should have_many(:users).through(:memberships) }
  it { should have_many(:tasks) }

  it { should allow_mass_assignment_of(:end_date) }
  it { should allow_mass_assignment_of(:end_time) }
  it { should allow_mass_assignment_of(:start_date) }
  it { should allow_mass_assignment_of(:start_time) }
  it { should allow_mass_assignment_of(:campaign_id) }
  it { should allow_mass_assignment_of(:event_ids) }
  it { should allow_mass_assignment_of(:user_ids) }

  it { should_not allow_mass_assignment_of(:id) }
  it { should_not allow_mass_assignment_of(:aasm_state) }
  it { should_not allow_mass_assignment_of(:active) }
  it { should_not allow_mass_assignment_of(:created_by_id) }
  it { should_not allow_mass_assignment_of(:updated_by_id) }
  it { should_not allow_mass_assignment_of(:created_at) }
  it { should_not allow_mass_assignment_of(:updated_at) }

  it { should validate_presence_of(:campaign_id) }
  it { should validate_numericality_of(:campaign_id) }
  it { should validate_presence_of(:start_at) }
  it { should validate_presence_of(:end_at) }

  describe "end_after_start validation" do
    subject { Event.new({start_at: Time.zone.local(2016,1,20,12,5,0)}, without_protection: true) }

    it { should_not allow_value(Time.zone.local(2016,1,20,12,0,0)).for(:end_at).with_message("must be on or after 2016-01-20 12:05:00") }
    it { should allow_value(Time.zone.local(2016,1,20,12,5,0)).for(:end_at) }
    it { should allow_value(Time.zone.local(2016,1,20,12,10,0)).for(:end_at) }
  end

  describe "#start_at attribute" do
    it "should be correctly set when assigning valid start_date and start_time" do
      event = Event.new
      event.start_date = '01/20/2012'
      event.start_time = '12:05pm'
      event.valid?
      event.start_at.should == Time.zone.local(2012,1,20,12,5,0)
    end

    it "should be nil if no start_date and start_time are provided" do
      event = Event.new
      event.valid?
      event.start_at.should be_nil
    end

    it "should have only the date if no start_time provided" do
      event = Event.new
      event.start_date = '01/20/2012'
      event.start_time = nil
      event.valid?
      event.start_at.should == Time.zone.local(2012,1,20,0,0,0)
    end
  end

  describe "#end_at attribute" do
    it "should be correcly set when assigning valid end_date and end_time" do
      event = Event.new
      event.end_date = '01/20/2012'
      event.end_time = '12:05pm'
      event.valid?
      event.end_at.should == Time.zone.local(2012,1,20,12,5,0)
    end

    it "should be nil if no end_date and end_time are provided" do
      event = Event.new
      event.valid?
      event.end_at.should be_nil
    end

    it "should have only the date if no end_time provided" do
      event = Event.new
      event.end_date = '01/20/2012'
      event.end_time = nil
      event.valid?
      event.end_at.should == Time.zone.local(2012,1,20,0,0,0)
    end

  end

  describe "campaign association" do
    let(:campaign) { FactoryGirl.create(:campaign) }

    it "should update campaign's first_event_id and first_event_at attributes" do
      campaign.update_attributes({first_event_id: 999, first_event_at: '2013-02-01 12:00:00'}, without_protection: true).should be_true
      event = FactoryGirl.create(:event, campaign: campaign, start_date: '01/01/2013', start_time: '01:00 AM', end_date:  '01/01/2013', end_time: '05:00 AM')
      campaign.reload
      campaign.first_event_id.should == event.id
      campaign.first_event_at.should == Time.zone.parse('2013-01-01 01:00:00')
    end

    it "should update campaign's first_event_id and first_event_at attributes" do
      campaign.update_attributes({last_event_id: 999, last_event_at: '2013-01-01 12:00:00'}, without_protection: true).should be_true
      event = FactoryGirl.create(:event, campaign: campaign, start_date: '02/01/2013', start_time: '01:00 AM', end_date:  '02/01/2013', end_time: '05:00 AM')
      campaign.reload
      campaign.last_event_id.should == event.id
      campaign.last_event_at.should == Time.zone.parse('2013-02-01 05:00:00')
    end
  end

end
