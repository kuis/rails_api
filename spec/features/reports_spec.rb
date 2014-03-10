require 'spec_helper'

feature "Reports", js: true do
  before do
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    sign_in @user
    @company = @user.companies.first
  end

  after do
    Warden.test_reset!
  end

  feature "Create a report" do
    scenario 'user is redirected to the report build page after creation' do
      visit results_reports_path

      click_js_button 'New report'

      expect {
        within visible_modal do
          fill_in 'Name', with: 'new report name'
          fill_in 'Description', with: 'new report description'
          click_button 'Create'
        end
        ensure_modal_was_closed
      }.to change(Report, :count).by(1)
      report = Report.last

      expect(current_path).to eql(results_report_path(report))
    end
  end

  scenario "allows the user to activate/deactivate reports" do
    FactoryGirl.create(:report, name: 'Events by Venue',
      description: 'a resume of events by venue',
      active: true, company: @company)

    visit results_reports_path

    within reports_list do
      expect(page).to have_content('Events by Venue')
      hover_and_click 'li', 'Deactivate'
    end

    confirm_prompt "Are you sure you want to deactivate this report?"

    within reports_list do
      expect(page).to have_no_content('Events by Venue')
    end
  end

  scenario "allows the user to edit reports name and description" do
    report = FactoryGirl.create(:report, name: 'My Report',
      description: 'Description of my report',
      active: true, company: @company)

    visit results_reports_path

    within reports_list do
      expect(page).to have_content('My Report')
      hover_and_click 'li', 'Edit'
    end

    within visible_modal do
      fill_in 'Name', with: 'Edited Report Name'
      fill_in 'Description', with: 'Edited Report Description'
      click_js_button 'Save'
    end

    within reports_list do
      expect(page).to have_selector('b', text: 'Edited Report Name')
      expect(page).to have_selector('p', text: 'Edited Report Description')
    end
  end

  feature "run view" do
    before do
      @report = FactoryGirl.create(:report, name: 'My Report',
        description: 'Description of my report',
        active: true, company: @company)
      page.driver.resize(1024, 1500)
    end

    scenario "allows the user to modify an existing custom report" do
      FactoryGirl.create(:kpi, name: 'Kpi #1', company: @company)

      visit results_report_path(@report)

      click_link 'Edit'

      expect(current_path).to eql(build_results_report_path(@report))

      within ".sidebar" do
        find("li", text: 'Kpi #1').drag_to field_list('columns')
        expect(field_list('fields')).to have_no_content('Kpi #1')
      end

      click_button 'Save'

      expect(current_path).to eql(build_results_report_path(@report))
    end

    scenario "allows the user to cancel changes an existing custom report" do
      FactoryGirl.create(:kpi, name: 'Kpi #1', company: @company)

      visit results_report_path(@report)

      click_link 'Edit'

      expect(current_path).to eql(build_results_report_path(@report))

      within ".sidebar" do
        find("li", text: 'Kpi #1').drag_to field_list('columns')
        expect(field_list('fields')).to have_no_content('Kpi #1')
      end

      page.execute_script('$(window).off("beforeunload")') # Prevent the alert as there is no way to test it
      click_link 'Exit'

      expect(current_path).to eql(results_report_path(@report))
    end
  end

  feature "build view" do
    before do
      @report = FactoryGirl.create(:report, name: 'Events by Venue',
        description: 'a resume of events by venue',
        active: true, company: @company)
      page.driver.resize(1024, 1500)
      Kpi.create_global_kpis
    end

    scenario "share a report" do
      user = FactoryGirl.create(:company_user,
        user: FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas'),
        company: @company)
      team = FactoryGirl.create(:team, name:'Los Fantasticos', company: @company)
      role = FactoryGirl.create(:role, name: 'Super Hero', company: @company)

      visit build_results_report_path(@report)
      click_js_button 'Share'
      within visible_modal do
        expect(find_field('report_sharing_custom')['checked']).to be_false
        expect(find_field('report_sharing_everyone')['checked']).to be_false
        expect(find_field('report_sharing_owner')['checked']).to be_true
        choose('Share with Users, Teams and Roles')
        select_from_chosen('Guillermo Vargas', from: 'report_sharing_selections')
        select_from_chosen('Los Fantasticos', from: 'report_sharing_selections')
        select_from_chosen('Super Hero', from: 'report_sharing_selections')
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      click_js_button 'Share'
      within visible_modal do
        expect(page).to have_content('Guillermo Vargas')
        expect(page).to have_content('Los Fantasticos')
        expect(page).to have_content('Super Hero')
        expect(find_field('report_sharing_custom')['checked']).to be_true
        expect(find_field('report_sharing_everyone')['checked']).to be_false
        expect(find_field('report_sharing_owner')['checked']).to be_false

        choose('Share with everyone')
        click_js_button 'Save'
      end
      ensure_modal_was_closed
      expect(@report.reload.sharing).to eql 'everyone'
    end

    scenario "search for fields in the fields list" do
      FactoryGirl.create(:kpi, name: 'ABC KPI', company: @company)

      visit build_results_report_path(@report)

      within report_fields do
        expect(page).to have_content('ABC KPI')
      end

      fill_in 'field_search', with: 'XYZ'

      within report_fields do
        expect(page).to have_no_content('ABC KPI')
      end

      fill_in 'field_search', with: 'ABC'

      within report_fields do
        expect(page).to have_content('ABC KPI')
      end

      fill_in 'field_search', with: 'venue'
      within report_fields do
        expect(page).to have_no_content('ABC')
        expect(page).to have_content('Name')
        expect(page).to have_content('State')
        expect(page).to have_content('City')
      end
    end

    scenario "drag fields to the different field lists" do
      FactoryGirl.create(:kpi, name: 'Kpi #1', company: @company)
      FactoryGirl.create(:kpi, name: 'Kpi #2', company: @company)
      FactoryGirl.create(:kpi, name: 'Kpi #3', company: @company)
      FactoryGirl.create(:kpi, name: 'Kpi #4', company: @company)
      FactoryGirl.create(:kpi, name: 'Kpi #5', company: @company)

      visit build_results_report_path(@report)

      # The save button should be disabled
      expect(find_button('Save', disabled: true)['disabled']).to eql 'disabled'

      within ".sidebar" do
        expect(field_list('columns')).to have_no_content('Values')
        find("li", text: 'Kpi #1').drag_to field_list('values')
        expect(field_list('fields')).to have_no_content('Kpi #1')
        find("li", text: 'Kpi #2').drag_to field_list('rows')
        expect(field_list('fields')).to have_no_content('Kpi #2')
        find('li[data-group="Venue"]', text: 'Name').drag_to field_list('rows')
        expect(field_list('rows')).to have_content('Venue Name')
        find("li", text: 'Kpi #3').drag_to field_list('filters')
        expect(field_list('fields')).to have_no_content('Kpi #3')
        find("li", text: 'Kpi #4').drag_to field_list('values')
        expect(field_list('fields')).to have_no_content('Kpi #4')
        expect(field_list('values')).to have_content('Sum of Kpi #4')
        expect(field_list('columns')).to have_content('Values')
      end

      # Save the report and reload page to make sure they were correctly saved
      click_js_button "Save"
      wait_for_ajax
      expect(find_button('Save', disabled: true)['disabled']).to eql 'disabled'

      visit build_results_report_path(@report)
      within ".sidebar" do
        # Each KPI should be in the correct list
        expect(field_list('values')).to have_content('Kpi #1')
        expect(field_list('columns')).to have_content('Values')
        expect(field_list('rows')).to have_content('Kpi #2')
        expect(field_list('filters')).to have_content('Kpi #3')
        expect(field_list('values')).to have_content('Sum of Kpi #4')

        # and they should not be in the source fields lists
        expect(field_list('fields')).to have_no_content('Kpi #1')
        expect(field_list('fields')).to have_no_content('Kpi #2')
        expect(field_list('fields')).to have_no_content('Kpi #3')
        expect(field_list('fields')).to have_no_content('Kpi #4')
        expect(field_list('fields')).to have_content('Kpi #5')
      end
    end

    scenario "user can change the aggregation method for values" do
      visit build_results_report_path(@report)
      field_list('fields').find("li", text: 'Impressions').drag_to field_list('values')
      field_list('values').find('.field-settings-btn').click
      within ".report-field-settings" do
        select_from_chosen('Average', from: 'Summarize by')
        find_field('Label').value.should == 'Average of Impressions'
      end
      find('body').click
      click_button 'Save'
      wait_for_ajax
      expect(@report.reload.values.first.to_hash).to include("label"=>"Average of Impressions", "aggregate" => 'avg')
    end

    scenario "user can change the aggregation method for rows" do
      campaign = FactoryGirl.create(:campaign, company: @company, name: 'My Super Campaign')
      FactoryGirl.create(:event, campaign: campaign, start_date: '01/01/2014', end_date: '01/01/2014',
        results: {impressions: 100, interactions: 1000})
      FactoryGirl.create(:event, campaign: campaign, start_date: '02/02/2014', end_date: '02/02/2014',
        results: {impressions: 50, interactions: 2000})
      visit build_results_report_path(@report)
      field_list('fields').find('li[data-field-id="campaign:name"]').drag_to field_list('rows')
      field_list('fields').find('li[data-field-id="event:start_date"]').drag_to field_list('rows')
      field_list('fields').find("li", text: 'Impressions').drag_to field_list('values')
      field_list('fields').find("li", text: 'Interactions').drag_to field_list('values')

      field_list('rows').find('li[data-field-id="campaign:name"]').find('.field-settings-btn').click
      within '.report-field-settings' do
        select_from_chosen('Average', from: 'Summarize by')
        expect(find_field('Label').value).to eql 'Campaign Name'
      end
      find('body').click
      click_button 'Save'
      wait_for_ajax
      expect(@report.reload.rows.first.to_hash).to include("label"=>"Campaign Name", "aggregate" => 'avg', "field" => "campaign:name")

      within "#report-container tr.level_0" do
        expect(page).to have_content('My Super Campaign')
        expect(page).to have_content('75.0')
        expect(page).to have_content('1500.0')
      end

      field_list('rows').find('li[data-field-id="campaign:name"]').find('.field-settings-btn').click
      within '.report-field-settings' do
        select_from_chosen('Max', from: 'Summarize by')
      end
      find('body').click
      within "#report-container tr.level_0" do
        expect(page).to have_content('100.0')
        expect(page).to have_content('2000.0')
      end

      field_list('rows').find('li[data-field-id="campaign:name"]').find('.field-settings-btn').click
      within '.report-field-settings' do
        select_from_chosen('Min', from: 'Summarize by')
      end
      find('body').click
      within "#report-container tr.level_0" do
        expect(page).to have_content('50.0')
        expect(page).to have_content('1000.0')
      end

      field_list('rows').find('li[data-field-id="campaign:name"]').find('.field-settings-btn').click
      within '.report-field-settings' do
        select_from_chosen('Sum', from: 'Summarize by')
      end
      find('body').click
      within "#report-container tr.level_0" do
        expect(page).to have_content('150.0')
        expect(page).to have_content('3000.0')
      end

      field_list('rows').find('li[data-field-id="campaign:name"]').find('.field-settings-btn').click
      within '.report-field-settings' do
        select_from_chosen('Count', from: 'Summarize by')
      end
      find('body').click
      within "#report-container tr.level_0" do
        expect(page).to have_content('2')
      end
    end

    scenario "user can change the calculation method for values" do
      campaign = FactoryGirl.create(:campaign, company: @company, name: 'My Super Campaign')
      FactoryGirl.create(:event, campaign: campaign, start_date: '01/01/2014', end_date: '01/01/2014',
        results: {impressions: 100, interactions: 1000})
      FactoryGirl.create(:event, campaign: campaign, start_date: '02/02/2014', end_date: '02/02/2014',
        results: {impressions: 50, interactions: 2000})
      visit build_results_report_path(@report)
      field_list('fields').find('li[data-field-id="campaign:name"]').drag_to field_list('rows')
      field_list('fields').find("li", text: 'Interactions').drag_to field_list('values')

      field_list('values').find('li', text: 'Sum of Interactions').find('.field-settings-btn').click
      within '.report-field-settings' do
        select_from_chosen('% of Column', from: 'Display as')
        expect(find_field('Label').value).to eql 'Sum of Interactions'
      end
      find('body').click
      click_button 'Save'
      wait_for_ajax
      expect(@report.reload.values.first.to_hash).to include("label"=>"Sum of Interactions", "display" => 'perc_of_column', "field" => "kpi:#{Kpi.interactions.id}")

      within "#report-container tr.level_0" do
        expect(page).to have_content('My Super Campaign')
        expect(page).to have_content('100.0')
      end

    end

    scenario "drag fields outside the list to remove it" do
      FactoryGirl.create(:kpi, name: 'Kpi #1', company: @company)

      visit build_results_report_path(@report)

      # The save button should be disabled
      expect(find_button('Save', disabled: true)['disabled']).to eql 'disabled'

      find("li", text: 'Kpi #1').drag_to field_list('columns')
      find_button('Save') # The button should become active

      # Drag the field to outside the list make check it's removed from the columns list
      # and visible in the source fields list
      field_list('columns').find("li", text: 'Kpi #1').drag_to find('#report-container')
      expect(field_list('columns')).to have_no_content('Kpi #1')
      expect(field_list('fields')).to have_content('Kpi #1')
    end

    scenario "adding a value should automatically add the 'Values' column and removing it should remove the values" do
      FactoryGirl.create(:kpi, name: 'Kpi #1', company: @company)

      visit build_results_report_path(@report)

      find("li", text: 'Kpi #1').drag_to field_list('values')

      # A "Values" field should have been created in the columns list
      expect(field_list('columns')).to have_content('Values')
      expect(field_list('values')).to have_content('Kpi #1')

      # Drop out the "Values" field from the columns and make sure the values are removed
      # from the values list
      field_list('columns').find("li", text: 'Values').drag_to find('#report-container')
      expect(field_list('columns')).to have_no_content('Values')
      expect(field_list('values')).to have_no_content('Kpi #1')
    end

    feature "preview" do
      it "should display a preview as the user make changes on the report" do
        FactoryGirl.create(:event, company: @company, results: {impressions: 100})
        visit build_results_report_path(@report)

        expect(find(report_preview)).to have_content('Drag and drop filters, columns, rows and values to create your report.')

        field_list('fields').find("li", text: 'Impression').drag_to field_list('values')
        field_list('fields').find("li", text: 'Interactions').drag_to field_list('values')

        expect(find(report_preview)).to have_content('Drag and drop filters, columns, rows and values to create your report.')

        field_list('fields').find('li[data-field-id="place:name"]').drag_to field_list('rows')

        within report_preview do
          expect(page).to have_no_content('Drag and drop filters, columns, rows and values to create your report.')
          expect(page).to have_selector('th', text: 'IMPRESSIONS')
          expect(page).to have_selector('th', text: 'INTERACTIONS')
        end
      end
    end
  end


  def reports_list
    "ul#custom-reports-list"
  end

  def report_fields
    "#report-fields"
  end

  def field_search_box
    "#field-search-input"
  end

  def report_preview
    "#report-container"
  end

  def field_list(name)
    find("#report-#{name}")
  end
end