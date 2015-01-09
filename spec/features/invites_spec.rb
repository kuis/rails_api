require 'rails_helper'

feature 'Invites', search: true, js: true do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company, modules: { 'attendance' => {} }) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { create(:place, name: 'Guillermitos Bar', country: 'CR', city: 'Curridabat', state: 'San Jose', is_custom_place: true, reference: nil) }
  let(:permissions) { [] }
  let(:event) { create(:event, campaign: campaign, place: place) }
  let(:venue) { create(:venue, company: company, place: place) }
  let(:role) { create(:non_admin_role, company: company) }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
    venue
    company_user.places << place
    company_user.campaigns << campaign
    campaign.places << place
    Sunspot.commit
  end

  after do
    Warden.test_reset!
  end

  feature 'in event details' do
    let(:permissions) do
      [[:index_invites, 'Event'],
       [:create_invite, 'Event'],
       [:show, 'Event']]
    end

    scenario 'user can create invites' do
      visit event_path(event)

      click_js_button 'Add Invite'
      within visible_modal do
        select_from_autocomplete 'Search for a place', 'Guillermitos Bar'
        fill_in '# Invitees', with: '100'
        click_js_button 'Create'
      end
      ensure_modal_was_closed

      within '#invites-list' do
        expect(page).to have_content
      end
    end
  end
end
