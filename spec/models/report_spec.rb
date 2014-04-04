# == Schema Information
#
# Table name: reports
#
#  id            :integer          not null, primary key
#  company_id    :integer
#  name          :string(255)
#  description   :text
#  active        :boolean          default(TRUE)
#  created_by_id :integer
#  updated_by_id :integer
#  rows          :text
#  columns       :text
#  values        :text
#  filters       :text
#  sharing       :string(255)      default("owner")
#

require 'spec_helper'

describe Report do
  it { should validate_presence_of(:name) }

  describe "#activate" do
    let(:report) { FactoryGirl.build(:report, active: false) }

    it "should return the active value as true" do
      report.activate!
      report.reload
      report.active.should be_true
    end
  end

  describe "#deactivate" do
    let(:report) { FactoryGirl.build(:report, active: false) }

    it "should return the active value as false" do
      report.deactivate!
      report.reload
      report.active.should be_false
    end
  end

  describe "#accessible_by_user" do
    let(:user) { FactoryGirl.create(:company_user, company: company) }
    let(:company) { FactoryGirl.create(:company)  }
    before{ User.current = user.user }
    it "should return all the reports created by the current user" do
      report = FactoryGirl.create(:report, company: company)
      expect(Report.accessible_by_user(user)).to match_array [report]
    end

    it "should return all the reports shared with everyone by the current user" do
      report = FactoryGirl.create(:report, company: company, sharing: 'everyone')
      other_user = FactoryGirl.create(:company_user, company: company)
      expect(Report.accessible_by_user(user)).to match_array [report]
      expect(Report.accessible_by_user(other_user)).to match_array [report]

      # Should not return reports from other company
      other_company_user = FactoryGirl.create(:company_user, company: FactoryGirl.create(:company))
      expect(Report.accessible_by_user(other_company_user)).to match_array []
    end

    it "should return reports shared with the user's role" do
      report = FactoryGirl.create(:report, company: company,
        sharing: 'custom', sharing_selections: ["role:#{user.role_id}"])
      other_user = FactoryGirl.create(:company_user, company: company, role: user.role)
      expect(Report.accessible_by_user(user)).to match_array [report]
      expect(Report.accessible_by_user(other_user)).to match_array [report]
    end

    it "should return reports shared with the user's role" do
      other_user = FactoryGirl.create(:company_user, company: company, role: user.role)
      team = FactoryGirl.create(:team, company: company)
      team.users << user
      team.users << other_user
      report = FactoryGirl.create(:report, company: company,
        sharing: 'custom', sharing_selections: ["team:#{team.id}", 'company_user:9999999', 'role:9999999'])
      report2 = FactoryGirl.create(:report, company: company)
      other_team_user = FactoryGirl.create(:company_user, company: FactoryGirl.create(:company))
      expect(Report.accessible_by_user(user)).to match_array [report, report2]
      expect(Report.accessible_by_user(other_user)).to match_array [report]
    end

    it "should return reports shared with the user" do
      other_user = FactoryGirl.create(:company_user, company: company, role: user.role)
      team = FactoryGirl.create(:team, company: company)
      team.users << user
      team.users << other_user
      report = FactoryGirl.create(:report, company: company,
        sharing: 'custom', sharing_selections: ["company_user:#{other_user.id}"])
      expect(Report.accessible_by_user(user)).to match_array [report]
      expect(Report.accessible_by_user(other_user)).to match_array [report]
    end
  end

  describe "#columns_totals" do
    let(:company) { FactoryGirl.create(:company) }
    let(:campaign) { FactoryGirl.create(:campaign, name: 'Guaro Cacique 2013', company: company) }
    before do
      Kpi.create_global_kpis
    end

    it "should return the totals for all the values" do
      campaign2 = FactoryGirl.create(:campaign, name: 'Other', company: company)
      FactoryGirl.create(:event, campaign: campaign,  results: { impressions: 100 })
      FactoryGirl.create(:event, campaign: campaign,  results: { impressions: 200 })
      FactoryGirl.create(:event, campaign: campaign2, results: { impressions: 100 })

      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign Name"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"% of column Impressions", "aggregate"=>"sum"}]
      )

      expect(report.report_columns).to match_array ["% of column Impressions"]
      expect(report.columns_totals).to eql [400.0]
    end

    it "should return the totals for the value on each column" do
      place_in_ca = FactoryGirl.create(:place, city: 'Los Angeles', state: 'California')
      place_in_tx = FactoryGirl.create(:place, city: 'Houston', state: 'Texas')
      place_in_az = FactoryGirl.create(:place, city: 'Phoenix', state: 'Arizona')
      campaign2 = FactoryGirl.create(:campaign, name: 'Other', company: company)
      FactoryGirl.create(:event, campaign: campaign,  results: { impressions: 100 }, place: place_in_ca)
      FactoryGirl.create(:event, campaign: campaign,  results: { impressions: 200 }, place: place_in_tx)
      FactoryGirl.create(:event, campaign: campaign2, results: { impressions: 500 }, place: place_in_ca)
      FactoryGirl.create(:event, campaign: campaign,  results: { impressions: 50 }, place: place_in_az)

      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"place:state", "label"=>"State"}, {"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign Name"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"% of column Impressions", "aggregate"=>"sum", "display" => ''}]
      )

      expect(report.report_columns).to match_array ["Arizona||% of column Impressions", "California||% of column Impressions", "Texas||% of column Impressions"]
      expect(report.columns_totals).to eql [50.0, 600.0, 200.0]
    end

    it "should return the totals for each value on each column" do
      place_in_ca = FactoryGirl.create(:place, city: 'Los Angeles', state: 'California')
      place_in_tx = FactoryGirl.create(:place, city: 'Houston', state: 'Texas')
      place_in_az = FactoryGirl.create(:place, city: 'Phoenix', state: 'Arizona')
      campaign2 = FactoryGirl.create(:campaign, name: 'Other', company: company)
      FactoryGirl.create(:event, campaign: campaign,  results: { impressions: 100, interactions: 10 }, place: place_in_ca)
      FactoryGirl.create(:event, campaign: campaign,  results: { impressions: 200, interactions: 20 }, place: place_in_tx)
      FactoryGirl.create(:event, campaign: campaign2, results: { impressions: 500, interactions: 50 }, place: place_in_ca)
      FactoryGirl.create(:event, campaign: campaign,  results: { impressions: 50, interactions: 5 }, place: place_in_az)

      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"place:state", "label"=>"State"}, {"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign Name"}],
        values:  [
            {"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"},
            {"field"=>"kpi:#{Kpi.interactions.id}", "label"=>"Interactions", "aggregate"=>"sum"}
          ]
      )

      expect(report.report_columns).to match_array ["Arizona||Impressions", "Arizona||Interactions", "California||Impressions", "California||Interactions", "Texas||Impressions", "Texas||Interactions"]
      expect(report.columns_totals).to eql [50.0, 5.0, 600.0, 60.0, 200.0, 20.0]
    end
  end

  describe "#fetch_page" do
    let(:company) { FactoryGirl.create(:company) }
    let(:campaign) { FactoryGirl.create(:campaign, name: 'Guaro Cacique 2013', company: company) }
    before do
      Kpi.create_global_kpis
    end
    it "returns nil if report has no rows, values and columns" do
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      report = FactoryGirl.create(:report,
        company: company,
        rows:    [],
        values:  [],
        columns: []
      )
      page = report.fetch_page
      expect(page).to be_nil
    end

    it "returns nil if report has rows but not values and columns" do
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      report = FactoryGirl.create(:report,
        company: company,
        rows:    [{"field"=>"event:start_date", "label"=>"Start date"}]
      )
      page = report.fetch_page
      expect(report.rows).to_not be_empty
      expect(page).to be_nil
    end

    it "returns a line for each different day where a event happens" do
      FactoryGirl.create(:event, start_date: '01/01/2014', end_date: '01/01/2014', campaign: campaign,
        results: {impressions: 100, interactions: 50})
      FactoryGirl.create(:event, start_date: '01/12/2014', end_date: '01/12/2014', campaign: campaign,
        results: {impressions: 200, interactions: 150})
      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"event:start_date", "label"=>"Start date"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
          {"event_start_date"=>"2014/01/01", "values" => [100.00]},
          {"event_start_date"=>"2014/01/12", "values" => [200.00]}
      ]
    end

    it "returns a line for each event's user when adding a user field as a row" do
      user1 = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Nicole', last_name: 'Aldana'))
      user2 = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Nadia', last_name: 'Aldana'))
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      event.users << [user1, user2]
      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"user:first_name", "label"=>"First Name"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"user_first_name"=>"Nadia", "values" => [100.00]},
        {"user_first_name"=>"Nicole", "values" => [100.00]}
      ]
    end

    it "returns a line for each team's user when adding a user field as a row and the team is part of the event" do
      user1 = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Nicole', last_name: 'Aldana'))
      user2 = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Nadia', last_name: 'Aldana'))
      team = FactoryGirl.create(:team, company: company)
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interactions: 300}) # Another event
      team.users << [user1, user2]
      event.teams << team
      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"user:first_name", "label"=>"First Name"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"user_first_name"=>"Nadia", "values" => [100.00]},
        {"user_first_name"=>"Nicole", "values" => [100.00]},
        {"user_first_name"=>nil, "values" => [300.00]}
      ]
    end

    it "returns a line for each team  when adding a team field as a row and the team is part of the event" do
      team = FactoryGirl.create(:team, name: 'Power Rangers', company: company)
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interactions: 300}) # Another event
      event.teams << team
      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"team:name", "label"=>"Team"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"team_name"=>"Power Rangers", "values" => [100.00]}
      ]
    end

    it "returns the correct number of events" do
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interactions: 300}) # Another event
      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.interactions.id}", "label"=>"Interactions"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.events.id}", "label"=>"Events", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [2.00]}
      ]
    end

    it "returns the correct number of promo hours" do
      FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interactions: 300})
      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.interactions.id}", "label"=>"Interactions"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.promo_hours.id}", "label"=>"Promo Hours", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [4.00]}
      ]
    end

    it "returns the correct number of photos" do
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      FactoryGirl.create_list(:attached_asset, 2, attachable: event, asset_type: 'photo')
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interactions: 300})
      FactoryGirl.create_list(:attached_asset, 2, attachable: event, asset_type: 'photo')

      campaign2 = FactoryGirl.create(:campaign, name: 'Zeta', company: company)
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 300, interactions: 300})

      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.interactions.id}", "label"=>"Interactions"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.photos.id}", "label"=>"Photos", "aggregate"=>"count"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [4.00]},
        {"campaign_name"=>campaign2.name, "values" => [0.00]}
      ]
    end

    it "returns the correct number of comments" do
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      FactoryGirl.create_list(:comment, 2, commentable: event)
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interactions: 300})
      FactoryGirl.create_list(:comment, 2, commentable: event)

      campaign2 = FactoryGirl.create(:campaign, name: 'Zeta', company: company)
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 300, interactions: 300})

      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.interactions.id}", "label"=>"Interactions"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.comments.id}", "label"=>"Photos", "aggregate"=>"count"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [4.00]},
        {"campaign_name"=>campaign2.name, "values" => [0.00]}
      ]
    end

    it "returns the correct amount of expenses" do
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      FactoryGirl.create(:event_expense, event: event, amount: 160)
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interactions: 300})
      FactoryGirl.create(:event_expense, event: event, amount: 330)

      campaign2 = FactoryGirl.create(:campaign, name: 'Zeta', company: company)
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 300, interactions: 300})

      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.interactions.id}", "label"=>"Interactions"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.expenses.id}", "label"=>"Expenses", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [490.00]},
        {"campaign_name"=>campaign2.name, "values" => [0.00]}
      ]

      # With COUNT aggregation method
      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.interactions.id}", "label"=>"Interactions"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.expenses.id}", "label"=>"Expenses", "aggregate"=>"count"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [2.00]},
        {"campaign_name"=>campaign2.name, "values" => [0.00]}
      ]

      # With MIN aggregation method
      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.interactions.id}", "label"=>"Interactions"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.expenses.id}", "label"=>"Expenses", "aggregate"=>"min"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [160.00]},
        {"campaign_name"=>campaign2.name, "values" => [0.00]}
      ]

      # With MAX aggregation method
      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.interactions.id}", "label"=>"Interactions"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.expenses.id}", "label"=>"Expenses", "aggregate"=>"max"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [330.00]},
        {"campaign_name"=>campaign2.name, "values" => [0.00]}
      ]
    end

    it "returns a line for each brand portfolio when adding a portfolio field as a row and the event is associated to any " do
      campaign.assign_all_global_kpis
      brand_portfolio1 = FactoryGirl.create(:brand_portfolio, name: 'BP1', company: company)
      brand_portfolio2 = FactoryGirl.create(:brand_portfolio, name: 'BP2', company: company)
      brand = FactoryGirl.create(:brand)
      brand_portfolio1.brands << brand
      brand_portfolio2.brands << brand

      FactoryGirl.create(:event, start_date: '01/01/2014', end_date: '01/01/2014', campaign: campaign,
        results: {impressions: 100, interactions: 50})

      campaign2 = FactoryGirl.create(:campaign, company: company)
      FactoryGirl.create(:event, start_date: '01/12/2014', end_date: '01/12/2014', campaign: campaign2,
        results: {impressions: 200, interactions: 150})

      campaign3 = FactoryGirl.create(:campaign, company: company)
      FactoryGirl.create(:event, start_date: '01/13/2014', end_date: '01/13/2014', campaign: campaign3,
        results: {impressions: 300, interactions: 175})

      # Campaign without brands or brand portfolios
      campaign4 = FactoryGirl.create(:campaign, company: company)
      FactoryGirl.create(:event, start_date: '01/15/2014', end_date: '01/15/2014', campaign: campaign4,
        results: {impressions: 350, interactions: 250})

      # Make both campaigns to be related to the same brand
      campaign.brand_portfolios << brand_portfolio1
      campaign2.brands << brand
      campaign3.brand_portfolios << brand_portfolio2
      campaign2.brand_portfolios << brand_portfolio2

      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"brand_portfolio:name", "label"=>"Portfolio"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"brand_portfolio_name"=>"BP1", "values"=>[300.0]},
        {"brand_portfolio_name"=>"BP2", "values"=>[500.0]},
        {"brand_portfolio_name"=>nil, "values"=>[350.0]}
      ]

      # Filter by a brand portfolio
      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"brand_portfolio:name", "label"=>"Portfolio"}],
        filters: [{"field"=>"brand_portfolio:name", "label"=>"Portfolio"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      report.filter_params = {"brand_portfolio:name" => ['BP1']}
      page = report.fetch_page
      expect(page).to eql [
        {"brand_portfolio_name"=>"BP1", "values"=>[300.0]}
      ]
    end


    it "returns a line for each brand when adding a brand field as a row and the event is associated to any " do
      campaign.assign_all_global_kpis
      brand1 = FactoryGirl.create(:brand, name: 'Brand1')
      brand2 = FactoryGirl.create(:brand, name: 'Brand2')
      brand_portfolio1 = FactoryGirl.create(:brand_portfolio, name: 'BP1', company: company)
      brand_portfolio2 = FactoryGirl.create(:brand_portfolio, name: 'BP2', company: company)
      brand_portfolio1.brands << brand1
      brand_portfolio2.brands << brand1
      brand_portfolio2.brands << brand2

      FactoryGirl.create(:event, start_date: '01/01/2014', end_date: '01/01/2014', campaign: campaign,
        results: {impressions: 100, interactions: 50})

      campaign2 = FactoryGirl.create(:campaign, company: company)
      FactoryGirl.create(:event, start_date: '01/12/2014', end_date: '01/12/2014', campaign: campaign2,
        results: {impressions: 200, interactions: 150})

      campaign3 = FactoryGirl.create(:campaign, company: company)
      FactoryGirl.create(:event, start_date: '01/13/2014', end_date: '01/13/2014', campaign: campaign3,
        results: {impressions: 300, interactions: 175})

      # Campaign without brands or brand portfolios
      campaign4 = FactoryGirl.create(:campaign, company: company)
      FactoryGirl.create(:event, start_date: '01/15/2014', end_date: '01/15/2014', campaign: campaign4,
        results: {impressions: 350, interactions: 250})

      # Make both campaigns to be related to the same brand
      campaign.brands << brand1
      campaign2.brand_portfolios << brand_portfolio1
      campaign3.brands << brand2

      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"brand:name", "label"=>"Portfolio"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"brand_name"=>"Brand1", "values"=>[300.0]},
        {"brand_name"=>"Brand2", "values"=>[300.0]},
        {"brand_name"=>nil, "values"=>[350.0]}
      ]

      # Filter by a brand portfolio
      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"brand_portfolio:name", "label"=>"Portfolio"}],
        filters: [{"field"=>"brand_portfolio:name", "label"=>"Portfolio"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      report.filter_params = {"brand_portfolio:name" => ['BP1']}
      page = report.fetch_page
      expect(page).to eql [
        {"brand_portfolio_name"=>"BP1", "values"=>[300.0]}
      ]
    end

    it "should work when adding fields from users and teams" do
      user = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Green', last_name: 'Ranger'))
      team = FactoryGirl.create(:team, name: 'Power Rangers', company: company)
      team2 = FactoryGirl.create(:team, name: 'Transformers', company: company)
      team.users << user

      # A event with members but no teams
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      event.users << user

      # A event with a team without members
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 200, interactions: 100})
      event.teams << team2

      # A event with a team with members
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interactions: 150})
      event.teams << team

      # A event without teams or members
      FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interactions: 150})
      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"team:name", "label"=>"Team"}, {"field"=>"user:first_name", "label"=>"Team"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"team_name"=>"Power Rangers", "user_first_name"=>"Green", "values" => [300.00]},
        {"team_name"=>"Transformers", "user_first_name"=>nil, "values" => [200.00]},
        {"team_name"=>nil, "user_first_name"=>"Green", "values" => [100.00]},
        {"team_name"=>nil, "user_first_name"=>nil, "values" => [300.00]}
      ]
    end

    it "returns the values for each report's row" do
      user1 = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Nicole', last_name: 'Aldana'))
      user2 = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Nadia', last_name: 'Aldana'))
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      event.users << [user1, user2]
      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"user:last_name", "label"=>"Last Name"}, {"field"=>"user:first_name", "label"=>"First Name"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"user_last_name"=>"Aldana", "user_first_name"=>"Nadia", "values" => [100.00]},
        {"user_last_name"=>"Aldana", "user_first_name"=>"Nicole", "values" => [100.00]}
      ]
    end

    it "correctly handles multiple rows with fields from the event and users" do
      user1 = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Nicole', last_name: 'Aldana'))
      user2 = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Nadia', last_name: 'Aldana'))
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      event.users << [user1, user2]
      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"event:start_date", "label"=>"Start date"}, {"field"=>"user:first_name", "label"=>"First Name"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"event_start_date"=>"2019/01/23", "user_first_name"=>"Nadia", "values" => [100.00]},
        {"event_start_date"=>"2019/01/23", "user_first_name"=>"Nicole", "values" => [100.00]}
      ]
    end

    it "returns a line for each role" do
      user = FactoryGirl.create(:company_user, company: company, role: FactoryGirl.create(:role, name: 'Market Manager'))
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interactions: 300}) # Another event
      event.users << user
      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"role:name", "label"=>"Role"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"role_name"=>"Market Manager", "values" => [100.00]}
      ]
    end

    it "returns a line for each campaign" do
      FactoryGirl.create(:event, campaign: campaign, place: FactoryGirl.create(:place, state: 'Texas', city: 'Houston'),
        results: {impressions: 100, interactions: 50})
      FactoryGirl.create(:event, campaign: campaign, place: FactoryGirl.create(:place, state: 'California', city: 'Los Angeles'),
        results: {impressions: 200, interactions: 75})
      FactoryGirl.create(:event, place: FactoryGirl.create(:place, state: 'California', city: 'San Francisco'),
        campaign: FactoryGirl.create(:campaign, name: 'Ron Centenario FY12', company: company),
        results: {impressions: 300, interactions: 150})
      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"place:state", "label"=>"State"}, {"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(report.report_columns).to match_array ["California||Impressions", "Texas||Impressions"]
      expect(page).to eql [
       {"campaign_name"=>"Guaro Cacique 2013", "values"=>[200.0, 100.0]},
       {"campaign_name"=>"Ron Centenario FY12", "values"=>[300.0, nil]}
      ]

      expect(report.report_columns).to eql ["California||Impressions", "Texas||Impressions"]
    end

    it "should allow display values as a percentage of the column" do
      campaign2 = FactoryGirl.create(:campaign, name: 'Other', company: company)
      FactoryGirl.create(:event, campaign: campaign,  results: { impressions: 100 })
      FactoryGirl.create(:event, campaign: campaign,  results: { impressions: 200 })
      FactoryGirl.create(:event, campaign: campaign2, results: { impressions: 100 })

      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign Name"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"% of column Impressions", "aggregate"=>"sum", "display" => 'perc_of_column'}]
      )

      page = report.fetch_page
      expect(report.report_columns).to match_array ["% of column Impressions"]
      expect(page).to eql [
       {"campaign_name"=>"Guaro Cacique 2013", "values"=>[75.0]},
       {"campaign_name"=>"Other", "values"=>[25.0]}
      ]
    end

    it "should work when adding a table field as a value with the aggregation method 'count'" do
      FactoryGirl.create(:event, campaign: campaign, place: FactoryGirl.create(:place, state: 'Texas', city: 'Houston'),
        results: {impressions: 100, interactions: 50})
      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"place:name", "label"=>"Venue Name", "aggregate"=>"count"}]
      )

      page = report.fetch_page
      expect(page).to eql [
       {"campaign_name"=>"Guaro Cacique 2013", "values"=>[1.0]}
      ]
    end

    it "should work when adding a table field as a value with the aggregation method 'sum'" do
      FactoryGirl.create(:event, campaign: campaign, place: FactoryGirl.create(:place, state: 'Texas', city: 'Houston'),
        results: {impressions: 100, interactions: 50})
      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"place:name", "label"=>"Venue Name", "aggregate"=>"sum"}]
      )

      page = report.fetch_page
      expect(page).to eql [
       {"campaign_name"=>"Guaro Cacique 2013", "values"=>[0.0]}
      ]
    end

    it "should work when adding percentage KPIs as a value" do
      event = FactoryGirl.create(:event, campaign: campaign, place: FactoryGirl.create(:place))
      kpi = FactoryGirl.create(:kpi, company: company, kpi_type: 'percentage', kpis_segments: [
        FactoryGirl.build(:kpis_segment, text: 'Segment 1', ordering: 1),
        FactoryGirl.build(:kpis_segment, text: 'Segment 2', ordering: 2)
      ])
      campaign.add_kpi kpi
      results = event.result_for_kpi(kpi)
      results.first.value = 25
      results.second.value = 75
      event.save # Save the event results

      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{kpi.id}", "label"=>"Segmented Field", "aggregate"=>"avg"}]
      )

      page = report.fetch_page
      expect(report.report_columns).to eql ["Segmented Field: Segment 1", "Segmented Field: Segment 2"]
      expect(page).to eql [
       {"campaign_name"=>"Guaro Cacique 2013", "values"=>[25.0, 75.0]}
      ]
    end

    it "should work when adding count KPIs as a value" do
      kpi = FactoryGirl.create(:kpi, company: company, kpi_type: 'count', kpis_segments: [
        FactoryGirl.build(:kpis_segment, text: 'Yes', ordering: 1),
        FactoryGirl.build(:kpis_segment, text: 'No', ordering: 2)
      ])
      campaign.add_kpi kpi

      event = FactoryGirl.create(:event, campaign: campaign, place: FactoryGirl.create(:place))
      event.result_for_kpi(kpi).value = kpi.kpis_segments.first.id
      event.save # Save the event results

      event = FactoryGirl.create(:event, campaign: campaign, place: FactoryGirl.create(:place))
      event.result_for_kpi(kpi).value = kpi.kpis_segments.second.id
      event.save # Save the event results

      event = FactoryGirl.create(:event, campaign: campaign, place: FactoryGirl.create(:place))
      event.result_for_kpi(kpi).value = kpi.kpis_segments.second.id
      event.save # Save the event results

      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{kpi.id}", "label"=>"Count Field", "aggregate"=>"count"}]
      )

      page = report.fetch_page
      expect(report.report_columns).to eql ["Count Field: Yes", "Count Field: No"]
      expect(page).to eql [
       {"campaign_name"=>"Guaro Cacique 2013", "values"=>[1.0, 2.0]}
      ]
    end

    it "should accept kpis as rows" do
      FactoryGirl.create(:event, campaign: campaign,
        results: {impressions: 123, interactions: 50})

      FactoryGirl.create(:event, campaign: campaign,
        results: {impressions: 321, interactions: 25})

      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"kpi:#{Kpi.interactions.id}", "label"=>"Interactions"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"kpi_#{Kpi.interactions.id}"=>"25", "values" => [321.0]},
        {"kpi_#{Kpi.interactions.id}"=>"50", "values" => [123.0]}
      ]
    end

    it "should accept kpis as columns" do
      FactoryGirl.create(:event, campaign: campaign, place: FactoryGirl.create(:place, name: 'Bar 1'),
        results: {impressions: 123, interactions: 50})

      FactoryGirl.create(:event, campaign: campaign, place: FactoryGirl.create(:place, name: 'Bar 2'),
        results: {impressions: 321, interactions: 25})

      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}, {"field"=>"kpi:#{Kpi.interactions.id}", "label"=>"Interactions"}],
        rows:    [{"field"=>"place:name", "label"=>"Interactions"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"place_name"=>"Bar 1", "values" => [nil, 123.0]},
        {"place_name"=>"Bar 2", "values" => [321.0, nil]}
      ]
    end

    describe "with columns" do
      it "returns all the values grouped by venue state" do
        place_in_ca = FactoryGirl.create(:place, city: 'Los Angeles', state: 'California')
        place_in_tx = FactoryGirl.create(:place, city: 'Houston', state: 'Texas')
        FactoryGirl.create(:event, start_date: '01/01/2014', end_date: '01/01/2014', campaign: campaign,
          place: place_in_ca, results: {impressions: 100, interactions: 50})
        FactoryGirl.create(:event, start_date: '01/12/2014', end_date: '01/12/2014', campaign: campaign,
          place: place_in_tx, results: {impressions: 200, interactions: 150})
        report = FactoryGirl.create(:report,
          company: company,
          columns: [{"field"=>"place:state", "label"=>"State"}, {"field"=>"values", "label"=>"Values"}],
          rows:    [{"field"=>"event:start_date", "label"=>"Start date"}],
          values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"},
                    {"field"=>"kpi:#{Kpi.interactions.id}", "label"=>"Interactions", "aggregate"=>"avg"}]
        )
        page = report.fetch_page
        expect(report.report_columns).to match_array ["California||Impressions", "California||Interactions", "Texas||Impressions", "Texas||Interactions"]
        expect(page).to eql [
            {"event_start_date"=>"2014/01/01", "values" => [100.00, 50.0, nil, nil]},
            {"event_start_date"=>"2014/01/12", "values" => [nil, nil, 200.00, 150.0]}
        ]

        # Test to_csv
        csv = CSV.parse(report.to_csv)
        expect(csv[0]).to eql ["Start date", "California/Impressions", "California/Interactions", "Texas/Impressions", "Texas/Interactions"]
        expect(csv[1]).to eql ["2014/01/01", "100.0", "50.0", nil, nil]
        expect(csv[2]).to eql ["2014/01/12", nil, nil, "200.0", "150.0"]
      end

      it "returns a line for each team  when adding a team field as a row and the team is part of the event" do
        team = FactoryGirl.create(:team, name: 'Power Rangers', company: company)
        event = FactoryGirl.create(:event, campaign: campaign, start_date: '01/01/2014', end_date: '01/01/2014',
          results: {impressions: 100, interactions: 50})
        event.teams << team
        report = FactoryGirl.create(:report,
          company: company,
          columns: [{"field"=>"team:name", "label"=>"Team"}, {"field"=>"values", "label"=>"Values"}],
          rows:    [{"field"=>"event:start_date", "label"=>"Start date"}],
          values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
        )
        page = report.fetch_page
        expect(page).to eql [
          {"event_start_date"=>"2014/01/01", "values" => [100.00]}
        ]
      end
    end
  end

  describe "filtering" do
    let(:company) { FactoryGirl.create(:company) }
    let(:campaign) { FactoryGirl.create(:campaign, name: 'Guaro Cacique 2013', company: company) }
    before { Kpi.create_global_kpis }

    it "can filter results by a range for numeric KPIs" do
      campaign.assign_all_global_kpis
      kpi = FactoryGirl.create(:kpi, company: company, kpi_type: 'number')
      campaign.add_kpi kpi
      event1 = FactoryGirl.create(:event, start_date: '01/01/2014', end_date: '01/01/2014', campaign: campaign,
        results: {impressions: 100, interactions: 50})
      event1.result_for_kpi(kpi).value = 200
      event1.save

      event2 = FactoryGirl.create(:event, start_date: '01/12/2014', end_date: '01/12/2014', campaign: campaign,
        results: {impressions: 200, interactions: 150})

      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"event:start_date", "label"=>"Start date"}],
        filters: [{"field"=>"kpi:#{kpi.id}", "label"=>"A Numeric Filter"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      # With no filtering
      page = report.fetch_page
      expect(report.fetch_page).to eql [
          {"event_start_date"=>"2014/01/01", "values" => [100.00]},
          {"event_start_date"=>"2014/01/12", "values" => [200.00]}
      ]

      report.filter_params = {"kpi:#{kpi.id}" => {'min' => '100', 'max' => '300'}}
      expect(report.fetch_page).to eql [
          {"event_start_date"=>"2014/01/01", "values" => [100.00]}
      ]
    end

    it "can filter results by selected kpi segments" do
      campaign.assign_all_global_kpis
      kpi = FactoryGirl.create(:kpi, company: company, kpi_type: 'count')
      seg1 = FactoryGirl.create(:kpis_segment, kpi: kpi)
      seg2 = FactoryGirl.create(:kpis_segment, kpi: kpi)
      campaign.add_kpi kpi
      event1 = FactoryGirl.create(:event, start_date: '01/01/2014', end_date: '01/01/2014', campaign: campaign,
        results: {impressions: 100, interactions: 50})
      event1.result_for_kpi(kpi).value = seg1.id
      event1.save

      event2 = FactoryGirl.create(:event, start_date: '01/12/2014', end_date: '01/12/2014', campaign: campaign,
        results: {impressions: 200, interactions: 150})
      event2.result_for_kpi(kpi).value = seg2.id
      event2.save

      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"event:start_date", "label"=>"Start date"}],
        filters: [{"field"=>"kpi:#{kpi.id}", "label"=>"A Numeric Filter"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      # With no filtering
      page = report.fetch_page
      expect(report.fetch_page).to eql [
          {"event_start_date"=>"2014/01/01", "values" => [100.00]},
          {"event_start_date"=>"2014/01/12", "values" => [200.00]}
      ]

      report.filter_params = {"kpi:#{kpi.id}" => [seg1.id.to_s]}
      expect(report.fetch_page).to eql [
          {"event_start_date"=>"2014/01/01", "values" => [100.00]}
      ]

      report.filter_params = {"kpi:#{kpi.id}" => [seg1.id.to_s, seg2.id.to_s]}
      expect(report.fetch_page).to eql [
          {"event_start_date"=>"2014/01/01", "values" => [100.00]},
          {"event_start_date"=>"2014/01/12", "values" => [200.00]}
      ]
    end

    it "can filter by number of events" do
      # Events on campaing
      FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interactions: 300})

      # Events on other campaing
      campaign2 = FactoryGirl.create(:campaign, name: 'Zeta 2014', company: company)
      campaign2.assign_all_global_kpis
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 100, interactions: 50})
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 200, interactions: 100})
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 300, interactions: 300})

      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.events.id}", "label"=>"Events"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [400.00]},
        {"campaign_name"=>campaign2.name, "values" => [600.00]}
      ]

      # with filter
      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.events.id}", "label"=>"Events"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      report.filter_params = {"kpi:#{Kpi.events.id}" => {'min' => '1', 'max' => '2'}}

      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [400.00]}
      ]
    end

    it "can be filtered by promo hours" do
      # Events on campaing
      FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interactions: 300})

      # Events on other campaing
      campaign2 = FactoryGirl.create(:campaign, name: 'Zeta 2014', company: company)
      campaign2.assign_all_global_kpis
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 100, interactions: 50})
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 200, interactions: 100})
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 300, interactions: 300})

      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.promo_hours.id}", "label"=>"Promo Hours"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [400.00]},
        {"campaign_name"=>campaign2.name, "values" => [600.00]}
      ]

      # with filter
      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.promo_hours.id}", "label"=>"Promo Hours"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      report.filter_params = {"kpi:#{Kpi.promo_hours.id}" => {'min' => '1', 'max' => '4'}}

      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [400.00]}
      ]
    end

    it "can be filtered by number of comments" do
      # Events on campaing
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      FactoryGirl.create_list(:comment, 2, commentable: event)
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interactions: 300})
      FactoryGirl.create_list(:comment, 2, commentable: event)

      # Events on other campaing
      campaign2 = FactoryGirl.create(:campaign, name: 'Zeta 2014', company: company)
      campaign2.assign_all_global_kpis
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 100, interactions: 50})
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 200, interactions: 100})
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 300, interactions: 300})

      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.comments.id}", "label"=>"Comments"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [400.00]},
        {"campaign_name"=>campaign2.name, "values" => [600.00]}
      ]

      # with filter
      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.comments.id}", "label"=>"Comments"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      report.filter_params = {"kpi:#{Kpi.comments.id}" => {'min' => '1', 'max' => '4'}}

      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [400.00]}
      ]
    end

    it "can be filtered by number of photos" do
      # Events on campaing
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      FactoryGirl.create_list(:attached_asset, 2, attachable: event, asset_type: 'photo')
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interactions: 300})
      FactoryGirl.create_list(:attached_asset, 2, attachable: event, asset_type: 'photo')

      # Events on other campaing
      campaign2 = FactoryGirl.create(:campaign, name: 'Zeta 2014', company: company)
      campaign2.assign_all_global_kpis
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 100, interactions: 50})
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 200, interactions: 100})
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 300, interactions: 300})

      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.photos.id}", "label"=>"Photos"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [400.00]},
        {"campaign_name"=>campaign2.name, "values" => [600.00]}
      ]

      # with filter
      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.photos.id}", "label"=>"Photos"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      report.filter_params = {"kpi:#{Kpi.photos.id}" => {'min' => '1', 'max' => '4'}}

      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [400.00]}
      ]
    end

    it "can be filtered by amount of expenses" do
      # Events on campaing
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interactions: 50})
      FactoryGirl.create(:event_expense, amount: 100, event: event)
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interactions: 300})
      FactoryGirl.create(:event_expense, amount: 200, event: event)

      # Events on other campaing
      campaign2 = FactoryGirl.create(:campaign, name: 'Zeta 2014', company: company)
      campaign2.assign_all_global_kpis
      event = FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 100, interactions: 50})
      FactoryGirl.create(:event_expense, amount: 1000, event: event)
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 200, interactions: 100})
      FactoryGirl.create(:event, campaign: campaign2, results: {impressions: 300, interactions: 300})

      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.expenses.id}", "label"=>"Comments"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [400.00]},
        {"campaign_name"=>campaign2.name, "values" => [600.00]}
      ]

      # with filter
      report = FactoryGirl.create(:report,
        company: company,
        filters: [{"field"=>"kpi:#{Kpi.expenses.id}", "label"=>"Comments"}],
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      report.filter_params = {"kpi:#{Kpi.expenses.id}" => {'min' => '1', 'max' => '300'}}

      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [400.00]}
      ]

      report.filter_params = {"kpi:#{Kpi.expenses.id}" => {'min' => '1', 'max' => '1300'}}
      page = report.fetch_page
      expect(page).to eql [
        {"campaign_name"=>campaign.name, "values" => [400.00]},
        {"campaign_name"=>"Zeta 2014", "values"=>[100.0]}
      ]
    end

    it "can filter results by brands" do
      campaign.assign_all_global_kpis
      brand1 = FactoryGirl.create(:brand, name: 'Brand1')
      brand2 = FactoryGirl.create(:brand, name: 'Brand2')
      brand_portfolio1 = FactoryGirl.create(:brand_portfolio, name: 'BP1', company: company)
      brand_portfolio1.brands << brand1

      FactoryGirl.create(:event, start_date: '01/01/2014', end_date: '01/01/2014', campaign: campaign,
        results: {impressions: 100, interactions: 50})

      campaign2 = FactoryGirl.create(:campaign, company: company)
      FactoryGirl.create(:event, start_date: '01/12/2014', end_date: '01/12/2014', campaign: campaign2,
        results: {impressions: 200, interactions: 150})

      campaign3 = FactoryGirl.create(:campaign, company: company)
      FactoryGirl.create(:event, start_date: '01/13/2014', end_date: '01/13/2014', campaign: campaign3,
        results: {impressions: 300, interactions: 175})

      # Campaign without brands or brand portfolios
      campaign4 = FactoryGirl.create(:campaign, company: company)
      FactoryGirl.create(:event, start_date: '01/15/2014', end_date: '01/15/2014', campaign: campaign4,
        results: {impressions: 350, interactions: 250})

      # Make both campaigns to be related to the same brand
      campaign.brands << brand1
      campaign2.brand_portfolios << brand_portfolio1
      campaign3.brands << brand2
      campaign2.brands << brand2

      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"event:start_date", "label"=>"Start date"}],
        filters: [{"field"=>"brand:name", "label"=>"Brand"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      # With no filtering
      page = report.fetch_page
      expect(report.fetch_page).to eql [
          {"event_start_date"=>"2014/01/01", "values" => [100.00]},
          {"event_start_date"=>"2014/01/12", "values" => [200.00]},
          {"event_start_date"=>"2014/01/13", "values" => [300.00]},
          {"event_start_date"=>"2014/01/15", "values" => [350.00]}
      ]

      report.filter_params = {"brand:name" => ['Brand1']}
      expect(report.fetch_page).to eql [
          {"event_start_date"=>"2014/01/01", "values" => [100.00]},
          {"event_start_date"=>"2014/01/12", "values" => [200.00]}
      ]

      report.filter_params = {"brand:name" => ['Brand2']}
      expect(report.fetch_page).to eql [
          {"event_start_date"=>"2014/01/12", "values" => [200.00]},
          {"event_start_date"=>"2014/01/13", "values" => [300.0]}
      ]

      report.filter_params = {"brand:name" => ['Brand1', 'Brand2']}
      expect(report.fetch_page).to eql [
          {"event_start_date"=>"2014/01/01", "values" => [100.00]},
          {"event_start_date"=>"2014/01/12", "values" => [200.00]},
          {"event_start_date"=>"2014/01/13", "values" => [300.00]}
      ]
    end

    it "can filter results by brand portfolios" do
      campaign.assign_all_global_kpis
      brand_portfolio1 = FactoryGirl.create(:brand_portfolio, name: 'BP1', company: company)
      brand_portfolio2 = FactoryGirl.create(:brand_portfolio, name: 'BP2', company: company)
      brand = FactoryGirl.create(:brand)
      brand_portfolio1.brands << brand
      brand_portfolio2.brands << brand

      FactoryGirl.create(:event, start_date: '01/01/2014', end_date: '01/01/2014', campaign: campaign,
        results: {impressions: 100, interactions: 50})

      campaign2 = FactoryGirl.create(:campaign, company: company)
      FactoryGirl.create(:event, start_date: '01/12/2014', end_date: '01/12/2014', campaign: campaign2,
        results: {impressions: 200, interactions: 150})

      campaign3 = FactoryGirl.create(:campaign, company: company)
      FactoryGirl.create(:event, start_date: '01/13/2014', end_date: '01/13/2014', campaign: campaign3,
        results: {impressions: 300, interactions: 175})

      # Campaign without brands or brand portfolios
      campaign4 = FactoryGirl.create(:campaign, company: company)
      FactoryGirl.create(:event, start_date: '01/15/2014', end_date: '01/15/2014', campaign: campaign4,
        results: {impressions: 350, interactions: 250})

      # Make both campaigns to be related to the same brand
      campaign.brand_portfolios << brand_portfolio1
      campaign2.brands << brand
      campaign3.brand_portfolios << brand_portfolio2
      campaign2.brand_portfolios << brand_portfolio2

      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"event:start_date", "label"=>"Start date"}],
        filters: [{"field"=>"brand_portfolio:name", "label"=>"Brand Portfolio"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      # With no filtering
      page = report.fetch_page
      expect(report.fetch_page).to eql [
          {"event_start_date"=>"2014/01/01", "values" => [100.00]},
          {"event_start_date"=>"2014/01/12", "values" => [200.00]},
          {"event_start_date"=>"2014/01/13", "values" => [300.00]},
          {"event_start_date"=>"2014/01/15", "values" => [350.00]}
      ]

      report.filter_params = {"brand_portfolio:name" => ['BP1']}
      expect(report.fetch_page).to eql [
          {"event_start_date"=>"2014/01/01", "values" => [100.00]},
          {"event_start_date"=>"2014/01/12", "values" => [200.00]}
      ]

      report.filter_params = {"brand_portfolio:name" => ['BP1', 'BP2']}
      expect(report.fetch_page).to eql [
          {"event_start_date"=>"2014/01/01", "values" => [100.00]},
          {"event_start_date"=>"2014/01/12", "values" => [200.00]},
          {"event_start_date"=>"2014/01/13", "values" => [300.00]}
      ]
    end

    it "can filter results by a range of dates" do
      campaign.assign_all_global_kpis
      kpi = FactoryGirl.create(:kpi, company: company, kpi_type: 'count')
      seg1 = FactoryGirl.create(:kpis_segment, kpi: kpi)
      seg2 = FactoryGirl.create(:kpis_segment, kpi: kpi)
      campaign.add_kpi kpi
      event1 = FactoryGirl.create(:event, start_date: '01/01/2014', end_date: '01/01/2014', campaign: campaign,
        results: {impressions: 100, interactions: 50})
      event1.result_for_kpi(kpi).value = seg1.id
      event1.save

      event2 = FactoryGirl.create(:event, start_date: '01/12/2014', end_date: '01/12/2014', campaign: campaign,
        results: {impressions: 200, interactions: 150})
      event2.result_for_kpi(kpi).value = seg2.id
      event2.save

      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"event:start_date", "label"=>"Start date"}],
        filters: [{"field"=>"event:start_date", "label"=>"Start Date"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      # With no filtering
      page = report.fetch_page
      expect(report.fetch_page).to eql [
          {"event_start_date"=>"2014/01/01", "values" => [100.00]},
          {"event_start_date"=>"2014/01/12", "values" => [200.00]}
      ]

      report.filter_params = {"event:start_date" => {'start' => '01/01/2014', 'end' => '01/01/2014'}}
      expect(report.fetch_page).to eql [
          {"event_start_date"=>"2014/01/01", "values" => [100.00]}
      ]

      report.filter_params = {"event:start_date" => {'start' => '01/01/2014', 'end' => '01/12/2014'}}
      expect(report.fetch_page).to eql [
          {"event_start_date"=>"2014/01/01", "values" => [100.00]},
          {"event_start_date"=>"2014/01/12", "values" => [200.00]}
      ]
    end
  end

  describe "#first_row_values_for_page" do
    let(:company) { FactoryGirl.create(:company) }
    let(:campaign) { FactoryGirl.create(:campaign, name: 'Guaro Cacique 2013', company: company) }
    before do
      Kpi.create_global_kpis
    end
    it "returns all the venues names" do
      FactoryGirl.create(:event, campaign: campaign, place: FactoryGirl.create(:place, state: 'Texas', city: 'Houston'),
        results: {impressions: 100})
      FactoryGirl.create(:event, campaign: campaign, place: FactoryGirl.create(:place, state: 'California', city: 'Los Angeles'),
        results: {impressions: 200})
      FactoryGirl.create(:event, place: FactoryGirl.create(:place, state: 'California', city: 'San Francisco'),
        campaign: FactoryGirl.create(:campaign, name: 'Ron Centenario FY12', company: company),
        results: {impressions: 300})
      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"place:state", "label"=>"State"}, {"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"campaign:name", "label"=>"Campaign"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      values = report.first_row_values_for_page
      expect(values).to match_array ["Guaro Cacique 2013", "Ron Centenario FY12"]

      # Test to_csv
      csv = CSV.parse(report.to_csv)
      expect(csv[0]).to eql ['Campaign', 'California/Impressions', 'Texas/Impressions']
      expect(csv[1]).to eql ['Guaro Cacique 2013', '200.0', '100.0']
      expect(csv[2]).to eql ['Ron Centenario FY12', '300.0', nil]
    end

    it "returns all the campaign names" do
      FactoryGirl.create(:event, campaign: campaign,
        place: FactoryGirl.create(:place, name: 'Bar Texano', state: 'Texas', city: 'Houston'),
        results: {impressions: 100})
      FactoryGirl.create(:event, campaign: campaign,
        place: FactoryGirl.create(:place, name: 'Texas Restaurant', state: 'California', city: 'Los Angeles'),
        results: {impressions: 200})
      FactoryGirl.create(:event, campaign: campaign,
        place: FactoryGirl.create(:place, name: 'Texas Bar & Grill', state: 'California', city: 'San Francisco'),
        results: {impressions: 300})
      report = FactoryGirl.create(:report,
        company: company,
        columns: [{"field"=>"campaign:name", "label"=>"State"}, {"field"=>"values", "label"=>"Values"}],
        rows:    [{"field"=>"place:name", "label"=>"Venue"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      values = report.first_row_values_for_page
      expect(values).to match_array ["Bar Texano", "Texas Bar & Grill", 'Texas Restaurant']

      # Test to_csv
      csv = CSV.parse(report.to_csv)
      expect(csv[0]).to eql ['Venue', 'Guaro Cacique 2013/Impressions']
      expect(csv[1]).to eql ["Bar Texano", '100.0']
      expect(csv[2]).to eql ['Texas Bar & Grill', '300.0']
      expect(csv[3]).to eql ['Texas Restaurant', '200.0']
    end
  end
end
