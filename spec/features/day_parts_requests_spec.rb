require 'rails_helper'

feature 'DayParts', js: true, search: true do
  let(:user) { create(:user, company: company, role_id: create(:role).id) }
  let(:company) { create(:company) }
  let(:company_user) { user.company_users.first }

  before do
    Warden.test_mode!
    sign_in user
  end

  after do
    Warden.test_reset!
  end

  feature '/day_parts', search: true do
    scenario 'GET index should display a table with the day_parts' do
      create(:day_part, company: company,
             name: 'Morningns', description: 'From 8 to 11am', active: true)
      create(:day_part, company: company,
             name: 'Afternoons', description: 'From 1 to 6pm', active: true)
      Sunspot.commit
      visit day_parts_path

      # First Row
      within resource_item 1, list: '#day_parts-list' do
        expect(page).to have_content('Afternoons')
        expect(page).to have_content('From 1 to 6pm')
      end

      # Second Row
      within resource_item 2, list: '#day_parts-list' do
        expect(page).to have_content('Morningns')
        expect(page).to have_content('From 8 to 11am')
      end
    end

    scenario 'should allow user to activate/deactivate Day Parts' do
      create(:day_part, company: company, name: 'Morning', active: true)
      Sunspot.commit
      visit day_parts_path

      within resource_item do
        click_js_link('Deactivate')
      end

      confirm_prompt 'Are you sure you want to deactivate this day part?'

      expect(page).to have_no_content('Morning')

      # Make it show only the inactive elements
      filter_section('ACTIVE STATE').unicheck('Inactive')
      filter_section('ACTIVE STATE').unicheck('Active')

      within resource_item do
        expect(page).to have_content('Morning')
        click_js_link('Activate')
      end
      expect(page).to have_no_content('Morning')
    end

    scenario 'allows the user to create a new day part' do
      visit day_parts_path

      click_js_button 'New Day Part'

      within visible_modal do
        fill_in 'Name', with: 'new day part name'
        fill_in 'Description', with: 'new day part description'
        click_js_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'new day part name') # Wait for the page to load
      expect(page).to have_selector('h2', text: 'new day part name')
      expect(page).to have_selector('div.description-data', text: 'new day part description')
    end
  end

  feature '/day_parts/:day_part_id' do
    scenario 'GET show should display the day_part details page' do
      day_part = create(:day_part, company: company, name: 'Some day part', description: 'a day part description')
      visit day_part_path(day_part)
      expect(page).to have_selector('h2', text: 'Some day part')
      expect(page).to have_selector('div.description-data', text: 'a day part description')
    end

    scenario 'diplays a table of dates within the day part' do
      day_part = create(:day_part, company: company,
                                   day_items: [
                                     create(:day_item, start_time: '12:00pm', end_time: '4:00pm'),
                                     create(:day_item, start_time: '1:00pm', end_time: '3:00pm')
                                   ]
      )
      visit day_part_path(day_part)
      within('#day-part-days-list') do
        within('.date-item:nth-child(1)') do
          expect(page).to have_content('From 12:00 PM to 4:00 PM')
        end
        within('.date-item:nth-child(2)') do
          expect(page).to have_content('From 1:00 PM to 3:00 PM')
        end
      end
    end

    scenario 'allows the user to activate/deactivate a day part' do
      day_part = create(:day_part, company: company, active: true)
      visit day_part_path(day_part)
      find('.links-data').click_js_link('Deactivate')

      confirm_prompt 'Are you sure you want to deactivate this day part?'

      find('.links-data').click_js_link('Activate')
    end

    scenario 'allows the user to edit the day_part' do
      day_part = create(:day_part, name: 'Old name', company: company)
      visit day_part_path(day_part)

      expect(page).to have_content('Old name')
      find('.links-data').click_js_button('Edit Day Part')

      within("form#edit_day_part_#{day_part.id}") do
        fill_in 'Name', with: 'edited day part name'
        fill_in 'Description', with: 'edited day part description'
        click_js_button 'Save'
      end
      ensure_modal_was_closed
      expect(page).to have_no_content('Old name')
      expect(page).to have_selector('h2', text: 'edited day part name')
      expect(page).to have_selector('div.description-data', text: 'edited day part description')
    end

    scenario 'allows the user to add and remove date items to the day part' do
      day_part = create(:day_part, company: company)
      visit day_part_path(day_part)

      click_js_link('Add Time')

      within visible_modal do
        fill_in 'Start', with: '1:00am'
        fill_in 'End', with: '4:00am'
        click_js_button 'Add'
      end

      ensure_modal_was_closed

      day_item_text = 'From 1:00 AM to 4:00 AM'
      expect(page).to have_content(day_item_text)
      within('#day-part-days-list .date-item') do
        click_js_link('Remove')
      end
      expect(page).to have_no_content(day_item_text)
    end
  end

  feature 'export' do
    let(:day_part1) { create(:day_part, company: company,
                              name: 'Morningns', description: 'From 8 to 11am', active: true) }
    let(:day_part2) { create(:day_part, company: company,
                              name: 'Afternoons', description: 'From 1 to 6pm', active: true) }

    before do
      # make sure tasks are created before
      day_part1
      day_part2
      Sunspot.commit
    end

    scenario 'should be able to export as XLS' do
      visit day_parts_path

      click_js_link 'Download'
      click_js_link 'Download as XLS'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      expect(ListExport.last).to have_rows([
        ["NAME", "DESCRIPTION"],
        ["Afternoons", "From 1 to 6pm"],
        ["Morningns", "From 8 to 11am"]
      ])
    end

    scenario 'should be able to export as PDF' do
      visit day_parts_path

      click_js_link 'Download'
      click_js_link 'Download as PDF'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      export = ListExport.last
      # Test the generated PDF...
      reader = PDF::Reader.new(open(export.file.url))
      reader.pages.each do |page|
        # PDF to text seems to not always return the same results
        # with white spaces, so, remove them and look for strings
        # without whitespaces
        text = page.text.gsub(/[\s\n]/, '')
        expect(text).to include 'DayParts'
        expect(text).to include 'Afternoons'
        expect(text).to include 'From1to6pm'
        expect(text).to include 'Morningns'
        expect(text).to include 'From8to11am'
      end
    end
  end
end
