require 'spec_helper'

describe EventsController do
  describe "as registered user" do
    before(:each) do
      @user = sign_in_as_user
      @company = @user.companies.first
      @company_user = @user.current_company_user
    end

    describe "GET 'edit'" do
      let(:event){ FactoryGirl.create(:event, company: @company) }
      it "returns http success" do
        get 'edit', id: event.to_param, format: :js
        response.should be_success
      end
    end

    describe "GET 'edit_summary'" do
      let(:event){ FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, company: @company)) }
      it "returns http success" do
        get 'edit_summary', id: event.to_param, format: :js
        response.should be_success
        response.should render_template('edit_summary')
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
            response.should render_template('videos')
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
      it "should not render form_dialog if no errors" do
        lambda {
          post 'create', event: {campaign_id: 1, start_date: '05/23/2020', start_time: '12:00pm', end_date: '05/22/2021', end_time: '01:00pm'}, format: :js
        }.should change(Event, :count).by(1)
        response.should be_success
        response.should render_template(:create)
        response.should_not render_template(:form_dialog)
      end

      it "should render the form_dialog template if errors" do
        lambda {
          post 'create', format: :js
        }.should_not change(Event, :count)
        response.should render_template(:create)
        response.should render_template(:form_dialog)
        assigns(:event).errors.count > 0
      end

      it "should assign current_user's company_id to the new event" do
        lambda {
          post 'create', event: {campaign_id: 1, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2021', end_time: '01:00pm'}, format: :js
        }.should change(Event, :count).by(1)
        assigns(:event).company_id.should == @company.id
      end

    end


    describe "PUT 'update'" do
      let(:event){ FactoryGirl.create(:event, company: @company) }
      it "must update the user attributes" do
        put 'update', id: event.to_param, event: {campaign_id: 111, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm'}, format: :js
        assigns(:event).should == event
        response.should be_success
        event.reload
        event.campaign_id.should == 111
        event.start_at.should == Time.zone.parse('2020-05-21 12:00:00')
        event.end_at.should == Time.zone.parse('2020-05-22 13:00:00')
      end
    end

    describe "DELETE 'delete_member' with a user" do
      let(:event){ FactoryGirl.create(:event, company: @company) }
      it "should remove the team member from the event" do
        event.users << @company_user
        lambda{
          delete 'delete_member', id: event.id, member_id: @company_user.id, format: :js
          response.should be_success
          assigns(:event).should == event
          event.reload
        }.should change(event.users, :count).by(-1)
      end

      it "should unassign any tasks assigned the user" do
        event.users << @company_user
        user_tasks = FactoryGirl.create_list(:task, 3, event: event, company_user: @company_user)
        other_tasks = FactoryGirl.create_list(:task, 2, event: event, company_user_id: @company_user.id+1)
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
        team.users << @company_user
        event.teams << team
        user_tasks = FactoryGirl.create_list(:task, 3, event: event, company_user: @company_user)
        other_tasks = FactoryGirl.create_list(:task, 2, event: event, company_user_id: @company_user.id+1)
        delete 'delete_member', id: event.id, team_id: team.id, format: :js

        user_tasks.each{|t| t.reload.company_user_id.should be_nil }
        other_tasks.each{|t| t.reload.company_user_id.should_not be_nil }

      end

      it "should not unassign any tasks assigned the team users if the user is directly assigned to the event" do
        team.users << @company_user
        event.users << @company_user
        event.teams << team
        user_tasks = FactoryGirl.create_list(:task, 3, event: event, company_user: @company_user)
        other_tasks = FactoryGirl.create_list(:task, 2, event: event, company_user_id: @company_user.id+1)
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
        get 'new_member', id: event.id, format: :js
        response.should be_success
        assigns(:event).should == event
        assigns(:users).should == [@company_user]
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
        team.users << @company_user
        get 'new_member', id: event.id, format: :js
        assigns(:assignable_teams).should == [team]
        assigns(:staff).should == [team,@company_user]
      end
    end


    describe "POST 'add_members" do
      let(:event){ FactoryGirl.create(:event, company: @company) }

      it 'should assign the user to the event' do
        lambda {
          post 'add_members', id: event.id, member_id: @company_user.to_param, format: :js
          response.should be_success
          assigns(:event).should == event
          event.reload
        }.should change(event.users, :count).by(1)
        event.users.should == [@company_user]
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
  end

end
