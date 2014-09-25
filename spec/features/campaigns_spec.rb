require 'rails_helper'

feature 'Campaigns', js: true do

  let(:user) { create(:user, company_id: create(:company).id, role_id: create(:role).id) }

  before do
    Warden.test_mode!
    @company = user.companies.first
    sign_in user
  end

  after do
    Warden.test_reset!
  end

  feature 'Index', search: true  do
    scenario 'should display a table with the campaigns' do
      campaigns = [
        create(:campaign, name: 'Cacique FY13', description: 'test campaign for guaro cacique', company: @company),
        create(:campaign, name: 'Centenario FY12', description: 'ron Centenario test campaign', company: @company)
      ]
      Sunspot.commit
      visit campaigns_path

      within('ul#campaigns-list') do
        # First Row
        within('li:nth-child(1)') do
          expect(page).to have_content(campaigns[0].name)
          expect(page).to have_content(campaigns[0].description)
        end
        # Second Row
        within('li:nth-child(2)') do
          expect(page).to have_content(campaigns[1].name)
          expect(page).to have_content(campaigns[1].description)
        end
      end
    end

    scenario 'should allow user to deactivate campaigns' do
      create(:campaign, name: 'Cacique FY13', description: 'test campaign for guaro cacique', company: @company)
      Sunspot.commit
      visit campaigns_path

      expect(page).to have_content('Cacique FY13')
      within('ul#campaigns-list li:nth-child(1)') do
        click_js_link('Deactivate')
      end

      confirm_prompt 'Are you sure you want to deactivate this campaign?'

      expect(page).to have_no_content('Cacique FY13')
    end

    scenario 'should allow user to activate campaigns' do
      campaign = create(:inactive_campaign, name: 'Cacique FY13', description: 'test campaign for guaro cacique', company: @company)
      Sunspot.commit
      visit campaigns_path

      filter_section('ACTIVE STATE').unicheck('Inactive')
      filter_section('ACTIVE STATE').unicheck('Active')

      expect(page).to have_content('Cacique FY13')
      within('ul#campaigns-list li:nth-child(1)') do
        expect(page).to have_content('Cacique FY13')
        click_js_link('Activate')
      end
      expect(page).to have_no_content('Cacique FY13')
    end

    scenario 'allows the user to create a new campaign' do
      porfolio = create(:brand_portfolio, name: 'Test portfolio', company: @company)
      visit campaigns_path

      click_js_button 'New Campaign'

      within('form#new_campaign') do
        fill_in 'Name', with: 'new campaign name'
        fill_in 'Description', with: 'new campaign description'
        fill_in 'Start date', with: '01/22/2013'
        fill_in 'End date', with: '01/22/2014'
        select_from_chosen('Test portfolio', from: 'Brand portfolios', match: :first)
        click_js_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'new campaign name') # Wait for the page to load
      campaign = Campaign.last
      expect(page).to have_selector('h2', text: 'new campaign name')
      expect(page).to have_selector('div.description-data', text: 'new campaign description')
      expect(campaign.start_date).to eql Date.parse('2013-01-22')
      expect(campaign.end_date).to eql Date.parse('2014-01-22')
    end
  end

  feature 'Details page', js: true do
    scenario 'GET show should display the campaign details page' do
      campaign = create(:campaign, name: 'Some Campaign', description: 'a campaign description', company: @company)
      visit campaign_path(campaign)
      expect(page).to have_selector('h2', text: 'Some Campaign')
      expect(page).to have_selector('div.description-data', text: 'a campaign description')
    end

    scenario 'allows the user to activate/deactivate a campaign' do
      campaign = create(:campaign, name: 'Some Campaign', description: 'a campaign description', company: @company)
      visit campaign_path(campaign)
      within('.links-data') do
        click_js_link('Deactivate')
      end

      confirm_prompt 'Are you sure you want to deactivate this campaign?'

      within('.links-data') do
        click_js_link('Activate')
        expect(page).to have_link('Deactivate') # test the link have changed
      end
    end

    scenario 'allows the user to edit the campaign' do
      campaign = create(:campaign, company: @company)
      visit campaign_path(campaign)

      within('.links-data') { click_js_button 'Edit Campaign' }

      within("form#edit_campaign_#{campaign.id}") do
        fill_in 'Name', with: 'edited campaign name'
        fill_in 'Description', with: 'edited campaign description'
        click_js_button 'Save'
      end

      # find('h2', text: 'edited campaign name') # Wait for the page to reload
      expect(page).to have_selector('h2', text: 'edited campaign name')
      expect(page).to have_selector('div.description-data', text: 'edited campaign description')
    end

    scenario 'should be able to assign areas to the campaign' do
      Kpi.create_global_kpis
      campaign = create(:campaign, company: @company)
      area = create(:area, name: 'San Francisco Area', company: @company)
      area2 = create(:area, name: 'Los Angeles Area', company: @company)
      visit campaign_path(campaign)

      tab = open_tab('Places')

      click_js_link 'Add Places'

      within visible_modal do
        fill_in 'place-search-box', with: 'San'
        expect(page).to have_selector("li#area-#{area.id}")
        expect(page).to have_no_selector("li#area-#{area2.id}")
        expect(page).to have_content('San Francisco Area')
        expect(page).to have_no_content('Los Angeles Area')
        find("#area-#{area.id}").click_js_link('Add Area')
        expect(page).to have_no_selector("#area-#{area.id}") # The area was removed from the available areas list
      end
      close_modal

      # Re-open the modal to make sure it's not added again to the list
      click_js_link 'Add Places'

      within visible_modal do
        expect(page).to have_no_selector("#area-#{area.id}") # The area does not longer appear on the list after it was added to the campaign
        expect(page).to have_selector("#area-#{area2.id}")
      end
      close_modal

      within tab do
        # Ensure the area now appears on the list of areas
        expect(page).to have_content('San Francisco Area')

        # Test the area removal
        click_js_link 'Remove Area'
        expect(page).to have_no_content('San Francisco Area')
      end
    end

    scenario 'should be able to deactivate places from areas assigned to the campaign' do
      Kpi.create_global_kpis
      campaign = create(:campaign, company: @company)
      area = create(:area, name: 'San Francisco Area', company: @company)
      place1 = create(:place, name: 'One place name')
      place2 = create(:place, name: 'Another place name')
      area.places << [place1, place2]

      campaign.areas << [area]
      visit campaign_path(campaign)

      tab = open_tab('Places')

      within tab do
        expect(page).to have_content('San Francisco Area')
        find('a[data-original-title="Customize area"]').click # tooltip changes the title
      end

      within visible_modal do
        expect(page).to have_content('Customize San Francisco Area')
        expect(page).to have_content 'One place name'
        expect(page).to have_content 'Another place name'
        fill_in 'q', with: 'one'
        expect(page).not_to have_content 'Another place name'
        find("li#area-campaign-place-#{place1.id}").click_js_link 'Deactivate'
        expect(page).to have_selector("li#area-campaign-place-#{place1.id}.inactive")
      end

      expect(campaign.areas_campaigns.find_by(area_id: area.id).exclusions).to eql [place1.id]
    end

    feature 'Add KPIs', search: false do

      feature 'with a non admin user', search: false do
        let(:company) { create(:company) }
        let(:user) { create(:user, company: company, role_id: create(:non_admin_role, company: company).id) }
        let(:company_user) { user.company_users.first }

        scenario 'User without permissions cannot add KPIs' do
          company_user.role.permissions.create(action: :show, subject_class: 'Campaign')
          company_user.role.permissions.create(action: :view_kpis, subject_class: 'Campaign')

          campaign = create(:campaign, company: company)
          visit campaign_path(campaign)

          open_tab('KPIs')

          expect(page).to_not have_content('Add KPI')
        end
      end

      scenario 'Add existing KPI to campaign' do
        Kpi.create_global_kpis
        campaign = create(:campaign, company: @company)

        visit campaign_path(campaign)

        tab = open_tab('KPIs')

        click_js_link 'Add KPI'

        within visible_modal do
          fill_in 'Search', with: 'Gender'
          expect(page).to have_content('Gender')
          expect(page).to have_no_content('Events')
          click_js_link('Add KPI')
          expect(page).to have_no_content('Gender') # The KPI was removed from the available KPIs list
        end
        close_modal

        click_js_link 'Add KPI'

        within visible_modal do
          expect(page).to have_no_content('Gender') # The KPI does not longer appear on the list after it was added to the campaign
          expect(page).to have_content('Comments')
        end
        close_modal

        within tab do
          # Ensure the KPI now appears on the list of KPIs
          expect(page).to have_content('Gender')
        end
      end

      scenario 'Add a new KPI to campaign and set the goal' do
        Kpi.create_global_kpis
        campaign = create(:campaign, company: @company)

        visit campaign_path(campaign)

        tab = open_tab('KPIs')

        click_js_link 'Add KPI'

        within visible_modal do
          click_js_link 'Create New KPI'
        end

        within visible_modal do
          fill_in 'Name', with: 'My Custom KPI'
          fill_in 'Description', with: 'My custom KPI description'
          select_from_chosen('Count', from: 'Kpi type', match: :first)
          click_js_link 'Add a segment'
          fill_in 'Segment name', with: 'Option 1'
          select_from_chosen('Dropdown', from: 'Capture mechanism', match: :first)
          click_js_button 'Create'
        end
        ensure_modal_was_closed

        kpi = Kpi.last
        within '#global-kpis' do
          expect(page).to have_content('My Custom KPI')
          expect(page).to have_content('My custom KPI description')
          hover_and_click('li#campaign-kpi-' + kpi.id.to_s, 'Edit')
        end

        within visible_modal do
          fill_in 'Goal', with: '223311'
          click_js_button 'Save'
        end

        ensure_modal_was_closed

        within '#global-kpis' do
          expect(page).to have_content('223311.0')
        end
      end

      scenario 'Get errors when create a new KPI without enough segments for the selected capture mechanism' do
        campaign = create(:campaign, company: @company)

        visit campaign_path(campaign)

        click_js_link 'KPIs'

        click_js_link 'Add KPI'

        within visible_modal do
          click_js_link 'Create New KPI'
        end

        within visible_modal do
          fill_in 'Name', with: 'My Custom KPI'
          fill_in 'Description', with: 'my custom kpi description'
          select_from_chosen('Count', from: 'Kpi type', match: :first)
          click_js_link 'Add a segment'
          fill_in 'Segment name', with: 'Option 1'
          select_from_chosen('Radio', from: 'Capture mechanism', match: :first)
          click_js_button 'Create'
          expect(page).to have_content('You need to add at least 2 segments for the selected capture mechanism')
        end
      end
    end

    feature 'Remove KPIs', search: false do
      scenario 'Remove existing KPI from campaign' do
        Kpi.create_global_kpis
        campaign = create(:campaign, company: @company)
        kpi = create(:kpi, name: 'My Custom KPI', description: 'My custom kpi description', kpi_type: 'number', capture_mechanism: 'currency', company: @company)
        campaign.add_kpi kpi

        visit campaign_path(campaign)

        open_tab('KPIs')

        within '#global-kpis' do
          expect(page).to have_content('My Custom KPI')
          hover_and_click('li#campaign-kpi-' + kpi.id.to_s, 'Remove')
        end

        confirm_prompt 'Please confirm you want to remove this KPI?'

        within '#global-kpis' do
          expect(page).to have_no_content('My Custom KPI')
        end

        # Ensure that Campaign-KPI association was removed
        visit campaign_path(campaign)

        open_tab('KPIs')

        within '#global-kpis' do
          expect(page).to have_no_content('My Custom KPI')
        end
      end
    end

    feature 'Edit custom KPIs', search: false do

      feature 'with a non admin user', search: false do
        let(:company) { create(:company) }
        let(:user) { create(:user, company: company, role_id: create(:non_admin_role, company: company).id) }
        let(:company_user) { user.company_users.first }
        let(:campaign) { create(:campaign, company: company) }
        let(:kpi) { create(:kpi, name: 'My Custom KPI', description: 'my custom kpi description', kpi_type: 'number', capture_mechanism: 'currency', company: company) }

        scenario 'User without permissions cannot edit Custom KPIs' do
          Kpi.create_global_kpis
          company_user.role.permissions.create(action: :show, subject_class: 'Campaign')
          company_user.role.permissions.create(action: :view_kpis, subject_class: 'Campaign')

          campaign.add_kpi(kpi)

          visit campaign_path(campaign)

          within '#global-kpis' do
            expect(page).to have_content('My Custom KPI')
            hover_and_click('li#campaign-kpi-' + kpi.id.to_s, 'Edit')
          end

          within visible_modal do
            expect(page).to have_content('You are not authorized to perform this action')
          end
        end

        scenario 'User without permissions to edit Custom KPIs and permission to edit goals' do
          Kpi.create_global_kpis
          company_user.role.permissions.create(action: :show, subject_class: 'Campaign')
          company_user.role.permissions.create(action: :view_kpis, subject_class: 'Campaign')
          company_user.role.permissions.create(action: :edit_kpi_goals, subject_class: 'Campaign')

          campaign.add_kpi(kpi)
          create(:goal, goalable: campaign, kpi: kpi, value: 100)

          visit campaign_path(campaign)

          within '#global-kpis' do
            expect(page).to have_content('My Custom KPI')
            expect(page).to have_content('100.0')
            expect(page).to have_content('my custom kpi description')
            hover_and_click('li#campaign-kpi-' + kpi.id.to_s, 'Edit')
          end

          within visible_modal do
            find_field('Name', disabled: true)
            find_field('Description', disabled: true)
            find_field('Kpi type', visible: false, disabled: true)
            find_field('Capture mechanism', visible: false, disabled: true)
            fill_in 'Goal', with: '350'
            click_js_button 'Save'
          end
          ensure_modal_was_closed

          within '#global-kpis' do
            expect(page).to have_content('350.0')
          end
        end
      end

      scenario 'Edit Custom KPI' do
        Kpi.create_global_kpis
        campaign = create(:campaign, company: @company)
        kpi = create(:kpi, name: 'My Custom KPI', description: 'my custom kpi description', kpi_type: 'number', capture_mechanism: 'currency', company: @company)
        campaign.add_kpi(kpi)
        create(:goal, goalable: campaign, kpi: kpi, value: 100)

        visit campaign_path(campaign)

        click_js_link 'KPIs'

        within '#global-kpis' do
          expect(page).to have_content('My Custom KPI')
          hover_and_click('li#campaign-kpi-' + kpi.id.to_s, 'Edit')
        end

        within visible_modal do
          fill_in 'Name', with: 'My Modified KPI'
          fill_in 'Description', with: 'my modified kpi description'
          select_from_chosen('Count', from: 'Kpi type', match: :first)
          click_js_link 'Add a segment'
          fill_in 'Segment name', with: 'Option 1'
          select_from_chosen('Dropdown', from: 'Capture mechanism', match: :first)
          click_js_button 'Save'
        end
        ensure_modal_was_closed

        within '#global-kpis' do
          expect(page).to have_content('My Modified KPI')
          expect(page).to have_content('my modified kpi description')
          hover_and_click('li#campaign-kpi-' + kpi.id.to_s, 'Edit')
        end

        within visible_modal do
          fill_in 'Goal', with: '350'
          click_js_button 'Save'
        end
        ensure_modal_was_closed

        within '#global-kpis' do
          expect(page).to have_content('350.0')
        end
      end
    end

    feature 'Activity Types', search: false do
      scenario 'Set goals for Activity Types' do
        campaign = create(:campaign, company: @company)
        activity_type = create(:activity_type, name: 'Activity Type #1', company: @company)

        visit campaign_path(campaign)

        click_js_link 'KPIs'

        click_js_link 'Add KPI'

        within visible_modal do
          expect(page).to have_content('Add KPI')
          fill_in 'Search', with: 'Activity Type #1'
          within '.select-list-table-wrapper' do
            expect(page).to have_content('Activity Type #1')
            hover_and_click 'li', 'Add Activity Type'
            expect(page).not_to have_content('Activity Type #1')
          end
        end
        close_modal

        # Reopen the modal and make sure the activity type is not there
        click_js_link 'Add KPI'
        within visible_modal do
          expect(page).to have_content('Add KPI')
          fill_in 'Search', with: 'Activity Type #1'
          within '.select-list-table-wrapper' do
            expect(page).not_to have_content('Activity Type #1')
          end
        end
        close_modal

        within '#global-kpis' do
          expect(page).to have_content('Activity Type #1')
          hover_and_click('li#campaign-activity-type-' + activity_type.id.to_s, 'Edit')
        end

        within visible_modal do
          fill_in 'Goal', with: '123'
          click_js_button 'Save'
        end

        ensure_modal_was_closed

        within '#global-kpis' do
          expect(page).to have_content('123.0')

          # Remove the activity type from the list
          expect(page).to have_content('Activity Type #1')
          hover_and_click('li#campaign-activity-type-' + activity_type.id.to_s, 'Remove')

          expect(page).not_to have_content('Activity Type #1')
        end

        # Reopen the modal and make sure the activity type is againg available to be added
        click_js_link 'Add KPI'
        within visible_modal do
          expect(page).to have_content('Add KPI')
          fill_in 'Search', with: 'Activity Type #1'
          within '.select-list-table-wrapper' do
            expect(page).to have_content('Activity Type #1')
          end
        end
      end
    end
  end
end
