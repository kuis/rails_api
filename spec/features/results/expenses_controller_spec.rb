require 'spec_helper'

feature "Results Expenses Page", js: true, search: true  do

  before do
    Kpi.destroy_all
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    sign_in @user
  end

  after do
    Warden.test_reset!
  end

  let(:campaign){ FactoryGirl.create(:campaign, name: 'First Campaign', company: @company) }

  feature "Event Expenses index", js: true, search: true  do
    scenario "GET index should display a table with the expenses" do
      Kpi.create_global_kpis
      campaign.add_kpi(Kpi.expenses)
      event = FactoryGirl.build(:approved_event, campaign: campaign, company: @company, start_date: "08/21/2013", end_date: "08/21/2013", start_time: '8:00pm', end_time: '11:00pm', place: FactoryGirl.create(:place, name: 'Place 1'))
      event.event_expenses.build(name: 'Expense #1 Event #1', event_id: event.id, amount: 10)
      event.save

      event2 = FactoryGirl.build(:approved_event, campaign: campaign, company: @company, start_date: "08/25/2013", end_date: "08/25/2013", start_time: '9:00am', end_time: '10:00am', place: FactoryGirl.create(:place, name: 'Place 2'))
      event2.event_expenses.build(name: 'Expense #1 Event #2', event_id: event.id, amount: 20)
      event2.save

      Sunspot.commit
      visit results_expenses_path

      within("ul#expenses-list") do
        # First Row
        within("li:nth-child(1)") do
          expect(page).to have_content('First Campaign')
          expect(page).to have_content('WED Aug 21, 2013, 8:00 PM - 11:00 PM')
          expect(page).to have_content('Place 1, New York City, NY, 12345')
          expect(page).to have_content('$10.00')
        end
        # Second Row
        within("li:nth-child(2)") do
          expect(page).to have_content('First Campaign')
          expect(page).to have_content('SUN Aug 25, 2013, 9:00 AM - 10:00 AM')
          expect(page).to have_content('Place 2, New York City, NY, 12345')
          expect(page).to have_content('$20.00')
        end
      end
      expect(page).to have_content('TOTAL:$30.00')
    end

    scenario "GET index should display a table with the expenses" do
      Kpi.create_global_kpis
      campaign.add_kpi(Kpi.expenses)
      event = FactoryGirl.build(:approved_event, campaign: campaign, company: @company, start_date: "08/21/2013", end_date: "08/21/2013", start_time: '8:00pm', end_time: '11:00pm')
      event.event_expenses.build(name: 'Expense #1 Event #1', event_id: event.id, amount: 10)
      event.save

      Sunspot.commit
      visit results_expenses_path

      click_link("event-link-#{event.id}")

      current_path.should == event_path(event.id)
    end
  end
end