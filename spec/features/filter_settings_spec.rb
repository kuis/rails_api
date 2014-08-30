require 'rails_helper'

feature "Filter Settings", search: true, js: true do
  let(:company) { FactoryGirl.create(:company) }
  let(:campaign) { FactoryGirl.create(:campaign, company: company) }
  let(:user) { FactoryGirl.create(:user, company: company, role_id: FactoryGirl.create(:role).id) }
  let(:company_user) { user.company_users.first }

  before do
    Warden.test_mode!
    sign_in user
  end

  after do
    Warden.test_reset!
  end

  feature "filter settings" do
    let(:campaign1) { FactoryGirl.create(:campaign, name: 'Campaign 1', company: company) }
    let(:campaign2) { FactoryGirl.create(:campaign, name: 'Campaign 2', company: company) }
    let(:brand1) { FactoryGirl.create(:brand, name: 'Brand 1', company: company) }
    let(:brand2) { FactoryGirl.create(:brand, name: 'Brand 2', company: company, active: false) }
    let(:event1) { FactoryGirl.create(:submitted_event, campaign: campaign1) }
    let(:event2) { FactoryGirl.create(:late_event, campaign: campaign2) }
    let(:user1) { FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, first_name: 'Roberto', last_name: 'Gomez'), company: company) }
    let(:user2) { FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, first_name: 'Mario', last_name: 'Moreno'), company: company) }
    let(:user3) { FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, first_name: 'Eugenio', last_name: 'Derbez'), company: company, active: false) }

    scenario "allows to configure filter settings" do
      event1.users << user1
      event1.users << user2
      event1.users << user3
      event2.users << user2
      campaign1.brands << brand1
      campaign1.brands << brand2
      campaign2.brands << brand2
      Sunspot.commit

      visit events_path

      within '#collection-list-filters' do
        expect(page).to have_content('CAMPAIGNS')
        expect(page).to have_content('Campaign 1')
        expect(page).to have_content('Campaign 2')
        expect(page).to have_content('BRANDS')
        expect(page).to have_content('Brand 1')
        expect(page).to_not have_content('Brand 2')
        expect(page).to have_content('PEOPLE')
        expect(page).to_not have_content('Eugenio Derbez')
        expect(page).to have_content('Mario Moreno')
        expect(page).to have_content('Roberto Gomez')
        expect(page).to have_content('Test User')
        expect(page).to have_content('EVENT STATUS')
        expect(page).to have_content('ACTIVE STATE')
        find('.settings-for-filters').trigger('click')
      end

      within visible_modal do
        expect(page).to have_content('CAMPAIGNS')
        expect(page).to have_content('BRANDS')
        expect(page).to have_content('AREAS')
        expect(page).to have_content('USERS')
        expect(page).to have_content('TEAMS')
        unicheck('Inactive')
        click_button 'Save'
      end
      ensure_modal_was_closed

      within '#collection-list-filters' do
        expect(page).to_not have_content('CAMPAIGNS')
        expect(page).to have_content('BRANDS')
        expect(page).to_not have_content('Brand 1')
        expect(page).to have_content('Brand 2')
        expect(page).to have_content('PEOPLE')
        expect(page).to have_content('Eugenio Derbez')
        expect(page).to_not have_content('Mario Moreno')
        expect(page).to_not have_content('Roberto Gomez')
        expect(page).to_not have_content('Test User')
        expect(page).to have_content('EVENT STATUS')
        expect(page).to have_content('ACTIVE STATE')
      end
    end
  end
end