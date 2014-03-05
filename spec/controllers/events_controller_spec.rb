require 'spec_helper'
require 'roo'

describe EventsController do
  describe "as registered user" do
    before(:each) do
      @user = sign_in_as_user
      @company = @user.companies.first
      @company_user = @user.current_company_user
    end

    after do
      Timecop.return
    end

    describe "GET 'new'" do
      it "returns http success" do
        get 'new', format: :js
        response.should be_success
        response.should render_template('new')
        response.should render_template('form')
      end
    end

    describe "GET 'edit'" do
      let(:event){ FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, company: @company)) }
      it "returns http success" do
        get 'edit', id: event.to_param, format: :js
        response.should be_success
      end
    end

    describe "GET 'edit_data'" do
      let(:event){ FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, company: @company)) }
      it "returns http success" do
        event.build_event_data.save
        get 'edit_data', id: event.to_param, format: :js
        response.should be_success
        response.should render_template('edit_data')
      end
    end

    describe "GET 'edit_surveys'" do
      let(:event){ FactoryGirl.create(:event, company: @company) }
      it "returns http success" do
        get 'edit_surveys', id: event.to_param, format: :js
        response.should be_success
        response.should render_template('edit_surveys')
        response.should render_template('surveys')
      end
    end

    describe "GET 'show'" do
      describe "for an event in the future" do
        let(:event){ FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, company: @company), start_date: 1.week.from_now.to_s(:slashes), end_date: 1.week.from_now.to_s(:slashes)) }

        it "renders the correct templates" do
          get 'show', id: event.to_param
          response.should be_success
          response.should render_template('show')
          response.should_not render_template('show_results')
          response.should_not render_template('edit_results')
        end
      end

      describe "for an event in the past" do
        let(:event){ FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, company: @company), start_date: 1.day.ago.to_s(:slashes), end_date: 1.day.ago.to_s(:slashes)) }

        describe "when no data have been entered" do
          it "renders the correct templates" do
            Kpi.create_global_kpis
            event.campaign.assign_all_global_kpis
            get 'show', id: event.to_param
            response.should be_success
            response.should render_template('show')
            response.should render_template('edit_results')
            response.should render_template('surveys')
            response.should render_template('comments')
            response.should render_template('photos')
            response.should render_template('expenses')
            response.should_not render_template('show_results')
          end
        end
      end
    end

    describe "GET 'index'" do
      it "returns http success" do
        get 'index'
        response.should be_success
      end

      describe "calendar_highlights" do
        it "loads the highligths for the calendar" do
          FactoryGirl.create(:event, company: @company, start_date: '01/23/2013', end_date: '01/24/2013')
          FactoryGirl.create(:event, company: @company, start_date: '02/15/2013', end_date: '02/15/2013')
          get 'index'
          response.should be_success
          assigns(:calendar_highlights).should == { 2013 => { 1 => { 23 => 1, 24 => 1 }, 2 => { 15 => 1 } } }
        end
      end

      it "queue the job for export the list" do
        expect{
          get :index, format: :xlsx
        }.to change(ListExport, :count).by(1)
        export = ListExport.last
        ListExportWorker.should have_queued(export.id)
      end
    end

    describe "GET 'list_export'", search: true do
      let(:campaign) { FactoryGirl.create(:campaign, company: @company, name: 'Test Campaign FY01') }
      it "should return an empty book with the correct headers" do
        expect { get 'index', format: :xlsx }.to change(ListExport, :count).by(1)
        woorbook_from_last_export do |oo|
          oo.last_row.should == 1
          1.upto(oo.last_column).map{|col| oo.cell(1, col) }.should == ["CAMPAIGN NAME", "AREA", "START", "END", "VENUE NAME", "ADDRESS", "CITY", "STATE", "ZIP", "ACTIVE STATE", "EVENT STATUS", "TEAM MEMBERS","URL"]
        end
      end

      it "should include the event results" do
        place = FactoryGirl.create(:place, name: 'Bar Prueba', city: 'Los Angeles', state: 'California', country: 'US')
        event = FactoryGirl.create(:approved_event, company: @company, campaign: campaign, place: place)
        team = FactoryGirl.create(:team, company: @company, name: "zteam")
        event.teams << team
        Sunspot.commit

        expect { get 'index', format: :xlsx }.to change(ListExport, :count).by(1)
        woorbook_from_last_export do |oo|
          oo.last_row.should == 2
          1.upto(oo.last_column).map{|col| oo.cell(2, col) }.should == ["Test Campaign FY01", "", "Wed, 23 Jan 2019 09:59:59 +0000", "Wed, 23 Jan 2019 12:00:00 +0000", "Bar Prueba", "Bar Prueba, Los Angeles, California, 12345", "Los Angeles", "California", 12345.0, "Active", "Approved", "Test User, zteam", Rails.application.routes.url_helpers.event_url(event) ]
        end
      end
    end

    describe "GET 'new'" do
      it "initializes the event with the correct date" do
        Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
          get 'new', format: :js
          response.should be_success
          assigns(:event).start_date.should == Time.zone.local(2013, 07, 26, 12, 15).to_s(:slashes)
          assigns(:event).start_time.should == Time.zone.local(2013, 07, 26, 12, 15).to_s(:time_only)
          assigns(:event).end_date.should == Time.zone.local(2013, 07, 26, 13, 15).to_s(:slashes)
          assigns(:event).end_time.should == Time.zone.local(2013, 07, 26, 13, 15).to_s(:time_only)
        end
      end

      it "always choose the hour in the future" do
        Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 01)) do
          get 'new', format: :js
          response.should be_success
          assigns(:event).start_date.should == Time.zone.local(2013, 07, 26, 12, 15).to_s(:slashes)
          assigns(:event).start_time.should == Time.zone.local(2013, 07, 26, 12, 15).to_s(:time_only)
          assigns(:event).end_date.should == Time.zone.local(2013, 07, 26, 13, 15).to_s(:slashes)
          assigns(:event).end_time.should == Time.zone.local(2013, 07, 26, 13, 15).to_s(:time_only)
        end
      end

      it "a event that ends on the next day" do
        Timecop.freeze(Time.zone.local(2013, 07, 26, 23, 01)) do
          get 'new', format: :js
          response.should be_success
          assigns(:event).start_date.should == Time.zone.local(2013, 07, 26, 23, 15).to_s(:slashes)
          assigns(:event).start_time.should == Time.zone.local(2013, 07, 26, 23, 15).to_s(:time_only)
          assigns(:event).end_date.should == Time.zone.local(2013, 07, 27, 0, 15).to_s(:slashes)
          assigns(:event).end_time.should == Time.zone.local(2013, 07, 27, 0, 15).to_s(:time_only)
        end
      end
    end

    describe "GET 'items'" do
      it "returns http success" do
        get 'items'
        response.should be_success
      end
    end

    describe "GET 'tasks'" do
      let(:event) { FactoryGirl.create(:event, company: @company) }
      it "returns http success" do
        get 'tasks', id: event.to_param
        response.should be_success
        response.should render_template(:tasks)
        response.should render_template(:tasks_counters)
      end
    end

    describe "POST 'create'" do
      let(:campaign){ FactoryGirl.create(:campaign, company: @company) }
      it "should not render form_dialog if no errors" do
        lambda {
          post 'create', event: {campaign_id: campaign.id, start_date: '05/23/2020', start_time: '12:00pm', end_date: '05/22/2021', end_time: '01:00pm'}, format: :js
        }.should change(Event, :count).by(1)
        response.should be_success
        response.should render_template(:create)
        response.should_not render_template(:form_dialog)
      end

      it "should render the form_dialog template if errors" do
        lambda {
          post 'create', event: {campaign_id: 'XX'}, format: :js
        }.should_not change(Event, :count)
        response.should render_template(:create)
        response.should render_template(:form_dialog)
        assigns(:event).errors.count > 0
      end

      it "should assign current_user's company_id to the new event" do
        lambda {
          post 'create', event: {campaign_id: campaign.id, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm'}, format: :js
        }.should change(Event, :count).by(1)
        assigns(:event).company_id.should == @company.id
      end
      
      it "should assign current_company_user to the new event" do
        lambda {
          post 'create', event: {campaign_id: campaign.id, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm'}, format: :js
        }.should change(Event, :count).by(1)
        assigns(:event).users.last.user.id.should == @user.id
      end

      it "should create the event with the correct dates" do
        lambda {
          post 'create', event: {campaign_id: campaign.id, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/21/2020', end_time: '01:00pm'}, format: :js
        }.should change(Event, :count).by(1)
        event = Event.last
        event.start_at.should == Time.zone.parse('2020/05/21 12:00pm')
        event.end_at.should == Time.zone.parse('2020/05/21 01:00pm')
        event.promo_hours.should == 1
      end
    end

    describe "PUT 'update'" do
      let(:campaign){ FactoryGirl.create(:campaign, company: @company) }
      let(:event){ FactoryGirl.create(:event, company: @company, campaign: campaign) }
      it "must update the event attributes" do
        new_campaign = FactoryGirl.create(:campaign, company: @company)
        put 'update', id: event.to_param, event: {campaign_id: new_campaign.id, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm'}, format: :js
        assigns(:event).should == event
        response.should be_success
        event.reload
        event.campaign_id.should == new_campaign.id
        event.start_at.should == Time.zone.parse('2020-05-21 12:00:00')
        event.end_at.should == Time.zone.parse('2020-05-22 13:00:00')
      end

      it "must update the event attributes" do
        put 'update', id: event.to_param, partial: 'event_data', event: {campaign_id: FactoryGirl.create(:campaign, company: @company).to_param, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm'}, format: :js
        assigns(:event).should == event
        response.should be_success
        response.should render_template('results_event_data')
      end

      it "should update the event data for a event without data" do
        Kpi.create_global_kpis
        campaign.assign_all_global_kpis
        expect {
          put 'update', id: event.to_param,
            event: {
              summary: 'A summary of the events',
              results_attributes: [
                {form_field_id: campaign.form_field_for_kpi(Kpi.impressions), kpi_id: Kpi.impressions.id, kpis_segment_id: nil, value: "100"},
                {form_field_id: campaign.form_field_for_kpi(Kpi.interactions), kpi_id: Kpi.interactions.id, kpis_segment_id: nil, value: "200"}
              ]
            }
        }.to change(EventResult, :count).by(2)
        event.reload
        event.summary.should == 'A summary of the events'
        event.result_for_kpi(Kpi.impressions).value.should == 100
        event.result_for_kpi(Kpi.interactions).value.should == 200
      end


      it "should update the event data for a event that already have results" do
        Kpi.create_global_kpis
        campaign.assign_all_global_kpis

        impressions = event.result_for_kpi(Kpi.impressions)
        interactions = event.result_for_kpi(Kpi.interactions)
        expect {
          event.result_for_kpi(Kpi.impressions).value = 100
          event.result_for_kpi(Kpi.interactions).value = 200
          event.save
        }.to change(EventResult, :count).by(2)

        expect {
          put 'update', id: event.to_param,
            event: {
              summary: 'A summary of the events',
              results_attributes: [
                {form_field_id: campaign.form_field_for_kpi(Kpi.impressions), kpi_id: Kpi.impressions.id, kpis_segment_id: nil, value: "1111", id: impressions.id},
                {form_field_id: campaign.form_field_for_kpi(Kpi.interactions), kpi_id: Kpi.interactions.id, kpis_segment_id: nil, value: "2222", id: interactions.id}
              ]
            }
        }.to_not change(EventResult, :count)
        event.reload
        event.summary.should == 'A summary of the events'
        event.result_for_kpi(Kpi.impressions).value.should == 1111
        event.result_for_kpi(Kpi.interactions).value.should == 2222
      end
    end

    describe "DELETE 'delete_member' with a user" do
      let(:event){ FactoryGirl.create(:event, company: @company) }
      it "should remove the team member from the event" do
        lambda{
          delete 'delete_member', id: event.id, member_id: @company_user.id, format: :js
          response.should be_success
          assigns(:event).should == event
          event.reload
        }.should change(event.users, :count).by(-1)
      end

      it "should unassign any tasks assigned the user" do
        event.users << @company_user
        other_user = FactoryGirl.create(:company_user, company_id: 1)
        user_tasks = FactoryGirl.create_list(:task, 3, event: event, company_user: @company_user)
        other_tasks = FactoryGirl.create_list(:task, 2, event: event, company_user: other_user)
        delete 'delete_member', id: event.id, member_id: @company_user.id, format: :js

        user_tasks.each{|t| t.reload.company_user_id.should be_nil }
        other_tasks.each{|t| t.reload.company_user_id.should_not be_nil }
      end

      it "should not raise error if the user doesn't belongs to the event" do
        delete 'delete_member', id: event.id, member_id: @company_user.id, format: :js
        event.reload
        response.should be_success
        assigns(:event).should == event
      end
    end

    describe "DELETE 'delete_member' with a team" do
      let(:event){ FactoryGirl.create(:event, company: @company) }
      let(:team){ FactoryGirl.create(:team, company: @company) }
      it "should remove the team from the event" do
        event.teams << team
        lambda{
          delete 'delete_member', id: event.id, team_id: team.id, format: :js
          response.should be_success
          assigns(:event).should == event
          event.reload
        }.should change(event.teams, :count).by(-1)
      end

      it "should unassign any tasks assigned the team users" do
        another_user = FactoryGirl.create(:company_user, company_id: 1)
        team.users << another_user
        event.teams << team
        other_user = FactoryGirl.create(:company_user, company_id: 1)
        user_tasks = FactoryGirl.create_list(:task, 3, event: event, company_user: another_user)
        other_tasks = FactoryGirl.create_list(:task, 2, event: event, company_user: other_user)
        delete 'delete_member', id: event.id, team_id: team.id, format: :js
        event.reload
        user_tasks.each{|t| t.reload.company_user_id.should be_nil }
        other_tasks.each{|t| t.reload.company_user_id.should_not be_nil }

      end

      it "should not unassign any tasks assigned the team users if the user is directly assigned to the event" do
        team.users << @company_user
        event.teams << team
        other_user = FactoryGirl.create(:company_user, company_id: 1)
        user_tasks = FactoryGirl.create_list(:task, 3, event: event, company_user: @company_user)
        other_tasks = FactoryGirl.create_list(:task, 2, event: event, company_user: other_user)
        delete 'delete_member', id: event.id, team_id: team.id, format: :js

        user_tasks.each{|t| t.reload.company_user_id.should == @company_user.id }
        other_tasks.each{|t| t.reload.company_user_id.should_not be_nil }
      end

      it "should not raise error if the team doesn't belongs to the event" do
        delete 'delete_member', id: event.id, team_id: team.id, format: :js
        event.reload
        response.should be_success
        assigns(:event).should == event
      end
    end

    describe "GET 'new_member" do
      let(:event){ FactoryGirl.create(:event, company: @company) }
      it 'should load all the company\'s users into @users' do
        FactoryGirl.create(:user, company_id: @company.id+1)
        another_user = FactoryGirl.create(:company_user, company_id: @company.id,role_id: @company_user.role_id)
        get 'new_member', id: event.id, format: :js
        event.reload
        response.should be_success
        assigns(:event).should == event
        assigns(:users).should == [another_user]
      end

      it 'should not load the users that are already assigned to the event' do
        another_user = FactoryGirl.create(:company_user, company_id: @company.id, role_id: @company_user.role_id)
        event.users << @company_user
        get 'new_member', id: event.id, format: :js
        response.should be_success
        assigns(:event).should == event
        assigns(:users).should == [another_user]
        assigns(:staff).should == [another_user]
      end

      it 'should load teams with active users' do
        @company_user.user.update_attributes({first_name: 'CDE', last_name: 'FGH'}, without_protection: true)
        team = FactoryGirl.create(:team, name: 'ABC', company_id: @company.id)
        other_user = FactoryGirl.create(:company_user, company_id: @company.id, role_id: @company_user.role_id)
        team.users << other_user
        get 'new_member', id: event.id, format: :js
        assigns(:assignable_teams).should == [team]
        assigns(:staff).should == [team,other_user]
      end
    end


    describe "POST 'add_members" do
      let(:event){ FactoryGirl.create(:event, company: @company) }

      it 'should assign the user to the event' do
        other_user = FactoryGirl.create(:company_user, company_id: @company.id)
        lambda {
          post 'add_members', id: event.id, member_id: other_user.to_param, format: :js
          response.should be_success
          assigns(:event).should == event
          event.reload
        }.should change(event.users, :count).by(1)
        event.users.should =~ [@company_user, other_user]
      end

      it 'should assign all the team to the event' do
        team = FactoryGirl.create(:team, company_id: @company.id)
        lambda {
          post 'add_members', id: event.id, team_id: team.to_param, format: :js
          response.should be_success
          assigns(:event).should == event
          event.reload
        }.should change(event.teams, :count).by(1)
        event.teams.should == [team]
      end

      it 'should not assign users to the event if they are already part of the event' do
        event.users << @company_user
        lambda {
          post 'add_members', id: event.id, member_id: @company_user.to_param, format: :js
          response.should be_success
          assigns(:event).should == event
          event.reload
        }.should_not change(event.users, :count)
      end

      it 'should not assign teams to the event if they are already part of the event' do
        team = FactoryGirl.create(:team, company_id: @company.id)
        event.teams << team
        lambda {
          post 'add_members', id: event.id, team_id: team.to_param, format: :js
          response.should be_success
          assigns(:event).should == event
          event.reload
        }.should_not change(event.teams, :count)
      end
    end

    describe "GET 'activate'" do
      it "should activate an inactive event" do
        event = FactoryGirl.create(:event, active: false, company: @company)
        lambda {
          get 'activate', id: event.to_param, format: :js
          response.should be_success
          event.reload
        }.should change(event, :active).to(true)
      end
    end

    describe "GET 'deactivate'" do
      it "should deactivate an active event" do
        event = FactoryGirl.create(:event, active: true, company: @company)
        lambda {
          get 'deactivate', id: event.to_param, format: :js
          response.should be_success
          event.reload
        }.should change(event, :active).to(false)
      end
    end

    describe "PUT 'submit'" do
      it "should submit event" do
        event = FactoryGirl.create(:event, active: true, company: @company)
        lambda {
          put 'submit', id: event.to_param, format: :js
          response.should be_success
          event.reload
        }.should change(event, :submitted?).to(true)
      end

      it "should not allow to submit the event if the event data is not valid" do
        campaign = FactoryGirl.create(:campaign, company_id: @company)
        field = FactoryGirl.create(:campaign_form_field, campaign: campaign, kpi: FactoryGirl.create(:kpi, company_id: 1), field_type: 'number', options: {required: true})
        event = FactoryGirl.create(:event, active: true, company: @company, campaign: campaign)
        lambda {
          put 'submit', id: event.to_param, format: :js
          response.should be_success
          event.reload
        }.should_not change(event, :submitted?).to(true)
      end
    end


    describe "PUT 'approve'" do
      it "should approve event" do
        event = FactoryGirl.create(:submitted_event, active: true, company: @company)
        lambda {
          put 'approve', id: event.to_param
          response.should redirect_to(event_path(event, :status => 'approved'))
          event.reload
        }.should change(event, :approved?).to(true)
      end
    end


    describe "PUT 'reject'" do
      it "should reject event" do
        event = FactoryGirl.create(:submitted_event, active: true, company: @company)
        lambda {
          put 'reject', id: event.to_param, reason: 'blah blah blah', format: :js
          response.should be_success
          event.reload
        }.should change(event, :rejected?).to(true)
        event.reject_reason.should == 'blah blah blah'
      end
    end
  end


  describe "user with permissions to edit event data only" do
    before(:each) do
      @company_user = FactoryGirl.create(:company_user, company_id: FactoryGirl.create(:company).id, permissions: [[:show, 'Event'], [:edit_unsubmitted_data, 'Event']])
      @company = @company_user.company
      @user = @company_user.user
      sign_in @user
    end

    let(:event){ FactoryGirl.create(:event, company: @company) }

    it "should be able to edit event_data" do
      put 'update', id: event.to_param, event: {results_attributes: {} }, format: :js
      assigns(:event).should == event
      response.should be_success
      response.should render_template('events/_event')
    end
  end



end
