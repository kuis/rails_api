require 'rails_helper'

feature 'Attendance', js: true, search: true do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company, modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance', 'settings' => { 'attendance_display' => '1' } } }) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { create(:place, name: 'Guillermitos Bar', country: 'CR', city: 'Curridabat', state: 'San Jose', is_custom_place: true, reference: nil) }
  let(:area) { create(:area, name: 'California', company: company) }
  let(:permissions) { [] }
  let(:event) { create(:late_event, campaign: campaign, company: company, place: place) }

  before do
    add_permissions permissions
    sign_in user
  end

  shared_examples_for 'a user that can create invites' do
    scenario 'cannot view the attendance module if not invitations were created' do
      visit event_path(event)
      expect(page).to_not have_selector('h5', text: 'ATTENDANCE')
      expect(page).to have_button('Add Activity')
    end

    scenario 'can view the attendance module if invites were created' do
      create(:invite, event: event, venue: event.venue)
      visit event_path(event)
      expect(page).to have_selector('h5', text: 'ATTENDANCE')
      expect(page).to have_button('Add Activity')
    end

    scenario 'can create and edit an invite when attendance display is set as Venue' do
      visit event_path(event)
      create_invite account: 'Guillermitos Bar', invites: 12, type: 'venue'

      within '#invites-list' do
        expect(page).to have_content('Guillermitos Bar')
        expect(page).to have_content('No Jameson Locals')
        expect(page).to have_content('No Top 100')
        expect(page).to have_content('12 Invites')
        expect(page).to have_content('0 RSVPs')
        expect(page).to have_content('0 Attendees')
      end

      # Edit the invite
      hover_and_click resource_item(1, list: '#invites-list'), 'Edit'

      within visible_modal do
        fill_in '# Invites', with: '20'
        fill_in '# RSVPs', with: '8'
        fill_in '# Attendes', with: '14'

        click_js_button 'Save'
      end
      ensure_modal_was_closed

      within '#invites-list' do
        expect(page).to have_content('Guillermitos Bar')
        expect(page).to have_content('No Jameson Locals')
        expect(page).to have_content('No Top 100')
        expect(page).to have_content('20 Invites')
        expect(page).to have_content('8 RSVPs')
        expect(page).to have_content('14 Attendees')
      end
    end

    scenario 'can create and edit an invite when attendance display is set as Market' do
      campaign.update_attributes(modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance', 'settings' => { 'attendance_display' => '2' } } })

      visit event_path(event)
      create_invite account: 'California', invites: 10, type: 'market'

      within '#invites-list' do
        expect(page).to have_content('California')
        expect(page).to_not have_content('No Jameson Locals')
        expect(page).to_not have_content('No Top 100')
        expect(page).to have_content('10 Invites')
        expect(page).to have_content('0 RSVPs')
        expect(page).to have_content('0 Attendees')
      end

      # Edit the invite
      hover_and_click resource_item(1, list: '#invites-list'), 'Edit Invite'
      within visible_modal do
        fill_in '# Invites', with: '15'
        fill_in '# RSVPs', with: '6'
        fill_in '# Attendes', with: '9'

        click_js_button 'Save'
      end
      ensure_modal_was_closed

      within '#invites-list' do
        expect(page).to have_content('California')
        expect(page).to_not have_content('No Jameson Locals')
        expect(page).to_not have_content('No Top 100')
        expect(page).to have_content('15 Invites')
        expect(page).to have_content('6 RSVPs')
        expect(page).to have_content('9 Attendees')
      end
    end
  end

  shared_examples_for 'a user that can deactivate invites' do
    scenario 'can deactivate invites from the attendance table' do
      create(:invite, venue: event.venue, event: event)
      visit event_path(event)

      expect(page).to have_selector('#invites-list .resource-item')

      hover_and_click resource_item(1, list: '#invites-list'), 'Deactivate Attendance Record'

      confirm_prompt 'Are you sure you want to deactivate this attendance record?'

      expect(page).to have_no_selector('#invites-list .resource-item')
    end
  end

  shared_examples_for 'a user that can download invites' do
    scenario 'can export as csv' do
      visit event_path(event)
      create_invite account: 'Guillermitos Bar', invites: 12, type: 'venue'

      click_js_link 'Download'
      click_js_link 'Download as XLS'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end

      ensure_modal_was_closed
      expect(ListExport.last).to have_rows([
        ['ACCOUNT', 'JAMESON LOCALS', 'TOP 100', 'INVITES', 'RSVPs', 'ATTENDEES'],
        ['Guillermitos Bar', 'NO', 'NO', '12', '0', '0']
      ])
    end

    scenario 'can export individual as csv' do
      campaign.update_attributes(modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance', 'settings' => { 'attendance_display' => '2' } } })

      visit event_path(event)
      create_invite account: 'California', invites: 12, type: 'market'

      click_js_link 'Download'
      click_js_link 'Download individual to XLS'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end

      ensure_modal_was_closed
      expect(ListExport.last).to have_rows([
        ['MARKET', 'REGISTRANT ID', 'DATE ADDED', 'EMAIL', 'MOBILE PHONE', 'MOBILE SIGN UP',
         'FIRST NAME', 'LAST NAME', 'ATTENDED PREVIOUS BARTENDER BALL', 'OPT IN TO FUTURE COMMUNICATION',
         'PRIMARY REGISTRANT ID', 'BARTENDER HOW LONG', 'BARTENDER ROLE', 'DATE OF BIRTH', 'ZIP CODE']
      ])
    end

    scenario 'can export aggregate as csv' do
      campaign.update_attributes(modules: { 'attendance' => { 'field_type' => 'module', 'name' => 'attendance', 'settings' => { 'attendance_display' => '2' } } })

      visit event_path(event)
      create_invite account: 'California', invites: 12, type: 'market'

      click_js_link 'Download'
      click_js_link 'Download aggregate to XLS'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end

      ensure_modal_was_closed
      expect(ListExport.last).to have_rows([
        ['MARKET', 'INVITES', 'RSVPs', 'ATTENDEES'],
        ['California', '12', '0', '0']
      ])
    end
  end

  feature 'admin user' do
    let(:role) { create(:role, company: company) }

    it_behaves_like 'a user that can create invites' do
      before { area.places << place }
      before { campaign.areas << area }
    end

    it_behaves_like 'a user that can deactivate invites'
    it_behaves_like 'a user that can download invites' do
      before { area.places << place }
      before { campaign.areas << area }
    end
  end

  feature 'non admin user' do
    let(:role) { create(:non_admin_role, company: company) }

    it_should_behave_like 'a user that can create invites' do
      before { area.places << place }
      before { campaign.areas << area }
      before { company_user.campaigns << campaign }
      before { company_user.places << place }
      before { company_user.areas << area }
      let(:permissions) { [[:index_invites, 'Event'], [:create_invite, 'Event'], [:edit_invite, 'Event'], [:show, 'Event']] }
    end

    it_should_behave_like 'a user that can deactivate invites' do
      before { company_user.campaigns << campaign }
      before { company_user.places << place }
      let(:permissions) { [[:index_invites, 'Event'], [:deactivate_invite, 'Event'], [:show, 'Event']] }
    end

    it_should_behave_like 'a user that can download invites' do
      before { area.places << place }
      before { campaign.areas << area }
      before { company_user.campaigns << campaign }
      before { company_user.places << place }
      before { company_user.areas << area }
      let(:permissions) { [[:index_invites, 'Event'], [:create_invite, 'Event'], [:show, 'Event']] }
    end
  end

  def create_invite(account: nil, invites: 12, type: 'venue')
    Sunspot.commit
    click_js_button 'Add Activity'
    within visible_modal do
      choose('Invitation')
      click_js_button 'Create'
    end
    ensure_modal_was_closed

    select_from_autocomplete 'Search for a place', account if type == 'venue'
    select_from_chosen account, from: 'Market' if type == 'market'
    wait_for_ajax
    fill_in '# Invites', with: invites
    click_button 'Submit'

    expect(page).to have_content('Thank You!')
    click_link 'Finish'
  end
end
