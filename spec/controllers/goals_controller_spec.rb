require 'spec_helper'

describe GoalsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:kpi) {FactoryGirl.create(:kpi, company: @company)}
  let(:campaign) {FactoryGirl.create(:campaign, company: @company)}
  let(:company_user) {FactoryGirl.create(:company_user, company: @company)}
  let(:area) {FactoryGirl.create(:area, company: @company)}
  let(:activity_type){ FactoryGirl.create(:activity_type, company: @company) }

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', company_user_id: company_user.to_param, format: :js
      response.should be_success
      response.should render_template('new')
      response.should render_template('form')
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', company_user_id: company_user.to_param, goal: {value: '100', kpi_id: kpi.id}, format: :js
      response.should be_success
      response.should render_template('create')
    end

    it "should create a goal for the company user" do
      lambda {
        post 'create', company_user_id: company_user.to_param, goal: {value: '100', kpi_id: kpi.id, title: 'Goal Title', start_date: '01/31/2012', due_date: '01/31/2013'}, format: :js
      }.should change(Goal, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)

      goal = Goal.last
      goal.parent.should be_nil
      goal.goalable.should == company_user
      goal.value.should == 100
      goal.kpi_id.should == kpi.id
      goal.title.should == 'Goal Title'
      goal.start_date.should == Time.zone.local(2012, 01, 31).to_date
      goal.due_date.should   == Time.zone.local(2013, 01, 31).to_date
    end

    it "should create a goal for the company user in a given campaign" do
      lambda {
        post 'create', goal: {parent_id: campaign.id, parent_type: 'Campaign', goalable_id: company_user.id, goalable_type: 'CompanyUser', value: '100', kpi_id: kpi.id, title: 'Goal Title', start_date: '01/31/2012', due_date: '01/31/2013'}, format: :json
      }.should change(Goal, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)

      goal = Goal.last
      goal.parent.should == campaign
      goal.goalable.should == company_user
      goal.value.should == 100
      goal.kpi_id.should == kpi.id
      goal.title.should == 'Goal Title'
      goal.start_date.should == Time.zone.local(2012, 01, 31).to_date
      goal.due_date.should   == Time.zone.local(2013, 01, 31).to_date
    end

    it "should create an activity type goal for an area in a given campaign" do
      lambda {
        post 'create', goal: {parent_id: campaign.id, parent_type: 'Campaign', goalable_id: area.id, goalable_type: 'Area', value: '55', activity_type_id: activity_type.id}, format: :json
      }.should change(Goal, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)

      goal = Goal.last
      goal.parent.should == campaign
      goal.goalable.should == area
      goal.value.should == 55
      goal.activity_type_id.should == activity_type.id
    end

    it "should create an activity type goal for a company user in a given campaign" do
      lambda {
        post 'create', goal: {parent_id: campaign.id, parent_type: 'Campaign', goalable_id: company_user.id, goalable_type: 'CompanyUser', value: '66', activity_type_id: activity_type.id}, format: :json
      }.should change(Goal, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)

      goal = Goal.last
      goal.parent.should == campaign
      goal.goalable.should == company_user
      goal.value.should == 66
      goal.activity_type_id.should == activity_type.id
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', company_user_id: company_user.to_param, goal: {start_date: '99/99/9999'}, format: :js
      }.should_not change(Goal, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:goal).errors.count > 0
    end
  end

  describe "GET 'edit'" do
    it "returns http success" do
      goal = FactoryGirl.create(:goal, goalable: company_user, activity_type_id: activity_type.id)
      get 'edit', company_user_id: company_user.to_param, id: goal.to_param, format: :js
      response.should be_success
      assigns(:company_user).should == company_user
      assigns(:goal).should == goal
    end
  end

  describe "PUT 'update'" do
    it "should update the goal attributes for the company user" do
      goal = FactoryGirl.create(:goal, goalable: company_user, activity_type_id: activity_type.id)
      expect {
        put 'update', company_user_id: company_user.to_param, id: goal.to_param, goal: {value: '100', kpi_id: kpi.id, title: 'Goal Title', start_date: '01/31/2012', due_date: '01/31/2013'}, format: :js
      }.to_not change(Goal, :count)
      response.should be_success
      response.should render_template(:update)
      response.should_not render_template(:form_dialog)

      goal.reload
      goal.parent.should be_nil
      goal.goalable.should == company_user
      goal.value.should == 100
      goal.kpi_id.should == kpi.id
      goal.title.should == 'Goal Title'
      goal.start_date.should == Time.zone.local(2012, 01, 31).to_date
      goal.due_date.should   == Time.zone.local(2013, 01, 31).to_date
    end

    it "should update the goal value for the company user in a given campaign" do
      goal = FactoryGirl.create(:goal, goalable: company_user, activity_type_id: activity_type.id)
      expect {
        put 'update', id: goal.to_param, goal: {parent_id: campaign.id, parent_type: 'Campaign', goalable_id: company_user.id, goalable_type: 'CompanyUser', value: '110', kpi_id: kpi.id}, format: :json
      }.to_not change(Goal, :count)
      response.should be_success
      response.should render_template(:update)
      response.should_not render_template(:form_dialog)

      goal.reload
      goal.parent.should == campaign
      goal.goalable.should == company_user
      goal.value.should == 110
      goal.kpi_id.should == kpi.id
    end

    it "should update an activity type goal for an area in a given campaign" do
      area_goal = FactoryGirl.create(:goal, goalable: area, activity_type_id: activity_type.id)
      area_goal.save
      expect {
        post 'update', id: area_goal.to_param, goal: {parent_id: campaign.id, parent_type: 'Campaign', goalable_id: area.id, goalable_type: 'Area', value: '78', activity_type_id: activity_type.id}, format: :json
      }.to_not change(Goal, :count)
      response.should be_success
      response.should render_template(:update)
      response.should_not render_template(:form_dialog)

      area_goal.reload
      area_goal.parent.should == campaign
      area_goal.goalable.should == area
      area_goal.value.should == 78
      area_goal.activity_type_id.should == activity_type.id
    end

    it "should update an activity type goal for a company user in a given campaign" do
      user_goal = FactoryGirl.create(:goal, goalable: company_user, activity_type_id: activity_type.id)
      user_goal.save
      expect {
        post 'update', id: user_goal.to_param, goal: {parent_id: campaign.id, parent_type: 'Campaign', goalable_id: company_user.id, goalable_type: 'CompanyUser', value: '88', activity_type_id: activity_type.id}, format: :json
      }.to_not change(Goal, :count)
      response.should be_success
      response.should render_template(:update)
      response.should_not render_template(:form_dialog)

      user_goal.reload
      user_goal.parent.should == campaign
      user_goal.goalable.should == company_user
      user_goal.value.should == 88
      user_goal.activity_type_id.should == activity_type.id
    end
  end

end