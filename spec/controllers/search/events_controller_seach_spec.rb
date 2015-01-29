require 'rails_helper'

describe EventsController, type: :controller, search: true do
  describe 'As Super User' do
    let(:user) { sign_in_as_user }
    let(:company_user) { user.current_company_user }
    let(:company) { user.companies.first }
    let(:campaign) { create(:campaign, company: company) }

    before { user }

    describe "GET 'autocomplete'" do
      it 'should return the correct buckets in the right order' do
        Sunspot.commit
        get 'autocomplete'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        expect(buckets.map { |b| b['label'] }).to eq([
          'Campaigns', 'Brands', 'Places', 'People', 'Active State', 'Event Status'])
      end

      it 'should return the users in the People Bucket' do
        user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
        company_user = user.company_users.first
        Sunspot.commit

        get 'autocomplete', q: 'gu'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.find { |b| b['label'] == 'People' }
        expect(people_bucket['value']).to eq([
          { 'label' => '<i>Gu</i>illermo Vargas', 'value' => company_user.id.to_s,
            'type' => 'user' }])
      end

      it 'should exclude the users in the :user param' do
        user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
        excluded_user = create(:user, first_name: 'Guillermo', last_name: 'Tell', company_id: company.id)
        company_user = user.company_users.first
        Sunspot.commit

        get 'autocomplete', q: 'gu', user: [excluded_user.company_users.first.id]
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.find { |b| b['label'] == 'People' }
        expect(people_bucket['value']).to eq([
          { 'label' => '<i>Gu</i>illermo Vargas', 'value' => company_user.id.to_s,
            'type' => 'user' }])
      end

      it 'should return the teams in the People Bucket' do
        team = create(:team, name: 'Spurs', company_id: company.id)
        Sunspot.commit

        get 'autocomplete', q: 'sp'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.find { |b| b['label'] == 'People' }
        expect(people_bucket['value']).to eq([
          { 'label' => '<i>Sp</i>urs', 'value' => team.id.to_s, 'type' => 'team' }])
      end

      it 'should exclude teams in the :team param' do
        team = create(:team, name: 'Spurs', company_id: company.id)
        excluded_team = create(:team, name: 'Spurs Jr', company_id: company.id)
        Sunspot.commit

        get 'autocomplete', q: 'sp', team: [excluded_team.id]
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.find { |b| b['label'] == 'People' }
        expect(people_bucket['value']).to eq([
          { 'label' => '<i>Sp</i>urs', 'value' => team.id.to_s, 'type' => 'team' }])
      end

      it 'should return the teams and users in the People Bucket' do
        team = create(:team, name: 'Valladolid', company_id: company.id)
        user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
        company_user = user.company_users.first
        Sunspot.commit

        get 'autocomplete', q: 'va'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.find { |b| b['label'] == 'People' }
        expect(people_bucket['value']).to eq([
          { 'label' => '<i>Va</i>lladolid', 'value' => team.id.to_s, 'type' => 'team' },
          { 'label' => 'Guillermo <i>Va</i>rgas', 'value' => company_user.id.to_s,
            'type' => 'user' }
        ])
      end

      it 'should return the campaigns in the Campaigns Bucket' do
        campaign = create(:campaign, name: 'Cacique para todos', company_id: company.id)
        Sunspot.commit

        get 'autocomplete', q: 'cac'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        campaigns_bucket = buckets.find { |b| b['label'] == 'Campaigns' }
        expect(campaigns_bucket['value']).to eq([
          { 'label' => '<i>Cac</i>ique para todos', 'value' => campaign.id.to_s,
            'type' => 'campaign' }
        ])
      end

      it 'should exclude the campaigns that are in the campaign param' do
        campaign = create(:campaign, name: 'Cacique para todos', company: company)
        excluded_campaign = create(:campaign, name: 'Cacique para nadie', company: company)
        Sunspot.commit

        get 'autocomplete', q: 'cac', campaign: [excluded_campaign.id]
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        campaigns_bucket = buckets.find { |b| b['label'] == 'Campaigns' }
        expect(campaigns_bucket['value']).to eq([
          { 'label' => '<i>Cac</i>ique para todos', 'value' => campaign.id.to_s,
            'type' => 'campaign' }
        ])
      end

      it 'should return the brands in the Brands Bucket' do
        brand = create(:brand, name: 'Cacique', company_id: company.id)
        Sunspot.commit

        get 'autocomplete', q: 'cac'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        brands_bucket = buckets.find { |b| b['label'] == 'Brands' }
        expect(brands_bucket['value']).to eq([
          { 'label' => '<i>Cac</i>ique', 'value' => brand.id.to_s, 'type' => 'brand' }])
      end

      it 'should return the venues in the Places Bucket' do
        expect_any_instance_of(Place).to receive(:fetch_place_data).and_return(true)
        venue = create(:venue, company_id: company.id, place: create(:place, name: 'Motel Paraiso'))
        Sunspot.commit

        get 'autocomplete', q: 'mot'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        places_bucket = buckets.find { |b| b['label'] == 'Places' }
        expect(places_bucket['value']).to eq([
          { 'label' => '<i>Mot</i>el Paraiso', 'value' => venue.id.to_s, 'type' => 'venue' }
        ])
      end

      it 'should return inactive in the Active State Bucket' do
        get 'autocomplete', q: 'inact'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        places_bucket = buckets.find { |b| b['label'] == 'Active State' }
        expect(places_bucket['value']).to eq([
          { 'label' => '<i>Inact</i>ive', 'value' => 'Inactive', 'type' => 'status' }
        ])
      end
    end

    describe "GET 'filters'" do
      it 'should return the correct buckets in the right order' do
        Sunspot.commit
        create(:custom_filter, owner: company_user, apply_to: 'events')

        get 'filters', format: :json
        expect(response).to be_success

        filters = JSON.parse(response.body)
        expect(filters['filters'].map { |b| b['label'] }).to eq([
          'Campaigns', 'Brands', 'Areas', 'People', 'Event Status',
          'Active State', 'SAVED FILTERS'])
      end

      it 'should return the correct buckets in the right order' do
        Kpi.create_global_kpis
        campaign.assign_all_global_kpis
        event = create(:event, campaign: campaign, company: company)
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
        create(:custom_filter, owner: company_user, apply_to: 'events')
        Sunspot.commit

        get 'filters', with_event_data_only: true, format: :json

        expect(response).to be_success
        filters = JSON.parse(response.body)

        expect(filters['filters'].map { |b| b['label'] }).to eq([
          'Campaigns', 'Brands', 'Areas', 'People', 'Event Status',
          'Active State', 'SAVED FILTERS'])
        expect(filters['filters'][0]['items'].count).to eq(1)
        expect(filters['filters'][0]['items'].first['label']).to eq(campaign.name)
      end
    end

    describe 'GET calendar' do
      it 'should return the correct list of brands the count of events' do
        campaign.brands << create(:brand, company: company, name: 'Jose Cuervo')
        create(:event, start_date: '01/13/2013', end_date: '01/13/2013', campaign: campaign)
        Sunspot.commit
        get 'calendar', start: DateTime.new(2013, 01, 01, 0, 0, 0).to_i.to_s,
                        end: DateTime.new(2013, 01, 31, 23, 59, 59).to_i.to_s,
                        format: :json
        expect(response).to be_success
        results = JSON.parse(response.body)
        expect(results.count).to eq(1)
        brand = results.first
        expect(brand['title']).to eq('Jose Cuervo')
        expect(brand['count']).to eq(1)
        expect(brand['start']).to eq('2013-01-13')
        expect(brand['end']).to eq('2013-01-13')
      end
    end
  end

  describe 'As NOT Super User' do
    let(:company) { create(:company) }
    let(:user) { company_user.user }
    let(:company_user) do
      create(:company_user,
             company: company,
             role: create(:role, is_admin: false, company: company))
    end

    before { sign_in user }

    describe "GET 'filters'" do
      it 'should return the correct items for the Area bucket' do
        company_user.role.permission_for(:view_list, Event).save

        # Assigned area with a common place, it should be in the filters
        area = create(:area, name: 'Austin', company: company)
        area.places << create(:city, name: 'Bee Cave', state: 'Texas', country: 'US')
        company_user.areas << area

        # Unassigned area with a common place, it should be in the filters
        area_unassigned = create(:area, name: 'San Antonio', company: company)
        area_unassigned.places << create(:city, name: 'Schertz',
                                                state: 'Texas', country: 'US')

        # Unassigned area with not common place, it should not be in the filters
        area_not_in_filter = create(:area, name: 'Miami', company: company)
        area_not_in_filter.places << create(:city, name: 'Doral',
                                                   state: 'Florida', country: 'US')

        # Assigned area with not common place, it should be in the filters
        company_user.areas << create(:area, name: 'San Francisco', company: company)

        # Assigned place, itis the responsible for the common areas in the filters
        company_user.places << create(:state, name: 'Texas', country: 'US')

        get 'filters', format: :json
        expect(response).to be_success

        filters = JSON.parse(response.body)
        areas_filters = filters['filters'].find { |f| f['label'] == 'Areas' }
        expect(areas_filters['items'].count).to eql 3

        expect(areas_filters['items'].first['label']).to eql 'Austin'
        expect(areas_filters['items'].second['label']).to eql 'San Antonio'
        expect(areas_filters['items'].third['label']).to eql 'San Francisco'
      end

      describe 'when a user only a place assiged to it' do
        it 'returns all the areas that have at least one place inside' do
          company_user.role.permission_for(:view_list, Event).save

          # This is one area that have one place inside US
          area = create(:area, name: 'Austin', company: company)
          area.places << create(:place, name: 'Bee Cave',
                city: 'Bee Cave', state: 'Texas',
                country: 'US', types: %w(locality political))

          # This is another area that have one place inside US
          area = create(:area, name: 'San Antonio', company: company)
          area.places << create(:place, name: 'Schertz',
                types: %w(locality political), city: 'Schertz', state: 'Texas', country: 'US')

          # This area doesn't  have one place in US
          area = create(:area, name: 'Centro America', company: company)
          area.places << create(:place, name: 'Costa Rica',
                types: %w(country political), city: 'Schertz', state: nil, country: 'CR')

          # The user have US as the allowed places
          company_user.places << create(:place,
                                        name: 'United States', types: %w(country political),
                                        city: nil, state: nil, country: 'US')

          get 'filters', format: :json
          expect(response).to be_success

          filters = JSON.parse(response.body)

          # It should return the first two areas
          areas_filters = filters['filters'].find { |f| f['label'] == 'Areas' }
          expect(areas_filters['items'].count).to eql 2
          expect(areas_filters['items'].first['label']).to eql 'Austin'
          expect(areas_filters['items'].second['label']).to eql 'San Antonio'
        end
      end
    end
  end

end
