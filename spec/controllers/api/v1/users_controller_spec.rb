require 'spec_helper'

describe Api::V1::UsersController do
  let(:user) { sign_in_as_user }

  describe "POST 'new_password'" do
    it "should return failure for a non-existent user" do
      Devise::Mailer.should_not_receive(:reset_password_instructions)
      post 'new_password', email:"fake@email.com", format: :json
      response.response_code.should == 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Action Failed'
      result['data'].should be_empty
    end

    it "should return failure for an inactive user" do
      Devise::Mailer.should_not_receive(:reset_password_instructions)
      inactive_user = FactoryGirl.create(:company_user, company: FactoryGirl.create(:company), user: FactoryGirl.create(:user), active: false)
      post 'new_password', email: inactive_user.email, format: :json
      response.response_code.should == 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Action Failed'
      result['data'].should be_empty
    end

    it "should return failure for an active user with inactive role" do
      Devise::Mailer.should_not_receive(:reset_password_instructions)
      company = FactoryGirl.create(:company)
      inactive_user = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user), role: FactoryGirl.create(:role, company: company, active: false))
      post 'new_password', email: inactive_user.email, format: :json
      response.response_code.should == 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Action Failed'
      result['data'].should be_empty
    end

    it "should send reset password instructions to the user" do
      Devise::Mailer.should_receive(:reset_password_instructions).and_return(double(deliver: true))
      post 'new_password', email: user.email, format: :json
      response.should be_success
      result = JSON.parse(response.body)
      result['success'].should == true
      result['info'].should == 'Reset password instructions sent'
      result['data'].should be_empty

      user.reload
      user.reset_password_token.should_not be_nil
    end
  end

  describe "GET 'companies'" do
    it "should return failure for invalid authorization token" do
      get 'companies', auth_token: 'XXXXXXXXXXXXXXXX', format: :json
      response.response_code.should == 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Invalid auth token'
      result['data'].should be_empty
    end

    it "should return list of companies associated to the current logged in user" do
      company = user.company_users.first.company
      company2 = FactoryGirl.create(:company)
      FactoryGirl.create(:company_user, company: company2, user: user, role: FactoryGirl.create(:role, company: company2))
      get 'companies', auth_token: user.authentication_token, format: :json
      companies = JSON.parse(response.body)
      companies.should =~ [
        {'name' => company.name,  'id' => company.id },
        {'name' => company2.name, 'id' => company2.id}
      ]
      response.should be_success
    end
  end

  describe "GET 'permissions'" do
    let(:company) { user.company_users.first.company }
    it "should return failure for invalid authorization token" do
      get 'permissions', auth_token: 'XXXXXXXXXXXXXXXX',company_id: company.id, format: :json
      response.response_code.should == 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Invalid auth token'
      result['data'].should be_empty
    end

    it "should require the company_id param" do
      company = FactoryGirl.create(:company)
      FactoryGirl.create(:company_user, company: company, user: user, role: FactoryGirl.create(:role, company: company))
      expect{
        get 'permissions', auth_token: user.authentication_token, format: :json
      }.to raise_exception(Apipie::ParamMissing, 'Missing parameter company_id')
    end

    it "should return list of permissions for the current user" do
      company = FactoryGirl.create(:company)
      FactoryGirl.create(:company_user, company: company, user: user, role: FactoryGirl.create(:role, company: company))
      get 'permissions', auth_token: user.authentication_token, company_id: company.id, format: :json
      response.should be_success
      permissions = JSON.parse(response.body)
      permissions.should =~ ["events", "events_add_contacts", "events_add_team_members", "events_contacts", "events_create", "events_create_documents",
        "events_create_expenses", "events_create_photos", "events_create_surveys", "events_create_tasks", "events_deactivate_documents", "events_deactivate_expenses",
        "events_deactivate_photos", "events_deactivate_surveys", "events_delete_contacts", "events_delete_team_members", "events_documents", "events_edit_contacts",
        "events_edit_expenses", "events_edit_surveys", "events_edit_tasks", "events_expenses", "events_deactivate", "events_edit", "events_photos", "events_show", "events_surveys", "events_tasks",
        "events_team_members", "tasks_comments_own", "tasks_comments_team", "tasks_create_comments_own", "tasks_create_comments_team", "tasks_deactivate_own",
        "tasks_deactivate_team", "tasks_edit_own", "tasks_edit_team", "tasks_own", "tasks_team", "venues", "venues_create"]
    end

    it "should return empty list if the user has no permissions" do
      role = FactoryGirl.create(:non_admin_role, company: company,)
      non_admin = FactoryGirl.create(:user, company_users: [FactoryGirl.create(:company_user, company: company, role: role)])

      get 'permissions', auth_token: non_admin.authentication_token, company_id: company.id, format: :json

      response.should be_success
      permissions = JSON.parse(response.body)
      permissions.should =~ []
    end

    it "should return only the permissions given to the user's role" do
      role = FactoryGirl.create(:non_admin_role, company: company,)
      non_admin = FactoryGirl.create(:user, company_users: [FactoryGirl.create(:company_user, company: company, role: role)])

      role.permissions.create({action: :create, subject_class: 'Event'}, without_protection: true)
      role.permissions.create({action: :view_list, subject_class: 'Event'}, without_protection: true)

      get 'permissions', auth_token: non_admin.authentication_token, company_id: company.id, format: :json

      response.should be_success
      permissions = JSON.parse(response.body)
      permissions.should =~ ["events", "events_create"]
    end
  end
end