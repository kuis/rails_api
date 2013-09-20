require 'spec_helper'

describe Analysis::CampaignsReportController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
    #Kpi.create_global_kpis
  end

  describe "GET 'index'" do
    it "should load all the current campaign " do
      campaigns = []
      campaigns.push FactoryGirl.create(:campaign, company: @company)
      campaigns.push FactoryGirl.create(:inactive_campaign, company: @company)

      get 'index'

      response.should be_success
      assigns(:campaigns).should == campaigns
    end
  end

  describe "GET 'index'" do
    let(:campaign) { FactoryGirl.create(:campaign, company: @company) }

    it "should render the campaign report" do
      get 'report', report: { campaign_id: campaign.to_param }, format: :js
      response.should be_success
    end

    it "should assign the correct scope to @events_scope" do
      Kpi.create_global_kpis
      events = FactoryGirl.create_list(:approved_event, 3, company: @company, campaign: campaign)
      FactoryGirl.create(:event, company: @company, campaign: campaign)
      FactoryGirl.create(:approved_event, company: @company, campaign_id: campaign.id + 1)
      FactoryGirl.create(:approved_event, company_id: @company.id+1, campaign_id: campaign.id + 1)

      get 'report', report: { campaign_id: campaign.to_param }, format: :js

      response.should be_success
      assigns(:events_scope).should =~ events
    end

    it "should load all the campaign's goals into @goals" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      goals = [
        FactoryGirl.create(:goal, goalable: campaign, kpi_id: Kpi.impressions.id),
        FactoryGirl.create(:goal, goalable: campaign, kpi_id: Kpi.events.id),
        FactoryGirl.create(:goal, goalable: campaign, kpi_id: Kpi.interactions.id)
      ]

      get 'report', report: { campaign_id: campaign.to_param }, format: :js

      response.should be_success
      assigns(:goals).should =~ goals
    end



  end


end