# == Schema Information
#
# Table name: events
#
#  id             :integer          not null, primary key
#  campaign_id    :integer
#  company_id     :integer
#  start_at       :datetime
#  end_at         :datetime
#  aasm_state     :string(255)
#  created_by_id  :integer
#  updated_by_id  :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  active         :boolean          default(TRUE)
#  place_id       :integer
#  promo_hours    :decimal(6, 2)    default(0.0)
#  reject_reason  :text
#  summary        :text
#  timezone       :string(255)
#  local_start_at :datetime
#  local_end_at   :datetime
#

require 'spec_helper'

describe Event do
  it { should belong_to(:company) }
  it { should belong_to(:campaign) }
  it { should have_many(:memberships) }
  it { should have_many(:users).through(:memberships) }
  it { should have_many(:tasks) }


  it { should validate_presence_of(:campaign_id) }
  it { should validate_numericality_of(:campaign_id) }
  it { should validate_presence_of(:start_at) }
  it { should validate_presence_of(:end_at) }

  it { should allow_value("12/31/2012").for(:start_date) }
  it { should_not allow_value("12/31/12").for(:start_date).with_message('MM/DD/YYYY') }

  describe "end date validations" do
    before { subject.start_date = '12/31/2012' }
    it { should allow_value("12/31/2012").for(:end_date) }
    it { should_not allow_value("12/31/12").for(:end_date).with_message('MM/DD/YYYY') }
  end

  describe "event results validations" do
    it "should not allow submitting the event if the resuls are not valid" do
      campaign = FactoryGirl.create(:campaign)
      field = FactoryGirl.create(:campaign_form_field, campaign: campaign, kpi: FactoryGirl.create(:kpi, company_id: 1), field_type: 'number', options: {required: true})
      event = FactoryGirl.create(:event, campaign: campaign)

      expect {
        event.submit
      }.to raise_exception(AASM::InvalidTransition)

      event.results_for([field]).each {|r| r.value = 100}
      event.save
      event.submit.should be_true
    end
  end

  describe "end_after_start validation" do
    subject { Event.new({start_at: Time.zone.local(2016,1,20,12,5,0)}, without_protection: true) }

    it { should_not allow_value(Time.zone.local(2016,1,20,12,0,0)).for(:end_at).with_message("must be after") }
    it { should allow_value(Time.zone.local(2016,1,20,12,5,0)).for(:end_at) }
    it { should allow_value(Time.zone.local(2016,1,20,12,10,0)).for(:end_at) }
  end

  describe "states" do
    before(:each) do
      @event = FactoryGirl.create(:event)
    end

    describe ":unsent" do
      it 'should be an initial state' do
        @event.should be_unsent
      end

      it 'should change to :submitted on :unsent or :rejected' do
        @event.submit
        @event.should be_submitted
      end

      it 'should change to :approved on :submitted' do
        @event.submit
        @event.approve
        @event.should be_approved
      end

      it 'should change to :rejected on :submitted' do
        @event.submit
        @event.reject
        @event.should be_rejected
      end
    end
  end

  describe "#accessible_by" do
    before do
      @event = FactoryGirl.create(:event, campaign: campaign, place: place)
    end

    let(:company) {FactoryGirl.create(:company)}
    let(:campaign) {FactoryGirl.create(:campaign, company: company)}
    let(:place) {FactoryGirl.create(:place, country: 'US', state:'California', city: 'Los Angeles')}
    let(:area) {FactoryGirl.create(:area, company: company)}
    let(:company_user) {FactoryGirl.create(:company_user, company: company, role: FactoryGirl.create(:role, is_admin: false, company: company))}

    it "should return empty if the user doesn't have campaigns nor places" do
      expect(Event.accessible_by_user(company_user)).to be_empty
    end

    it "should return empty if the user have access to the campaing but not the place" do
       company_user.campaigns << campaign
      expect(Event.accessible_by_user(company_user)).to be_empty
    end

    it "should return the event if the user have the place directly assigned to the user" do
      company_user.campaigns << campaign
      company_user.places << place
      expect(Event.accessible_by_user(company_user)).to match_array([@event])
    end

    it "should return the event if the user have access to an area that includes the place" do
      company_user.campaigns << campaign
      area.places << place
      company_user.areas << area
      expect(Event.accessible_by_user(company_user)).to match_array([@event])
    end

    it "should return the event if the user has access to the city" do
      company_user.campaigns << campaign
      company_user.places << FactoryGirl.create(:place, country: 'US', state:'California', city: 'Los Angeles', types: ['locality'])
      expect(Event.accessible_by_user(company_user)).to match_array([@event])
    end
  end

  describe "with_user_in_team" do
    let(:campaign) { FactoryGirl.create(:campaign) }
    let(:user) { FactoryGirl.create(:company_user, company: campaign.company) }
    it "should return empty if the user is not assiged to any event" do
      expect(Event.with_user_in_team(user)).to be_empty
    end

    it "should return all the events where a user is assigned as part of the event team" do
      events = FactoryGirl.create_list(:event, 3, campaign: campaign)
      events.each{|e| e.users << user }
      FactoryGirl.create(:event, campaign: campaign)

      expect(Event.with_user_in_team(user)).to match_array(events)
    end

    it "should return all the events where a user is part of a team that is assigned to the event" do
      events = FactoryGirl.create_list(:event, 3, campaign: campaign)
      team = FactoryGirl.create(:team, company: campaign.company)
      team.users << user
      events.each{|e| e.teams << team }
      FactoryGirl.create(:event, campaign: campaign)

      expect(Event.with_user_in_team(user)).to match_array(events)
    end
  end

  describe "#in_areas" do
    let(:company) {FactoryGirl.create(:company)}
    let(:campaign) {FactoryGirl.create(:campaign, company: company)}

    it "should include only events within the given areas" do
      event_la = FactoryGirl.create(:event, campaign: campaign,
        place: FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles'))

      event_sf = FactoryGirl.create(:event, campaign: campaign,
        place: FactoryGirl.create(:place, country: 'US', state: 'California', city: 'San Francisco'))

      area_la = FactoryGirl.create(:area, company: company)
      area_sf = FactoryGirl.create(:area, company: company)

      area_la.places << FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles', types: ['locality'])
      area_sf.places << FactoryGirl.create(:place, country: 'US', state: 'California', city: 'San Francisco', types: ['locality'])

      expect(Event.in_areas([area_la])).to match_array [event_la]
      expect(Event.in_areas([area_sf])).to match_array [event_sf]
      expect(Event.in_areas([area_la, area_sf])).to match_array [event_la, event_sf]
    end

    it "should include events that are scheduled on places that are part of the areas" do
      place_la = FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles')
      event_la = FactoryGirl.create(:event, campaign: campaign, place: place_la)

      place_sf = FactoryGirl.create(:place, country: 'US', state: 'California', city: 'San Francisco')
      event_sf = FactoryGirl.create(:event, campaign: campaign, place: place_sf)

      area_la = FactoryGirl.create(:area, company: company)
      area_sf = FactoryGirl.create(:area, company: company)

      area_la.places << place_la
      area_sf.places << place_sf

      expect(Event.in_areas([area_la])).to match_array [event_la]
      expect(Event.in_areas([area_sf])).to match_array [event_sf]
      expect(Event.in_areas([area_la, area_sf])).to match_array [event_la, event_sf]
    end
  end

  describe "#in_places" do
    let(:company) {FactoryGirl.create(:company)}
    let(:campaign) {FactoryGirl.create(:campaign, company: company)}

    it "should include events that are scheduled on the given places" do
      place_la = FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles')
      event_la = FactoryGirl.create(:event, campaign: campaign, place: place_la)

      place_sf = FactoryGirl.create(:place, country: 'US', state: 'California', city: 'San Francisco')
      event_sf = FactoryGirl.create(:event, campaign: campaign, place: place_sf)

      expect(Event.in_places([place_la])).to match_array [event_la]
      expect(Event.in_places([place_sf])).to match_array [event_sf]
      expect(Event.in_places([place_la, place_sf])).to match_array [event_la, event_sf]
    end


    it "should include events that are scheduled within the given scope if the place is a locality" do
      los_angeles = FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles', types: ['locality'])
      event_la = FactoryGirl.create(:event, campaign: campaign,
        place: FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles'))

      san_francisco = FactoryGirl.create(:place, country: 'US', state: 'California', city: 'San Francisco', types: ['locality'])
      event_sf = FactoryGirl.create(:event, campaign: campaign,
        place: FactoryGirl.create(:place, country: 'US', state: 'California', city: 'San Francisco'))

      expect(Event.in_places([los_angeles])).to match_array [event_la]
      expect(Event.in_places([san_francisco])).to match_array [event_sf]
      expect(Event.in_places([los_angeles, san_francisco])).to match_array [event_la, event_sf]
    end
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
      event = FactoryGirl.create(:event, campaign: campaign, company: campaign.company, start_date: '01/01/2013', start_time: '01:00 AM', end_date:  '01/01/2013', end_time: '05:00 AM')
      campaign.reload
      campaign.first_event_id.should == event.id
      campaign.first_event_at.should == Time.zone.parse('2013-01-01 01:00:00')
    end

    it "should update campaign's first_event_id and first_event_at attributes" do
      campaign.update_attributes({last_event_id: 999, last_event_at: '2013-01-01 12:00:00'}, without_protection: true).should be_true
      event = FactoryGirl.create(:event, campaign: campaign, company: campaign.company, start_date: '02/01/2013', start_time: '01:00 AM', end_date:  '02/01/2013', end_time: '05:00 AM')
      campaign.reload
      campaign.last_event_id.should == event.id
      campaign.last_event_at.should == Time.zone.parse('2013-02-01 01:00:00')
    end
  end

  describe "#kpi_goals" do
    let(:campaign) { FactoryGirl.create(:campaign) }
    let(:event) { FactoryGirl.create(:event, campaign: campaign, company: campaign.company) }

    it "should not fail if there are not goals nor KPIs for the campaign" do
      event.kpi_goals.should == {}
    end

    it "should not fail if there are KPIs associated to the campaign but without goals" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      event.kpi_goals.should == {}
    end

    it "should not fail if the goal values are nil" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      goals = campaign.goals.for_kpis([Kpi.impressions])
      goals.each{|g| g.value = nil; g.save}
      event.kpi_goals.should == {}
    end

    it "returns the correct value for the goal" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      goals = campaign.goals.for_kpis([Kpi.impressions])
      goals.each{|g| g.value = 100; g.save}
      event.kpi_goals.should == {Kpi.impressions.id => 100}
    end

    it "returns the correctly divide the goal between the number of events" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      #Create another event for the campaign
      FactoryGirl.create(:event, campaign: campaign, company: campaign.company)
      goals = campaign.goals.for_kpis([Kpi.impressions])
      goals.each{|g| g.value = 100; g.save}
      event.kpi_goals.should == {Kpi.impressions.id => 50}
    end

  end

  describe "before_save #set_promo_hours" do
    it "correctly calculates the number of promo hours before saving the event" do
      event = FactoryGirl.build(:event,  start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/21/2020', end_time: '05:00pm')
      event.promo_hours = nil
      event.save.should be_true
      event.reload.promo_hours.should == 5
    end
    it "accepts promo_hours hours with decimals" do
      event = FactoryGirl.build(:event,  start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/21/2020', end_time: '03:15pm')
      event.promo_hours = nil
      event.save.should be_true
      event.reload.promo_hours.should == 3.25
    end
  end


  describe "in_past?" do
    after do
      Timecop.return
    end
    it "should return true if the event is scheduled to happen in the past" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        event = FactoryGirl.build(:event)
        event.end_at = Time.zone.local(2013, 07, 26, 12, 00)
        event.in_past?.should be_true

        event.end_at = Time.zone.local(2013, 07, 26, 12, 12)
        event.in_past?.should be_true

        event.end_at = Time.zone.local(2013, 07, 26, 12, 15)
        event.in_past?.should be_false
      end
    end

    it "should return true if the event is scheduled to happen in the future" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        event = FactoryGirl.build(:event)
        event.start_at = Time.zone.local(2013, 07, 26, 12, 00)
        event.in_future?.should be_false

        event.start_at = Time.zone.local(2013, 07, 26, 12, 12)
        event.in_future?.should be_false

        event.start_at = Time.zone.local(2013, 07, 26, 12, 15)
        event.in_future?.should be_true

        event.start_at = Time.zone.local(2014, 07, 26, 12, 15)
        event.in_future?.should be_true
      end
    end
  end


  describe "is_late?" do
    after do
      Timecop.return
    end
    it "should return true if the event is scheduled to happen in more than to days go" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        event = FactoryGirl.create(:event, start_date: '07/23/2013', end_date: '07/23/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.is_late?.should be_true

        event = FactoryGirl.create(:event, start_date: '01/23/2013', end_date: '01/23/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.is_late?.should be_true
      end
    end
    it "should return false if the event is end_date is less than two days ago" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        event = FactoryGirl.create(:event, start_date: '07/23/2013', end_date: '07/25/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.is_late?.should be_false
      end
    end
  end

  describe "happens_today?" do
    after do
      Timecop.return
    end
    it "should return true if the current day is between the start and end dates of the event" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        event = FactoryGirl.create(:event, start_date: '07/26/2013', end_date: '07/26/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.happens_today?.should be_true

        event = FactoryGirl.create(:event, start_date: '07/26/2013', end_date: '07/28/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.happens_today?.should be_true

        event = FactoryGirl.create(:event, start_date: '07/24/2013', end_date: '07/26/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.happens_today?.should be_true

        event = FactoryGirl.create(:event, start_date: '07/23/2013', end_date: '07/28/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.happens_today?.should be_true
      end
    end

    it "should return true if the current day is NOT between the start and end dates of the event" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        event = FactoryGirl.create(:event, start_date: '07/27/2013', end_date: '07/28/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.happens_today?.should be_false

        event = FactoryGirl.create(:event, start_date: '07/24/2013', end_date: '07/25/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.happens_today?.should be_false
      end
    end
  end

  describe "was_yesterday?" do
    after do
      Timecop.return
    end
    it "should return true if the end_date is the day before" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        event = FactoryGirl.create(:event, start_date: '07/24/2013', end_date: '07/25/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.was_yesterday?.should be_true

        event = FactoryGirl.create(:event, start_date: '07/21/2013', end_date: '07/25/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.was_yesterday?.should be_true

      end
    end

    it "should return false if the event's end_date is other than yesterday" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
        event = FactoryGirl.create(:event, start_date: '07/26/2013', end_date: '07/26/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.was_yesterday?.should be_false

        event = FactoryGirl.create(:event, start_date: '07/25/2013', end_date: '07/26/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.was_yesterday?.should be_false


        event = FactoryGirl.create(:event, start_date: '07/24/2013', end_date: '07/24/2013', start_time: '10:00 am', end_time: '2:00 pm')
        event.was_yesterday?.should be_false
      end
    end
  end

  describe "venue reindexing", strategy: :deletion do
    before do
      ResqueSpec.reset!
    end
    let(:campaign) { FactoryGirl.create(:campaign) }
    let(:event)    { FactoryGirl.create(:event, campaign: campaign, company: campaign.company) }

    it "should queue a job to update venue details after a event have been updated if the event data have changed" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      event.place_id = 1
      event.save # Make sure the event have a place_id
      ResqueSpec.reset!
      expect {
        field = campaign.form_fields.detect{|f| f.kpi_id == Kpi.impressions.id}
        event.update_attributes({results_attributes: {"1" => {form_field_id: field.id, kpi_id: field.kpi_id, value: '100' }}})
      }.to change(EventResult, :count).by(1)
      VenueIndexer.should have_queued(event.venue.id)
    end

    it "should queue a job to update venue details after a event have been updated if place_id changed" do
      expect {
        event.place_id =  1199
        event.save
      }.to change(Venue, :count).by(1)
      VenueIndexer.should have_queued(event.venue.id)
    end

  end


  describe "photos reindexing" do
    before do
      ResqueSpec.reset!
    end
    let(:event) { FactoryGirl.create(:event) }


    it "should queue a job to reindex photos after a event have been updated if place_id changed" do
      event.place_id = 1
      event.save
      ResqueSpec.reset!

      # Changing the place should reindex all photos for the event
      event.place_id =  1199
      event.save.should be_true
      EventPhotosIndexer.should have_queued(event.id)
    end

    it "should not queue a job to reindex if the place_id not changed" do
      event.place_id = 1
      event.save
      ResqueSpec.reset!

      # Changing the place should reindex all photos for the event
      event.start_at = event.start_at - 1.hour
      event.save.should be_true
      EventPhotosIndexer.should_not have_queued(event.id)
    end
  end

  describe "#place_reference=" do
    it "should not fail if nill" do
      event = FactoryGirl.build(:event, place: nil)
      event.place_reference = nil
      event.place.should be_nil
    end

    it "should initialized a new place object" do
      event = FactoryGirl.build(:event, place: nil)
      Place.any_instance.should_receive(:fetch_place_data)
      event.place_reference = 'some_reference||some_id'
      event.place.should_not be_nil
      event.place.new_record?.should be_true
      event.place.place_id.should == 'some_id'
      event.place.reference.should == 'some_reference'
    end


    it "should initialized the place object" do
      place = FactoryGirl.create(:place)
      event = FactoryGirl.build(:event, place: nil)
      event.place_reference = "#{place.reference}||#{place.place_id}"
      event.place.should_not be_nil
      event.place.new_record?.should be_false
      event.place.should == place
    end
  end

  describe "#place_reference" do
    it "should return the place id if the place is already stored on the DB" do
      place = FactoryGirl.create(:place)
      event = FactoryGirl.build(:event, place: place)

      event.place_reference.should == place.id
    end

    it "should return the combination of reference and place_id if it's not stored place" do
      place = FactoryGirl.build(:place, reference: ':the_reference', place_id: ':the_place_id')
      event = FactoryGirl.build(:event, place: place)

      event.place_reference.should == ':the_reference||:the_place_id'
    end

    it "should return nil if the event has no place associated" do
      event = FactoryGirl.build(:event, place: nil)

      event.place_reference.should be_nil
    end
  end


  describe "#demographics_graph_data" do
    let(:event) { FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign)) }
    it "should return the correct results" do
      Kpi.create_global_kpis
      event.campaign.assign_all_global_kpis
      set_event_results(event,
        gender_male: 35,
        gender_female: 65,
        ethnicity_asian: 15,
        ethnicity_native_american: 23,
        ethnicity_black: 24,
        ethnicity_hispanic: 26,
        ethnicity_white: 12,
        age_12: 1,
        age_12_17: 2,
        age_18_24: 4,
        age_25_34: 8,
        age_35_44: 16,
        age_45_54: 32,
        age_55_64: 24,
        age_65: 13
      )

      event.demographics_graph_data[:gender].should    == {'Female' => 65, 'Male' => 35}
      event.demographics_graph_data[:age].should       == {"< 12"=>1, "12 – 17"=>2, "18 – 24"=>4, "25 – 34"=>8, "35 – 44"=>16, "45 – 54"=>32, "55 – 64"=>24, "65+"=>13}
      event.demographics_graph_data[:ethnicity].should == {"Asian"=>15.0, "Black / African American"=>24.0, "Hispanic / Latino"=>26.0, "Native American"=>23.0, "White"=>12.0}
    end
  end


  describe "survey_statistics" do
    pending "Add tests for this method"
  end

  describe "after_remove_member" do
    let(:event) {FactoryGirl.create(:event)}
    it "should be called after removign a user from the event" do
      user = FactoryGirl.create(:company_user, company_id: event.company_id)
      event.users << user
      event.should_receive(:after_remove_member).with(user)
      event.users.delete(user)
    end

    it "should be called after removign a team from the event" do
      team = FactoryGirl.create(:team, company_id: event.company_id)
      event.teams << team
      event.should_receive(:after_remove_member).with(team)
      event.teams.delete(team)
    end

    it "should reindex all the tasks of the event" do
      user = FactoryGirl.create(:company_user, company_id: event.company_id)
      other_user = FactoryGirl.create(:company_user, company_id: event.company_id)
      event.users << user
      event.users << other_user

      tasks = FactoryGirl.create_list(:task, 3, event: event)
      tasks[1].update_attribute(:company_user_id, other_user.id)
      tasks[2].update_attribute(:company_user_id, user.id)

      tasks[2].reload.company_user_id.should == user.id

      Sunspot.should_receive(:index) do |taks_list|
        taks_list.should be_an_instance_of(Array)
        taks_list.should =~ tasks
      end

      event.users.delete(user)

      tasks[1].reload.company_user_id.should == other_user.id  # This shouldn't be unassigned
      tasks[2].reload.company_user_id.should be_nil
    end

    it "should unassign all the tasks assigned to any user of the team" do
      team_user1 = FactoryGirl.create(:company_user, company_id: event.company_id)
      team_user2 = FactoryGirl.create(:company_user, company_id: event.company_id)
      other_user = FactoryGirl.create(:company_user, company_id: event.company_id)
      team = FactoryGirl.create(:team, company_id: event.company_id)
      team.users << [team_user1, team_user2]
      event.teams << team
      event.users << team_user2

      tasks = FactoryGirl.create_list(:task, 3, event: event)
      tasks[0].update_attribute(:company_user_id, other_user.id)
      tasks[1].update_attribute(:company_user_id, team_user1.id)
      tasks[2].update_attribute(:company_user_id, team_user2.id)

      tasks[1].reload.company_user_id.should == team_user1.id
      tasks[2].reload.company_user_id.should == team_user2.id

      Sunspot.should_receive(:index) do |taks_list|
        taks_list.should be_an_instance_of(Array)
        taks_list.should =~ tasks
      end

      event.teams.delete(team)

      tasks[0].reload.company_user_id.should == other_user.id  # This shouldn't be unassigned
      tasks[1].reload.company_user_id.should be_nil
      tasks[2].reload.company_user_id.should == team_user2.id  # This shouldn't be unassigned either as the user is directly assigned to the event
    end
  end

  describe "reindex_associated" do
    it "should update the campaign first and last event dates " do
      campaign = FactoryGirl.create(:campaign, first_event_id: nil, last_event_at: nil, first_event_at: nil, last_event_at: nil)
      event = FactoryGirl.build(:event, campaign: campaign, start_date: '01/23/2019', end_date: '01/25/2019')
      campaign.should_receive(:first_event=).with(event)
      campaign.should_receive(:last_event=).with(event)
      event.save
    end


    it "should update only the first event" do
      campaign = FactoryGirl.create(:campaign, first_event_at: Time.zone.local(2013, 07, 26, 12, 13), last_event_at: Time.zone.local(2013, 07, 29, 14, 13))
      event = FactoryGirl.build(:event, campaign: campaign, start_date: '07/24/2013', end_date: '07/24/2013')
      campaign.should_receive(:first_event=).with(event)
      campaign.should_not_receive(:last_event=)
      event.save
    end

    it "should update only the last event" do
      campaign = FactoryGirl.create(:campaign, first_event_at: Time.zone.local(2013, 07, 26, 12, 13), last_event_at: Time.zone.local(2013, 07, 29, 14, 13))
      event = FactoryGirl.build(:event, campaign: campaign, start_date: '07/30/2013', end_date: '07/30/2013')
      campaign.should_not_receive(:first_event=)
      campaign.should_receive(:last_event=).with(event)
      event.save
    end

    it "should create a new event data for the event" do
      Kpi.create_global_kpis
      campaign = FactoryGirl.create(:campaign)
      campaign.assign_all_global_kpis
      event = FactoryGirl.create(:event, campaign: campaign)
      expect{
        set_event_results(event,
          impressions: 100,
          interactions: 101,
          samples: 102
        )
      }.to change(EventData, :count).by(1)
      data = EventData.last
      data.impressions.should == 100
      data.interactions.should == 101
      data.samples.should == 102
    end

    it "should reindex all the tasks of the event when a event is deactivated" do
      campaign = FactoryGirl.create(:campaign)
      event = FactoryGirl.create(:event, campaign: campaign)
      user = FactoryGirl.create(:company_user, company: campaign.company)
      other_user = FactoryGirl.create(:company_user, company: campaign.company)
      event.users << user
      event.users << other_user

      tasks = [FactoryGirl.create(:task, event: event)]

      Sunspot.should_receive(:index).with(event)
      Sunspot.should_receive(:index).with(tasks)
      event.deactivate!
    end
  end

  describe "#activate" do
    let(:event) { FactoryGirl.create(:event, active: false) }

    it "should return the active value as true" do
      event.activate!
      event.reload
      event.active.should be_true
    end
  end

  describe "#deactivate" do
    let(:event) { FactoryGirl.create(:event, active: false) }

    it "should return the active value as false" do
      event.deactivate!
      event.reload
      event.active.should be_false
    end
  end


  describe "#result_for_kpi" do
    let(:campaign) { FactoryGirl.create(:campaign) }
    let(:event) { FactoryGirl.create(:event, campaign: campaign) }
    it "should return a new instance of EventResult if the event has not results for the given kpi" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      result = event.result_for_kpi(Kpi.impressions)
      result.should be_an_instance_of(EventResult)
      result.new_record?.should be_true

      # Make sure the result is correctly initialized
      result.kpi_id == Kpi.impressions.id
      result.form_field_id.should_not be_nil
      result.value.should be_nil
      result.scalar_value.should == 0
    end
  end


  describe "#results_for_kpis" do
    let(:campaign) { FactoryGirl.create(:campaign) }
    let(:event) { FactoryGirl.create(:event, campaign: campaign) }
    it "should return a new instance of EventResult if the event has not results for the given kpi" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      results = event.results_for_kpis([Kpi.impressions, Kpi.interactions])
      results.count.should == 2
      results.each do |result|
        result.should be_an_instance_of(EventResult)
        result.new_record?.should be_true

        # Make sure the result is correctly initialized
        [Kpi.impressions.id, Kpi.interactions.id].should include(result.kpi_id)
        result.form_field_id.should_not be_nil
        result.value.should be_nil
        result.scalar_value.should == 0
      end
    end
  end


  describe "#results_for" do
    let(:campaign) { FactoryGirl.create(:campaign) }
    let(:event) { FactoryGirl.create(:event, campaign: campaign) }

    it "should return empty array if no fields given" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      results = event.results_for([])

      results.should == []
    end

    it "should return empty array if no fields given" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      results = event.results_for([])

      results.should == []
    end


    it "should only return the results for the given fields" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      impressions  = campaign.form_fields.detect{|f| f.kpi_id == Kpi.impressions.id}
      interactions = campaign.form_fields.detect{|f| f.kpi_id == Kpi.interactions.id}
      results = event.results_for([impressions, interactions])

      # Only two results returned
      results.count.should == 2

      # They both should be new records
      results.all?{|r| r.new_record? }.should be_true

      results.map{|r| r.kpi_id }.should =~ [Kpi.impressions.id, Kpi.interactions.id]
    end


    it "should not include segmented fields " do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      results = event.results_for(campaign.form_fields)

      results.any?{|r| r.kpis_segment_id.present? }.should be_false
    end
  end

  describe "#segments_results_for" do
    let(:campaign) { FactoryGirl.create(:campaign) }
    let(:event) { FactoryGirl.create(:event, campaign: campaign) }

    it "should return empty array if the fields is not segmented" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      impressions  = campaign.form_fields.detect{|f| f.kpi_id == Kpi.impressions.id}
      results = event.segments_results_for(impressions)

      results.should == []
    end

    it "the values for the all segments" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      gender  = campaign.form_fields.detect{|f| f.kpi_id == Kpi.gender.id}
      results = event.segments_results_for(gender)

      results.all?{|r| r.new_record? }.should be_true

      results.count.should == 2
    end
  end

  describe "#event_place_valid?" do
    after do
      User.current = nil
    end
    let(:place_LA) { FactoryGirl.create(:place, name: 'Los Angeles', city: 'Los Angeles', state: 'California', country: 'US', types: ['locality']) }
    let(:place_SF) { FactoryGirl.create(:place, name: 'San Francisco', city: 'San Francisco', state: 'California', country: 'US', types: ['locality']) }
    it "should only allow create events that are valid for the campaign" do
      campaign = FactoryGirl.create(:campaign)
      campaign.places << place_LA

      event = FactoryGirl.build(:event, campaign: campaign, company: campaign.company, place: place_SF)
      event.valid?.should be_false
      event.errors[:place_reference].should include('is not valid for this campaign')

      event.place = place_LA
      event.valid?.should be_true
    end

    it "should not validate place if the event's place haven't changed" do
      campaign = FactoryGirl.create(:campaign)

      event = FactoryGirl.create(:event, campaign: campaign, company: campaign.company, place: place_SF)
      event.save.should be_true

      campaign.places << place_LA

      event.reload.valid?.should be_true
    end

    it "should allow the event to have a blank place if the user is admin" do
      company = FactoryGirl.create(:company)
      user = FactoryGirl.create(:company_user, company: company, role: FactoryGirl.create(:role, is_admin: true)).user
      user.current_company = company
      User.current = user

      campaign = FactoryGirl.create(:campaign, company: company)
      event = FactoryGirl.build(:event, campaign: campaign, company: company, place: nil)
      event.valid?.should be_true
    end

    it "should NOT allow the event to have a blank place if the user is not admin" do
      company = FactoryGirl.create(:company)
      user = FactoryGirl.create(:company_user, company: company, role: FactoryGirl.create(:role, is_admin: false)).user
      user.current_company = company
      User.current = user

      campaign = FactoryGirl.create(:campaign, company: company)
      event = FactoryGirl.build(:event, campaign: campaign, place: nil)
      event.valid?.should be_false
      event.errors[:place_reference].should include('cannot be blank')
    end


    it "should NOT allow the event to have a place where the user is not authorized" do
      company = FactoryGirl.create(:company)

      # The user is autorized to L.A. only
      user = FactoryGirl.create(:company_user, place_ids: [place_LA.id], company: company, role: FactoryGirl.create(:role, is_admin: false)).user
      user.current_company = company
      User.current = user

      campaign = FactoryGirl.create(:campaign, company: company)
      user.current_company_user.campaigns << campaign

      event = FactoryGirl.build(:event, campaign: campaign, company: company, place: place_SF)
      event.valid?.should be_false
      event.errors[:place_reference].should include('is not part of your authorized locations')

      event.place = place_LA
      event.valid?.should be_true

      bar_in_LA = FactoryGirl.create(:place, name: 'Bar Testing', route: 'Amargura St.', city: 'Los Angeles', state: 'California', country: 'US', types: ['establishment', 'bar'])

      event.place = bar_in_LA
      event.valid?.should be_true
    end

    it "should NOT give an error if the place is nil and a non admin is editing the event without modifying the place" do
      # An example: an admin created a event without a place, but another user (not admin) is trying to approve the event
      company = FactoryGirl.create(:company)
      campaign = FactoryGirl.create(:campaign, company: company)
      event = FactoryGirl.create(:event, campaign: campaign, company: company, place: nil)

      # The user is autorized to L.A. only
      user = FactoryGirl.create(:company_user, place_ids: [place_LA.id], company: company, role: FactoryGirl.create(:role, is_admin: false)).user
      user.current_company = company
      User.current = user

      event.valid?.should be_true
    end
  end

  describe "after_validation #set_event_timezone" do
    it "should set the current timezone for new events" do
      event = FactoryGirl.build(:event)
      event.valid?  # this will trigger the after_validation call
      event.timezone.should == 'America/Los_Angeles'
    end

    it "should set the current timezone if the event's start date is updated" do
      event = nil
      Time.use_zone('America/New_York') do
        event = FactoryGirl.create(:event)
        event.timezone.should == "America/New_York"
        expect(event.local_start_at.utc.strftime('%Y-%m-%d %H:%M:%S')).to eql event.read_attribute(:start_at).strftime('%Y-%m-%d %H:%M:%S')
      end
      Time.use_zone("America/Guatemala") do
        event = Event.last
        event.local_start_at
        event.start_date = '01/22/2019'
        event.valid?  # this will trigger the after_validation call
        event.timezone.should == "America/Guatemala"
      end
    end

    it "should set the current timezone if the event's end date is updated" do
      event = nil
      Time.use_zone('America/New_York') do
        event = FactoryGirl.create(:event)
        event.timezone.should == "America/New_York"
      end
      Time.use_zone("America/Guatemala") do
        event = Event.last
        event.end_date = '01/22/2019'
        event.valid?  # this will trigger the after_validation call
        event.timezone.should == "America/Guatemala"
      end
    end

    it "should not update the timezone if the event's dates are not modified" do
      event = nil
      # When creating the event the timezone should be set to America/New_York
      Time.use_zone('America/New_York') do
        event = FactoryGirl.create(:event, timezone: Time.zone.name)
        event.timezone.should == 'America/New_York'
      end

      # Then if later it's updated on a different timezone, the timezone should not be updated
      # if the dates are not modified
      Time.use_zone('America/Guatemala') do
        event = Event.last
        event.summary = 'Just modifying any column'
        event.save.should be_true
        event.timezone.should == 'America/New_York'
      end
    end
  end

  describe "team_members" do
    let(:company){ FactoryGirl.create(:company) }

    it "should return all teams and users" do
      event = FactoryGirl.build(:event, company: company)

      FactoryGirl.create(:company_user, company: company )
      user1 = FactoryGirl.create(:company_user, company: company )
      event.users << user1
      user2 = FactoryGirl.create(:company_user, company: company )
      event.users << user2

      FactoryGirl.create(:team, company: company )
      team1 = FactoryGirl.create(:team, company: company )
      event.teams << team1
      team2 = FactoryGirl.create(:team, company: company )
      event.teams << team2

      expect(event.team_members).to match_array [
        "company_user:#{user1.id}", "company_user:#{user2.id}",
        "team:#{team1.id}", "team:#{team2.id}"
      ]
    end
  end

  describe "team_members=" do
    let(:company){ FactoryGirl.create(:company) }

    it "should correctly assign users and teams" do
      event = FactoryGirl.build(:event, company: company)
      user1 = FactoryGirl.create(:company_user, company: company)
      user2 = FactoryGirl.create(:company_user, company: company)
      team1 = FactoryGirl.create(:team, company: company)

      event.team_members = [
        "company_user:#{user1.id}", "company_user:#{user2.id}",
        "team:#{team1.id}", 'invalid:222'
      ]

      expect(event.user_ids).to match_array [user1.id, user2.id]
      expect(event.team_ids).to match_array [team1.id]
      expect(event.new_record?).to be_true
    end
  end
end
