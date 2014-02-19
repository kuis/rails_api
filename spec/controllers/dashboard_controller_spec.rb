require 'spec_helper'

describe DashboardController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
    Kpi.create_global_kpis
  end

  it "should render all modules" do
    get 'index'
    response.should be_success
    response.should render_template('incomplete_tasks')
    response.should render_template('kpi_trends')
    response.should render_template('upcoming_events')
    response.should render_template('recent_photos')
    response.should render_template('recent_comments')
    response.should render_template('venue_performance')
    response.should render_template('campaign_overview')
  end
end