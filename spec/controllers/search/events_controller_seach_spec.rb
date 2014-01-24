require 'spec_helper'

describe EventsController, search: true do
  describe "As Super User" do
    before(:each) do
      @user = sign_in_as_user
      @company = @user.companies.first
      @company_user = @user.current_company_user
    end

    let(:campaign){ FactoryGirl.create(:campaign, company: @company) }

    describe "GET 'autocomplete'" do
      it "should return the correct buckets in the right order" do
        Sunspot.commit
        get 'autocomplete'
        response.should be_success

        buckets = JSON.parse(response.body)
        buckets.map{|b| b['label']}.should == ['Campaigns', 'Brands', 'Places', 'People']
      end

      it "should return the users in the People Bucket" do
        user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
        company_user = user.company_users.first
        Sunspot.commit

        get 'autocomplete', q: 'gu'
        response.should be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.select{|b| b['label'] == 'People'}.first
        people_bucket['value'].should == [{"label"=>"<i>Gu</i>illermo Vargas", "value"=>company_user.id.to_s, "type"=>"company_user"}]
      end

      it "should return the teams in the People Bucket" do
        team = FactoryGirl.create(:team, name: 'Spurs', company_id: @company.id)
        Sunspot.commit

        get 'autocomplete', q: 'sp'
        response.should be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.select{|b| b['label'] == 'People'}.first
        people_bucket['value'].should == [{"label"=>"<i>Sp</i>urs", "value" => team.id.to_s, "type"=>"team"}]
      end

      it "should return the teams and users in the People Bucket" do
        team = FactoryGirl.create(:team, name: 'Valladolid', company_id: @company.id)
        user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
        company_user = user.company_users.first
        Sunspot.commit

        get 'autocomplete', q: 'va'
        response.should be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.select{|b| b['label'] == 'People'}.first
        people_bucket['value'].should == [{"label"=>"<i>Va</i>lladolid", "value"=>team.id.to_s, "type"=>"team"}, {"label"=>"Guillermo <i>Va</i>rgas", "value"=>company_user.id.to_s, "type"=>"company_user"}]
      end

      it "should return the campaigns in the Campaigns Bucket" do
        campaign = FactoryGirl.create(:campaign, name: 'Cacique para todos', company_id: @company.id)
        Sunspot.commit

        get 'autocomplete', q: 'cac'
        response.should be_success

        buckets = JSON.parse(response.body)
        campaigns_bucket = buckets.select{|b| b['label'] == 'Campaigns'}.first
        campaigns_bucket['value'].should == [{"label"=>"<i>Cac</i>ique para todos", "value"=>campaign.id.to_s, "type"=>"campaign"}]
      end

      it "should return the brands in the Brands Bucket" do
        brand = FactoryGirl.create(:brand, name: 'Cacique')
        Sunspot.commit

        get 'autocomplete', q: 'cac'
        response.should be_success

        buckets = JSON.parse(response.body)
        brands_bucket = buckets.select{|b| b['label'] == 'Brands'}.first
        brands_bucket['value'].should == [{"label"=>"<i>Cac</i>ique", "value"=>brand.id.to_s, "type"=>"brand"}]
      end

      it "should return the venues in the Places Bucket" do
        Place.any_instance.should_receive(:fetch_place_data).and_return(true)
        venue = FactoryGirl.create(:venue, company_id: @company.id, place: FactoryGirl.create(:place, name: 'Motel Paraiso'))
        Sunspot.commit

        get 'autocomplete', q: 'mot'
        response.should be_success

        buckets = JSON.parse(response.body)
        places_bucket = buckets.select{|b| b['label'] == 'Places'}.first
        places_bucket['value'].should == [{"label"=>"<i>Mot</i>el Paraiso", "value"=>venue.id.to_s, "type"=>"venue"}]
      end
    end


    describe "GET 'filters'" do
      it "should return the correct buckets in the right order" do
        Sunspot.commit
        get 'filters', format: :json
        response.should be_success

        filters = JSON.parse(response.body)
        filters['filters'].map{|b| b['label']}.should == ["Campaigns", "Brands", "Areas", "People", "Event Status", "Active State"]
      end


      it "should return the correct buckets in the right order" do
        Kpi.create_global_kpis
        campaign.assign_all_global_kpis
        event = FactoryGirl.create(:event, campaign: campaign, company: @company)
        set_event_results(event,
          impressions: 100,
          interactions: 101,
          samples: 102,
          gender_male: 35,
          gender_female: 65,
          ethnicity_asian: 15,
          ethnicity_native_american: 23,
          ethnicity_black: 24,
          ethnicity_hispanic: 26,
          ethnicity_white: 12
        )
        Sunspot.commit

        get 'filters', with_event_data_only: true, format: :json

        response.should be_success
        filters = JSON.parse(response.body)

        filters['filters'].map{|b| b['label']}.should == ["Campaigns", "Brands", "Areas", "People", "Event Status", "Active State"]
        filters['filters'][0]['items'].count.should == 1
        filters['filters'][0]['items'].first['label'].should == campaign.name
      end
    end

    describe "GET calendar" do
      it "should return the correct list of brands the count of events" do
        campaign.brands << FactoryGirl.create(:brand, name: 'Jose Cuervo')
        event = FactoryGirl.create(:event, start_date: '01/13/2013', end_date: '01/13/2013', campaign: campaign, company: @company)
        Sunspot.commit
        get 'calendar', start: DateTime.new(2013, 01, 01, 0, 0, 0).to_i.to_s, end: DateTime.new(2013, 01, 31, 23, 59, 59).to_i.to_s, format: :json
        response.should be_success
        results = JSON.parse(response.body)
        results.count.should == 1
        brand = results.first
        brand['title'].should == 'Jose Cuervo'
        brand['count'].should == 1
        brand['start'].should == '2013-01-13'
        brand['end'].should == '2013-01-13'
      end
    end
  end

  describe "As NOT Super User" do
    before(:each) do
      @company = FactoryGirl.create(:company)
      @company_user = FactoryGirl.create(:company_user, company: @company, user: FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', current_company: @company), role: FactoryGirl.create(:role, is_admin: false, company: @company))
      @user = @company_user.user
      sign_in @user
    end

    describe "GET 'filters'" do
      it "should return the correct items for the Area bucket" do
        @company_user.role.permission_for(:view_list, Event).save

        #Assigned area with a common place, it should be in the filters
        area = FactoryGirl.create(:area, name: 'Austin', company: @company)
        area.places << FactoryGirl.create(:place, name: 'Bee Cave', city: 'Bee Cave', state: 'Texas', country: 'US', types: ['locality', 'political'], formatted_address: "Bee Cave, TX 78738, USA", latitude: 30.306098, longitude: -97.9523768, street_number: nil, route: nil, zipcode: "78738", administrative_level_1: "TX", administrative_level_2: "Travis", neighborhood: nil)
        @company_user.areas << area

        #Unassigned area with a common place, it should be in the filters
        area_unassigned = FactoryGirl.create(:area, name: 'San Antonio', company: @company)
        area_unassigned.places << FactoryGirl.create(:place, name: "Schertz", types: ["locality", "political"], formatted_address: "Schertz, TX, USA", latitude: 29.5521737, longitude: -98.269734, street_number: nil, route: nil, zipcode: nil, city: "Schertz", state: "Texas", country: "US", administrative_level_1: "TX", administrative_level_2: "Guadalupe", neighborhood: nil)

        #Unassigned area with not common place, it should not be in the filters
        area_not_in_filter = FactoryGirl.create(:area, name: 'Miami', company: @company)
        area_not_in_filter.places << FactoryGirl.create(:place, name: "Doral", types: ["locality", "political"], formatted_address: "Doral, FL, USA", latitude: 25.8195424, longitude: -80.3553302, street_number: nil, route: nil, zipcode: nil, city: "Doral", state: "Florida", country: "US", administrative_level_1: "FL", administrative_level_2: "Miami-Dade", neighborhood: nil)

        #Assigned area with not common place, it should be in the filters
        @company_user.areas << FactoryGirl.create(:area, name: 'San Francisco', company: @company)

        #Assigned place, itis the responsible for the common areas in the filters
        @company_user.places << FactoryGirl.create(:place, name: "Texas", types: ["administrative_area_level_1", "political"], formatted_address: "Texas, USA", latitude: 31.9685988, longitude: -99.9018131, street_number: nil, route: nil, zipcode: nil, city: nil, state: "Texas", country: "US", administrative_level_1: "TX", administrative_level_2: nil, neighborhood: nil)
        Sunspot.commit

        get 'filters', format: :json
        response.should be_success

        filters = JSON.parse(response.body)
        filters['filters'][2]['items'].count.should == 3

        filters['filters'][2]['items'].first['label'].should == 'Austin'
        filters['filters'][2]['items'].second['label'].should == 'San Antonio'
        filters['filters'][2]['items'].third['label'].should == 'San Francisco'
      end
    end
  end

end