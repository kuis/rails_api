require 'spec_helper'

describe Analysis::ReportsHelper do
  before do
    @company = FactoryGirl.create(:company)
    @company_user = FactoryGirl.create(:company_user, company: @company)
  end

  describe "#each_events_goal" do
    it "should return the goals results for each campaign KPI and Activity Type" do
      place = FactoryGirl.create(:place)
      activity_type1 = FactoryGirl.create(:activity_type, company: @company)
      activity_type2 = FactoryGirl.create(:activity_type, company: @company)
      kpi_impressions = FactoryGirl.create(:kpi, name: 'Impressions', kpi_type: 'number', capture_mechanism: 'integer', company: @company)
      kpi_events = FactoryGirl.create(:kpi, name: 'Events', kpi_type: 'events_count', capture_mechanism: '', company: @company)
      kpi_interactions = FactoryGirl.create(:kpi, name: 'Interactions', kpi_type: 'number', capture_mechanism: 'integer', company: @company)

      campaign = FactoryGirl.create(:campaign, company: @company)
      campaign.add_kpi kpi_impressions
      campaign.add_kpi kpi_events
      campaign.add_kpi kpi_interactions
      campaign.activity_types << activity_type1
      campaign.activity_types << activity_type2

      goals = [
        FactoryGirl.create(:goal, goalable: campaign, kpi: kpi_impressions, value: '100'),
        FactoryGirl.create(:goal, goalable: campaign, kpi: kpi_events, value: '20'),
        FactoryGirl.create(:goal, goalable: campaign, kpi: kpi_interactions, value: '400'),
        FactoryGirl.create(:goal, goalable: campaign, kpi: nil, activity_type_id: activity_type1.id, value: '5'),
        FactoryGirl.create(:goal, goalable: campaign, kpi: nil, activity_type_id: activity_type2.id, value: '10')
      ]

      event = FactoryGirl.create(:approved_event, company: @company, campaign: campaign, place: place)
      event.result_for_kpi(kpi_impressions).value=50
      event.result_for_kpi(kpi_interactions).value=160
      event.save
      FactoryGirl.create(:activity, activity_type: activity_type1, activitable: event, company_user: @company_user, campaign: campaign)
      FactoryGirl.create(:activity, activity_type: activity_type2, activitable: event, company_user: @company_user, campaign: campaign)

      helper.instance_variable_set(:@events_scope, Event.where(id: event.id))
      helper.instance_variable_set(:@campaign, campaign)
      helper.instance_variable_set(:@goals, goals)

      results = helper.each_events_goal

      results[goals[0].id][:goal].kpi_id.should == kpi_impressions.id
      results[goals[0].id][:goal].goalable_id.should == campaign.id
      results[goals[0].id][:completed_percentage].should == 50.0
      results[goals[0].id][:remaining_percentage].should == 50.0
      results[goals[0].id][:remaining_count].should == 50.0
      results[goals[0].id][:total_count].should == 50
      results[goals[0].id][:submitted].should == 0

      results[goals[1].id][:goal].kpi_id.should == kpi_events.id
      results[goals[1].id][:goal].goalable_id.should == campaign.id
      results[goals[1].id][:completed_percentage].should == 5.0
      results[goals[1].id][:remaining_percentage].should == 95.0
      results[goals[1].id][:remaining_count].should == 19.0
      results[goals[1].id][:total_count].should == 1
      results[goals[1].id][:submitted].should == 0

      results[goals[2].id][:goal].kpi_id.should == kpi_interactions.id
      results[goals[2].id][:goal].goalable_id.should == campaign.id
      results[goals[2].id][:completed_percentage].should == 40.0
      results[goals[2].id][:remaining_percentage].should == 60.0
      results[goals[2].id][:remaining_count].should == 240.0
      results[goals[2].id][:total_count].should == 160
      results[goals[2].id][:submitted].should == 0

      results[goals[3].id][:goal].activity_type_id.should == activity_type1.id
      results[goals[3].id][:goal].goalable_id.should == campaign.id
      results[goals[3].id][:completed_percentage].should == 20.0
      results[goals[3].id][:remaining_percentage].should == 80.0
      results[goals[3].id][:remaining_count].should == 4.0
      results[goals[3].id][:total_count].should == 1
      results[goals[3].id][:submitted].should == 0

      results[goals[4].id][:goal].activity_type_id.should == activity_type2.id
      results[goals[4].id][:goal].goalable_id.should == campaign.id
      results[goals[4].id][:completed_percentage].should == 10.0
      results[goals[4].id][:remaining_percentage].should == 90.0
      results[goals[4].id][:remaining_count].should == 9.0
      results[goals[4].id][:total_count].should == 1
      results[goals[4].id][:submitted].should == 0
    end
  end
end