require 'spec_helper'

describe UsersController do
  describe "as registered user" do
    before(:each) do
      @user = sign_in_as_user
      @company = @user.current_company
    end

    describe "GET 'edit'" do
      let(:user){ FactoryGirl.create(:user, company_id: @company.id) }

      it "returns http success" do
        get 'edit', id: user.to_param, format: :js
        response.should be_success
      end
    end

    describe "GET 'index'" do
      it "returns http success" do
        get 'index'
        response.should be_success
      end

      describe "filters" do
        it "should call the with_text filter" do
          User.should_receive(:with_text).with('abc').at_least(:once) { User }
          get :index, with_text: 'abc', format: :json
        end
        it "should call the by_events filter" do
          User.should_receive(:by_events).with(123).at_least(:once) { User }
          get :index, by_events: 123, format: :json
        end
        it "should call the by_teams filter" do
          User.should_receive(:by_teams).with(123).at_least(:once) { User }
          get :index, by_teams: 123, format: :json
        end
      end

      describe "json requests" do
        it "responds to .table format" do
          get 'index', format: :json
          response.should be_success
        end

        it "returns the correct structure" do
          FactoryGirl.create_list(:user, 3, company_id: @company.id)

          # Users on other companies should not be included on the results
          FactoryGirl.create_list(:user, 2, company_id: 9999)
          get 'index', sEcho: 1, format: :json
          parsed_body = JSON.parse(response.body)

          parsed_body["total"].should == 4
          parsed_body["items"].count.should == 4
        end
      end
    end

    describe "GET 'deactivate'" do
      let(:user){ FactoryGirl.create(:user, company_id: @company.id, active: true) }

      it "deactivates an active user" do
        user.reload.company_users.first.active.should be_true
        get 'deactivate', id: user.to_param, format: :js
        response.should be_success
        user.reload.active?.should be_false
        user.company_users.first.active.should be_false
      end
    end

    describe "GET 'activate'" do
      let(:user){ FactoryGirl.create(:user, company_id: @company.id, active: false) }
      it "activates an inactive user" do
        user.reload.company_users.first.active.should be_false
        get 'activate', id: user.to_param, format: :js
        response.should be_success
        user.reload.active?.should be_true
        user.company_users.first.active.should be_true
      end
    end

    describe "PUT 'update'" do
      let(:user){ FactoryGirl.create(:user, company_id: @company.id) }
      it "must update the user data" do
        put 'update', id: user.to_param, user: {first_name: 'Juanito', last_name: 'Perez'}, format: :js
        assigns(:user).should == user
        response.should be_success
        user.reload
        user.first_name.should == 'Juanito'
        user.last_name.should == 'Perez'
      end

      it "must update the user password" do
        old_password = user.encrypted_password
        put 'update', id: user.to_param, user: {password: 'Juanito123', password_confirmation: 'Juanito123'}, format: :js
        assigns(:user).should == user
        response.should be_success
        user.reload
        user.encrypted_password.should_not == old_password
      end

      it "must update the its own profile data" do
        old_password = @user.encrypted_password
        put 'update', id: @user.to_param, user: {first_name: 'Juanito', last_name: 'Perez',  email: 'test@testing.com', city: 'Miami', state: 'FL', country: 'US', password: 'Juanito123', password_confirmation: 'Juanito123'}, format: :js
        assigns(:user).should == @user
        response.should be_success
        @user.reload
        @user.first_name.should == 'Juanito'
        @user.last_name.should == 'Perez'
        @user.email.should == 'test@testing.com'
        @user.city.should == 'Miami'
        @user.state.should == 'FL'
        @user.country.should == 'US'
        @user.encrypted_password.should_not == old_password
      end
    end
  end
end
