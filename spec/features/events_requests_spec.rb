require 'rails_helper'

feature 'Events section' do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company, name: 'Campaign FY2012') }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { create(:place, name: 'A Nice Place', country: 'CR', city: 'Curridabat', state: 'San Jose') }
  let(:permissions) { [] }
  let(:event) { create(:event, campaign: campaign, company: company) }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end
  after { Warden.test_reset! }

  shared_examples_for 'a user that can activate/deactivate events' do
    let(:events)do
      [
        create(:event, start_date: '08/21/2013', end_date: '08/21/2013',
               start_time: '10:00am', end_time: '11:00am', campaign: campaign, place: place),
        create(:event, start_date: '08/28/2013', end_date: '08/29/2013',
               start_time: '11:00am', end_time: '12:00pm', campaign: campaign, place: place)
      ]
    end
    scenario 'should allow user to deactivate events from the event list' do
      Timecop.travel(Time.zone.local(2013, 07, 30, 12, 01)) do
        events  # make sure events are created before
        Sunspot.commit
        visit events_path

        expect(page).to have_selector event_list_item(events.first)
        within resource_item events.first do
          click_js_link 'Deactivate'
        end

        confirm_prompt 'Are you sure you want to deactivate this event?'

        expect(page).to have_no_selector event_list_item(events.first)
      end
    end

    scenario 'should allow user to activate events' do
      Timecop.travel(Time.zone.local(2013, 07, 21, 12, 01)) do
        events.each(&:deactivate!) # Deactivate the events
        Sunspot.commit
        visit events_path

        # Show only inactive items
        filter_section('ACTIVE STATE').unicheck('Inactive')
        filter_section('ACTIVE STATE').unicheck('Active')

        expect(page).to have_selector event_list_item(events.first)
        within resource_item events.first do
          click_js_link('Activate')
        end
        expect(page).to have_no_selector event_list_item(events.first)
      end
    end

    scenario 'allows the user to activate/deactivate a event from the event details page' do
      visit event_path(events.first)
      within('.links-data') do
        click_js_link('Deactivate')
      end

      confirm_prompt 'Are you sure you want to deactivate this event?'

      within('.links-data') do
        click_js_link('Activate')
        expect(page).to have_link('Deactivate') # test the link have changed
      end
    end
  end

  feature 'non admin user', js: true, search: true do
    let(:role) { create(:non_admin_role, company: company) }

    it_should_behave_like 'a user that can activate/deactivate events' do
      before { company_user.campaigns << campaign }
      before { company_user.places << create(:place, city: nil, state: 'San Jose', country: 'CR', types: ['locality']) }
      let(:permissions) { [[:index, 'Event'], [:view_list, 'Event'], [:deactivate, 'Event'], [:show, 'Event']] }
    end
  end

  feature 'admin user', js: true, search: true do
    let(:role) { create(:role, company: company) }

    it_behaves_like 'a user that can activate/deactivate events'

    feature '/events', js: true, search: true  do
      after do
        Timecop.return
      end

      feature 'Close bar' do
        let(:events)do
          [
            create(:submitted_event,
                   start_date: '08/21/2013', end_date: '08/21/2013',
                   campaign: create(:campaign, name: 'Campaign #1 FY2012', company: company)),
            create(:submitted_event,
                   start_date: '08/28/2013', end_date: '08/29/2013',
                   campaign: create(:campaign, name: 'Campaign #2 FY2012', company: company)),
            create(:submitted_event, start_date: '08/28/2013', end_date: '08/29/2013',
                   campaign: create(:campaign, name: 'Campaign #3 FY2012', company: company)),
            create(:event, campaign: create(:campaign, name: 'Campaign #4 FY2012', company: company))
          ]
        end

        scenario 'Close bar should return the list of events' do
          events  # make sure users are created before
          Sunspot.commit
          visit events_path
          expect(page).to have_selector('#events-list .resource-item', count: 1)
          filter_section('EVENT STATUS').unicheck('Submitted')
          expect(page).to have_selector('#events-list .resource-item', count: 3)
          resource_item(2).click
          within('.alert') do
            click_link 'approve'
          end
          expect(page).to have_content('Your post event report has been approved.')
          find('#resource-close-details').click
          expect(page).to have_selector('#events-list .resource-item', count: 2)
        end

      end

      feature 'GET index' do
        let(:events) do
          [
            create(:event,
                   start_date: '08/21/2013', end_date: '08/21/2013',
                   start_time: '10:00am', end_time: '11:00am',
                   campaign: campaign, active: true,
                   place: create(:place, name: 'Place 1')),
            create(:event,
                   start_date: '08/28/2013', end_date: '08/29/2013',
                   start_time: '11:00am', end_time: '12:00pm',
                   campaign: create(:campaign, name: 'Another Campaign April 03', company: company),
                   place: create(:place, name: 'Place 2'), company: company)
          ]
        end

        scenario 'a user can play and dismiss the video tutorial' do
          visit events_path

          feature_name = 'Getting Started: Events'

          expect(page).to have_selector('h5', text: feature_name)
          expect(page).to have_content('The Events module is your one-stop-shop')
          click_link 'Play Video'

          within visible_modal do
            click_js_link 'Close'
          end
          ensure_modal_was_closed

          within('.new-feature') do
            click_js_link 'Dismiss'
          end
          wait_for_ajax

          visit events_path
          expect(page).to have_no_selector('h5', text: feature_name)
        end

        scenario 'should display a list of events' do
          Timecop.travel(Time.zone.local(2013, 07, 21, 12, 01)) do
            events  # make sure events are created before
            Sunspot.commit
            visit events_path

            # First Row
            within resource_item 1 do
              expect(page).to have_content('WED Aug 21')
              expect(page).to have_content('10:00 AM - 11:00 AM')
              expect(page).to have_content(events[0].place_name)
              expect(page).to have_content('Campaign FY2012')
            end
            # Second Row
            within resource_item 2  do
              expect(page).to have_content(events[1].start_at.strftime('WED Aug 28 at 11:00 AM'))
              expect(page).to have_content(events[1].end_at.strftime('THU Aug 29 at 12:00 PM'))
              expect(page).to have_content(events[1].place_name)
              expect(page).to have_content('Another Campaign April 03')
            end
          end
        end

        scenario 'should allow allow filter events by date range selected from the calendar' do
          today = Time.zone.local(Time.now.year, Time.now.month, 18, 12, 00)
          tomorrow = today + 1.day
          Timecop.travel(today) do
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes),
                   start_time: '10:00am', end_time: '11:00am', campaign: campaign,
                   place: create(:place, name: 'Place 1', city: 'Los Angeles', state: 'CA', country: 'US'))
            create(:event, start_date: tomorrow.to_s(:slashes), end_date: tomorrow.to_s(:slashes),
                   start_time: '11:00am',  end_time: '12:00pm',
                   campaign: create(:campaign, name: 'Another Campaign April 03', company: company),
                   place: create(:place, name: 'Place 2', city: 'Austin', state: 'TX', country: 'US'))
            Sunspot.commit

            visit events_path

            expect(page).to have_content('2 Active events taking place today and in the future')

            within events_list do
              expect(page).to have_content('Campaign FY2012')
              expect(page).to have_content('Another Campaign April 03')
            end

            expect(page).to have_filter_section(title: 'CAMPAIGNS',
                                                options: ['Campaign FY2012', 'Another Campaign April 03'])
            # expect(page).to have_filter_section(title: 'LOCATIONS', options: ['Los Angeles', 'Austin'])

            filter_section('CAMPAIGNS').unicheck('Campaign FY2012')

            expect(page).to have_content('1 Active event as part of Campaign FY2012')

            within events_list do
              expect(page).to have_no_content('Another Campaign April 03')
              expect(page).to have_content('Campaign FY2012')
            end

            filter_section('CAMPAIGNS').unicheck('Another Campaign April 03')
            within events_list do
              expect(page).to have_content('Another Campaign April 03')
              expect(page).to have_content('Campaign FY2012')
            end

            expect(page).to have_content('2 Active events as part of Another Campaign April 03 and Campaign FY2012')

            select_filter_calendar_day('18')
            expect(find('#collection-list-filters')).to have_content('Another Campaign April 03')
            within events_list do
              expect(page).to have_no_content('Another Campaign April 03')
              expect(page).to have_content('Campaign FY2012')
            end

            expect(page).to have_content('1 Active event taking place today as part of Another Campaign April 03 and Campaign FY2012')

            select_filter_calendar_day('18', '19')
            within events_list do
              expect(page).to have_content('Another Campaign April 03')
              expect(page).to have_content('Campaign FY2012')
            end
          end
        end

        feature 'export' do
          let(:month_number) { Time.now.strftime('%m') }
          let(:month_name) { Time.now.strftime('%b') }
          let(:year_number) { Time.now.strftime('%Y') }
          let(:today) { Time.zone.local(year_number, month_number, 18, 12, 00) }
          let(:event1) { create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes),
                                start_time: '10:00am', end_time: '11:00am',
                                campaign: campaign, active: true,
                                place: create(:place, name: 'Place 1'), company: company) }
          let(:event2) { create(:event, start_date: (today + 1.day).to_s(:slashes), end_date: (today + 1.days).to_s(:slashes),
                                start_time: '08:00am', end_time: '09:00am',
                                campaign: create(:campaign, name: 'Another Campaign April 03', company: company),
                                place: create(:place, name: 'Place 2', city: 'Los Angeles', state: 'CA', zipcode: '67890'), company: company) }

          before do
            # make sure events are created before
            event1
            event2
            Sunspot.commit
          end

          scenario 'should be able to export as xls' do
            visit events_path

            click_js_link 'Download'
            click_js_link 'Download as XLS'

            within visible_modal do
              expect(page).to have_content('We are processing your request, the download will start soon...')
              expect(ListExportWorker).to have_queued(ListExport.last.id)
              ResqueSpec.perform_all(:export)
            end
            ensure_modal_was_closed

            expect(ListExport.last).to have_rows([
              ['CAMPAIGN NAME', 'AREA', 'START', 'END', 'VENUE NAME', 'ADDRESS', 'CITY', 'STATE', 'ZIP', 'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'URL'],
              ['Campaign FY2012', nil, "#{year_number}-#{month_number}-18T10:00", "#{year_number}-#{month_number}-18T11:00", 'Place 1', 'Place 1, New York City, NY, 12345', 'New York City', 'NY', '12345', 'Active', 'Unsent', nil, "http://localhost:5100/events/#{event1.id}"],
              ['Another Campaign April 03', nil, "#{year_number}-#{month_number}-19T08:00", "#{year_number}-#{month_number}-19T09:00", 'Place 2', 'Place 2, Los Angeles, CA, 67890', 'Los Angeles', 'CA', '67890', 'Active', 'Unsent', nil, "http://localhost:5100/events/#{event2.id}"]
            ])
          end

          scenario 'should be able to export as PDF' do
            visit events_path

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
              expect(text).to include '2Activeeventstakingplacetodayandinthefuture'
              expect(text).to include 'CampaignFY2012'
              expect(text).to include 'AnotherCampaignApril03'
              expect(text).to include 'Place1NewYorkCity,NY,12345'
              expect(text).to include 'Place2LosAngeles,CA,67890'
              expect(text).to include '10:00AM-11:00AM'
              expect(text).to include '8:00AM-9:00AM'
              expect(text).to match(/#{month_name}18/)
              expect(text).to match(/#{month_name}19/)
            end
          end
        end

        feature 'date ranges box' do
          let(:today) { Time.zone.local(Time.now.year, Time.now.month, Time.now.day, 12, 00) }
          let(:month_number) { Time.now.strftime('%m')}
          let(:year) { Time.now.strftime('%Y') }
          let(:campaign1) { create(:campaign, name: 'Campaign FY2012', company: company) }
          let(:campaign2) { create(:campaign, name: 'Another Campaign April 03', company: company) }
          let(:campaign3) { create(:campaign, name: 'New Brand Campaign', company: company) }

          scenario "can filter the events by predefined 'Today' date range option" do
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes), campaign: campaign1)
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes), campaign: campaign2)
            create(:event, start_date: (today + 1.day).to_s(:slashes), end_date: (today + 1.day).to_s(:slashes), campaign: campaign3)
            Sunspot.commit

            visit events_path

            choose_predefined_date_range 'Today'
            wait_for_ajax

            expect(page).to have_selector('#events-list .resource-item', count: 2)
            within events_list do
              expect(page).to have_content('Campaign FY2012')
              expect(page).to have_content('Another Campaign April 03')
              expect(page).to have_no_content('New Brand Campaign')
            end
          end

          scenario "can filter the events by predefined 'Current week' date range option" do
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes), campaign: campaign2)
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes), campaign: campaign3)
            create(:event, start_date: (today - 2.weeks).to_s(:slashes), end_date: (today - 2.weeks).to_s(:slashes), campaign: campaign1)
            Sunspot.commit

            visit events_path

            choose_predefined_date_range 'Current week'
            wait_for_ajax

            expect(page).to have_selector('#events-list .resource-item', count: 2)
            within events_list do
              expect(page).to have_no_content('Campaign FY2012')
              expect(page).to have_content('Another Campaign April 03')
              expect(page).to have_content('New Brand Campaign')
            end
          end

          scenario "can filter the events by predefined 'Current month' date range option" do
            create(:event, start_date: "#{month_number}/15/#{year}", end_date: "#{month_number}/15/#{year}", campaign: campaign3)
            create(:event, start_date: "#{month_number}/16/#{year}", end_date: "#{month_number}/16/#{year}", campaign: campaign2)
            create(:event, start_date: "#{month_number.to_i+1}/15/#{year}", end_date: "#{month_number.to_i+1}/15/#{year}", campaign: campaign1)
            Sunspot.commit

            visit events_path

            choose_predefined_date_range 'Current month'
            wait_for_ajax

            expect(page).to have_selector('#events-list .resource-item', count: 2)
            within events_list do
              expect(page).to have_no_content('Campaign FY2012')
              expect(page).to have_content('Another Campaign April 03')
              expect(page).to have_content('New Brand Campaign')
            end
          end

          scenario "can filter the events by predefined 'Previous week' date range option" do
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes), campaign: campaign2)
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes), campaign: campaign3)
            create(:event, start_date: (today - 1.week).to_s(:slashes), end_date: (today - 1.week).to_s(:slashes), campaign: campaign1)
            Sunspot.commit

            visit events_path

            choose_predefined_date_range 'Previous week'
            wait_for_ajax

            expect(page).to have_selector('#events-list .resource-item', count: 1)
            within events_list do
              expect(page).to have_content('Campaign FY2012')
              expect(page).to have_no_content('Another Campaign April 03')
              expect(page).to have_no_content('New Brand Campaign')
            end
          end

          scenario "can filter the events by predefined 'Previous month' date range option" do
            create(:event, campaign: campaign2,
                   start_date: "#{month_number}/15/#{year}", end_date: "#{month_number}/15/#{year}")
            create(:event, campaign: campaign1,
                   start_date: "#{month_number.to_i-1}/15/#{year}", end_date: "#{month_number.to_i-1}/15/#{year}")
            create(:event, campaign: campaign1,
                   start_date: "#{month_number.to_i-1}/16/#{year}", end_date: "#{month_number.to_i-1}/16/#{year}")
            create(:event, campaign: campaign3,
                   start_date: "#{month_number.to_i-1}/17/#{year}", end_date: "#{month_number.to_i-1}/17/#{year}")
            Sunspot.commit

            visit events_path

            choose_predefined_date_range 'Previous month'
            wait_for_ajax

            expect(page).to have_selector('#events-list .resource-item', count: 3)
            within events_list do
              expect(page).to have_content('Campaign FY2012')
              expect(page).to have_no_content('Another Campaign April 03')
              expect(page).to have_content('New Brand Campaign')
            end
          end

          scenario "can filter the events by predefined 'YTD' date range option" do
            create(:event, start_date: "01/01/#{year}", end_date: "01/01/#{year}", campaign: campaign1)
            create(:event, start_date: "01/01/#{year}", end_date: "01/01/#{year}", campaign: campaign1)
            create(:event, start_date: "01/01/#{year}", end_date: "01/01/#{year}", campaign: campaign2)
            create(:event, start_date: "07/17/#{year.to_i-1}", end_date: "07/17/#{year.to_i-1}", campaign: campaign3)
            Sunspot.commit

            visit events_path

            choose_predefined_date_range 'YTD'
            wait_for_ajax

            expect(page).to have_selector('#events-list .resource-item', count: 3)
            within events_list do
              expect(page).to have_content('Campaign FY2012')
              expect(page).to have_content('Another Campaign April 03')
              expect(page).to have_no_content('New Brand Campaign')
            end
          end

          scenario 'can filter the events by custom date range selecting start and end dates' do
            create(:event, start_date: (today - 2.weeks).to_s(:slashes), end_date: (today - 2.weeks).to_s(:slashes), campaign: campaign1)
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes), campaign: campaign2)
            create(:event, start_date: Date.today.beginning_of_week.to_s(:slashes), end_date: Date.today.beginning_of_week.to_s(:slashes), campaign: campaign2)
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes), campaign: campaign3)
            create(:event, start_date: (Date.today.beginning_of_week + 5.days).to_s(:slashes), end_date: (Date.today.beginning_of_week + 5.days).to_s(:slashes), campaign: campaign3)
            Sunspot.commit

            visit events_path

            click_js_link 'Date ranges'

            within 'ul.dropdown-menu' do
              expect(page).to have_button('Apply', disabled: true)
              find_field('Start date').click
              select_and_fill_from_datepicker('custom_start_date', Date.today.beginning_of_week.to_s(:slashes))
              find_field('End date').click
              select_and_fill_from_datepicker('custom_end_date', (Date.today.beginning_of_week + 5.days).to_s(:slashes))
              expect(page).to have_button('Apply', disabled: false)
              click_js_button 'Apply'
            end
            ensure_date_ranges_was_closed

            expect(page).to have_selector('#events-list .resource-item', count: 4)
            within events_list do
              expect(page).to have_no_content('Campaign FY2012')
              expect(page).to have_content('Another Campaign April 03')
              expect(page).to have_content('New Brand Campaign')
            end
          end
        end

        scenario 'can filter by users' do
          ev1 = create(:event,
                                   campaign: create(:campaign, name: 'Campaña1', company: company))
          ev2 = create(:event,
                                   campaign: create(:campaign, name: 'Campaña2', company: company))
          ev1.users << create(:company_user,
                                          user: create(:user, first_name: 'Roberto', last_name: 'Gomez'), company: company)
          ev2.users << create(:company_user,
                                          user: create(:user, first_name: 'Mario', last_name: 'Cantinflas'), company: company)
          Sunspot.commit

          visit events_path

          expect(page).to have_filter_section(title: 'PEOPLE',
                                              options: ['Mario Cantinflas', 'Roberto Gomez'])

          within events_list do
            expect(page).to have_content('Campaña1')
            expect(page).to have_content('Campaña2')
          end

          filter_section('PEOPLE').unicheck('Roberto Gomez') # Select
          within events_list do
            expect(page).to have_content('Campaña1')
            expect(page).to have_no_content('Campaña2')
          end

          filter_section('PEOPLE').unicheck('Roberto Gomez') # Deselect
          filter_section('PEOPLE').unicheck('Mario Cantinflas') # Select
          within events_list do
            expect(page).to have_content('Campaña2')
            expect(page).to have_no_content('Campaña1')
          end
        end

        scenario 'Filters are preserved upon navigation' do
          today = Time.zone.local(Time.now.year, Time.now.month, 18, 12, 00)
          tomorrow = today + 1.day
          Timecop.travel(today) do
            ev1 = create(:event, campaign: campaign,
                         start_date: today.to_s(:slashes), end_date: today.to_s(:slashes),
                         start_time: '10:00am', end_time: '11:00am',
                         place: create(:place, name: 'Place 1', city: 'Los Angeles', state: 'CA', country: 'US'))

            create(:event,
                   start_date: tomorrow.to_s(:slashes), end_date: tomorrow.to_s(:slashes),
                   start_time: '11:00am',  end_time: '12:00pm',
                   campaign: create(:campaign, name: 'Another Campaign April 03', company: company),
                   place: create(:place, name: 'Place 2', city: 'Austin', state: 'TX', country: 'US'))
            Sunspot.commit

            visit events_path

            filter_section('CAMPAIGNS').unicheck('Campaign FY2012')
            select_filter_calendar_day('18')

            within events_list do
              click_js_link('Event Details')
            end

            expect(page).to have_selector('h2', text: 'Campaign FY2012')
            expect(current_path).to eq(event_path(ev1))

            close_resource_details

            expect(page).to have_content('1 Active event taking place today as part of Campaign FY2012')
            expect(current_path).to eq(events_path)

            within events_list do
              expect(page).to have_no_content('Another Campaign April 03')
              expect(page).to have_content('Campaign FY2012')
            end
          end
        end

        scenario 'first filter should make the list show events in the past' do
          Timecop.travel(Time.zone.local(2013, 07, 21, 12, 01)) do
            create(:event, campaign: campaign,
                   start_date: '07/07/2013', end_date: '07/07/2013')
            create(:event, campaign: campaign,
                   start_date: '07/21/2013', end_date: '07/21/2013')
            Sunspot.commit

            visit events_path
            expect(page).to have_content('1 Active event taking place today and in the future')
            expect(page).to have_selector('#events-list .resource-item', count: 1)

            filter_section('CAMPAIGNS').unicheck('Campaign FY2012')
            expect(page).to have_content('2 Active events as part of Campaign FY2012')  # The list shouldn't be filtered by date
            expect(page).to have_selector('#events-list .resource-item', count: 2)
          end
        end

        scenario 'clear filters should also exclude reset the default dates filter' do
          Timecop.travel(Time.zone.local(2013, 07, 21, 12, 01)) do
            create(:event, campaign: campaign,
                   start_date: '07/11/2013', end_date: '07/11/2013')
            create(:event, campaign: campaign,
                   start_date: '07/21/2013', end_date: '07/21/2013')
            Sunspot.commit

            visit events_path
            expect(page).to have_content('1 Active event taking place today and in the future')
            expect(page).to have_selector('#events-list .resource-item', count: 1)

            click_button 'Reset'
            expect(page).to have_content('2 Active events')  # The list shouldn't be filtered by date
            expect(page).to have_selector('#events-list .resource-item', count: 2)

            filter_section('CAMPAIGNS').unicheck('Campaign FY2012')
            expect(page).to have_content('2 Active events as part of Campaign FY2012')  # The list shouldn't be filtered by date
            expect(page).to have_selector('#events-list .resource-item', count: 2)
          end
        end

        feature 'with timezone support turned ON' do
          before do
            company.update_column(:timezone_support, true)
            user.reload
          end
          scenario "should display the dates relative to event's timezone" do
            Timecop.travel(Time.zone.local(2013, 07, 21, 12, 01)) do
              # Create a event with the time zone "Central America"
              Time.use_zone('Central America') do
                create(:event, start_date: '08/21/2013', end_date: '08/21/2013', start_time: '10:00am', end_time: '11:00am', company: company)
              end

              # Just to make sure the current user is not in the same timezone
              expect(user.time_zone).to eq('Pacific Time (US & Canada)')

              Sunspot.commit
              visit events_path

              within resource_item 1 do
                expect(page).to have_content('WED Aug 21')
                expect(page).to have_content('10:00 AM - 11:00 AM')
              end
            end
          end
        end

        feature 'filters' do
          scenario 'Users must be able to filter on all brands they have permissions to access ' do
            today = Time.zone.local(Time.now.year, Time.now.month, 18, 12, 00)
            tomorrow = today + 1.day
            Timecop.travel(today) do
              ev1 = create(:event,
                           start_date: today.to_s(:slashes), end_date: today.to_s(:slashes),
                           start_time: '10:00am', end_time: '11:00am',
                           campaign: campaign,
                           place: create(:place, name: 'Place 1', city: 'Los Angeles', state: 'CA', country: 'US'))
              ev2 = create(:event,
                           start_date: tomorrow.to_s(:slashes), end_date: tomorrow.to_s(:slashes),
                           start_time: '11:00am',  end_time: '12:00pm',
                           campaign: create(:campaign, name: 'Another Campaign April 03', company: company),
                           place: create(:place, name: 'Place 2', city: 'Austin', state: 'TX', country: 'US'))
              brands = [
                create(:brand, name: 'Cacique', company: company),
                create(:brand, name: 'Smirnoff', company: company)
              ]
              create(:brand, name: 'Centenario')  # Brand not added to the user/campaing
              ev1.campaign.brands << brands.first
              ev2.campaign.brands << brands.last
              company_user.brands << brands
              Sunspot.commit
              visit events_path
              expect(page).to have_filter_section(title: 'BRANDS', options: %w(Cacique Smirnoff))

              within events_list do
                expect(page).to have_content('Campaign FY2012')
                expect(page).to have_content('Another Campaign April 03')
              end

              filter_section('BRANDS').unicheck('Cacique')

              within events_list do
                expect(page).to have_content('Campaign FY2012')
                expect(page).to have_no_content('Another Campaign April 03')
              end
              filter_section('BRANDS').unicheck('Cacique')   # Deselect Cacique
              filter_section('BRANDS').unicheck('Smirnoff')

              within events_list do
                expect(page).to have_no_content('Campaign FY2012')
                expect(page).to have_content('Another Campaign April 03')
              end
            end
          end

          scenario 'Users must be able to filter on all areas they have permissions to access ' do
            areas = [
              create(:area, name: 'Gran Area Metropolitana',
                     description: 'Ciudades principales de Costa Rica', company: company),
              create(:area, name: 'Zona Norte',
                     description: 'Ciudades del Norte de Costa Rica', company: company),
              create(:area, name: 'Inactive Area', active: false,
                     description: 'This should not appear', company: company)
            ]
            areas.each do |area|
              company_user.areas << area
            end
            Sunspot.commit

            visit events_path
            expect(page).to have_filter_section(title: 'AREAS',
                                                options: ['Gran Area Metropolitana', 'Zona Norte'])
          end
        end
      end
    end

    feature 'custom filters' do
      let(:campaign1) { create(:campaign, name: 'Campaign 1', company: company) }
      let(:campaign2) { create(:campaign, name: 'Campaign 2', company: company) }
      let(:event1) { create(:submitted_event, campaign: campaign1) }
      let(:event2) { create(:late_event, campaign: campaign2) }
      let(:user1) { create(:company_user, user: create(:user, first_name: 'Roberto', last_name: 'Gomez'), company: company) }
      let(:user2) { create(:company_user, user: create(:user, first_name: 'Mario', last_name: 'Moreno'), company: company) }

      scenario 'allows to create a new custom filter' do
        event1.users << user1
        event2.users << user2
        Sunspot.commit

        visit events_path

        filter_section('CAMPAIGNS').unicheck('Campaign 1')
        filter_section('PEOPLE').unicheck('Roberto Gomez')
        filter_section('EVENT STATUS').unicheck('Submitted')

        click_button 'Save'

        within visible_modal do
          fill_in('Filter name', with: 'My Custom Filter')
          expect do
            click_button 'Save'
            wait_for_ajax
          end.to change(CustomFilter, :count).by(1)

          custom_filter = CustomFilter.last
          expect(custom_filter.owner).to eq(company_user)
          expect(custom_filter.name).to eq('My Custom Filter')
          expect(custom_filter.apply_to).to eq('events')
          expect(custom_filter.filters).to eq('campaign%5B%5D=' + campaign1.to_param + '&user%5B%5D=' + user1.to_param + '&event_status%5B%5D=Submitted&status%5B%5D=Active')
        end
        ensure_modal_was_closed

        within '.form-facet-filters' do
          expect(page).to have_content('My Custom Filter')
        end
      end

      scenario 'allows to apply custom filters' do
        event1.users << user1
        event2.users << user2
        Sunspot.commit

        create(:custom_filter, owner: company_user, name: 'Custom Filter 1', apply_to: 'events', filters: 'campaign%5B%5D=' + campaign1.to_param + '&user%5B%5D=' + user1.to_param + '&event_status%5B%5D=Submitted&status%5B%5D=Active')
        create(:custom_filter, owner: company_user, name: 'Custom Filter 2', apply_to: 'events', filters: 'campaign%5B%5D=' + campaign2.to_param + '&user%5B%5D=' + user2.to_param + '&event_status%5B%5D=Late&status%5B%5D=Active')

        visit events_path

        # Using Custom Filter 1
        filter_section('SAVED FILTERS').unicheck('Custom Filter 1')

        within events_list do
          expect(page).to have_content('Campaign 1')
        end

        within '.form-facet-filters' do
          expect(find_field('Campaign 1')['checked']).to be_truthy
          expect(find_field('Campaign 2')['checked']).to be_falsey
          expect(find_field('Roberto Gomez')['checked']).to be_truthy
          expect(find_field('Mario Moreno')['checked']).to be_falsey
          expect(find_field('Submitted')['checked']).to be_truthy
          expect(find_field('Late')['checked']).to be_falsey
          expect(find_field('Active')['checked']).to be_truthy
          expect(find_field('Inactive')['checked']).to be_falsey
          expect(find_field('Custom Filter 1')['checked']).to be_truthy
          expect(find_field('Custom Filter 2')['checked']).to be_falsey
        end

        # Using Custom Filter 2 should update results and checked/unchecked checkboxes
        filter_section('SAVED FILTERS').unicheck('Custom Filter 2')

        within events_list do
          expect(page).to have_content('Campaign 2')
        end

        within '.form-facet-filters' do
          expect(find_field('Campaign 1')['checked']).to be_falsey
          expect(find_field('Campaign 2')['checked']).to be_truthy
          expect(find_field('Roberto Gomez')['checked']).to be_falsey
          expect(find_field('Mario Moreno')['checked']).to be_truthy
          expect(find_field('Submitted')['checked']).to be_falsey
          expect(find_field('Late')['checked']).to be_truthy
          expect(find_field('Active')['checked']).to be_truthy
          expect(find_field('Inactive')['checked']).to be_falsey
          expect(find_field('Custom Filter 1')['checked']).to be_falsey
          expect(find_field('Custom Filter 2')['checked']).to be_truthy
        end

        # Using Custom Filter 2 again should reset filters
        filter_section('SAVED FILTERS').unicheck('Custom Filter 2')

        within events_list do
          expect(page).to have_content('Campaign 1')
          expect(page).to have_content('Campaign 2')
        end

        within '.form-facet-filters' do
          expect(find_field('Campaign 1')['checked']).to be_falsey
          expect(find_field('Campaign 2')['checked']).to be_falsey
          expect(find_field('Roberto Gomez')['checked']).to be_falsey
          expect(find_field('Mario Moreno')['checked']).to be_falsey
          expect(find_field('Submitted')['checked']).to be_falsey
          expect(find_field('Late')['checked']).to be_falsey
          expect(find_field('Active')['checked']).to be_truthy
          expect(find_field('Inactive')['checked']).to be_falsey
          expect(find_field('Custom Filter 1')['checked']).to be_falsey
          expect(find_field('Custom Filter 2')['checked']).to be_falsey
        end
      end

      scenario 'allows to remove custom filters' do
        create(:custom_filter, owner: company_user, name: 'Custom Filter 1', apply_to: 'events', filters: 'Filters 1')
        cf2 = create(:custom_filter, owner: company_user, name: 'Custom Filter 2', apply_to: 'events', filters: 'Filters 2')
        create(:custom_filter, owner: company_user, name: 'Custom Filter 3', apply_to: 'events', filters: 'Filters 3')

        visit events_path

        find('.settings-for-filters').trigger('click')

        within visible_modal do
          expect(page).to have_content('Custom Filter 1')
          expect(page).to have_content('Custom Filter 2')
          expect(page).to have_content('Custom Filter 3')

          expect do
            hover_and_click('#saved-filters-container #custom-filter-' + cf2.id.to_s, 'Remove Custom Filter')
            wait_for_ajax
          end.to change(CustomFilter, :count).by(-1)

          expect(page).to have_content('Custom Filter 1')
          expect(page).to_not have_content('Custom Filter 2')
          expect(page).to have_content('Custom Filter 3')

          click_button 'Done'
        end
        ensure_modal_was_closed

        within '.form-facet-filters' do
          expect(page).to have_content('Custom Filter 1')
          expect(page).to_not have_content('Custom Filter 2')
          expect(page).to have_content('Custom Filter 3')
        end
      end
    end

    feature 'create a event' do
      scenario 'allows to create a new event' do
        create(:company_user, company: company,
                                          user: create(:user, first_name: 'Other', last_name: 'User'))
        create(:campaign, company: company, name: 'ABSOLUT Vodka')
        visit events_path

        click_button 'Create'

        within visible_modal do
          expect(page).to have_content(company_user.full_name)
          select_from_chosen('ABSOLUT Vodka', from: 'Campaign')
          select_from_chosen('Other User', from: 'Event staff')
          fill_in 'Description', with: 'some event description'
          click_button 'Create'
        end
        ensure_modal_was_closed
        expect(page).to have_content('ABSOLUT Vodka')
        expect(page).to have_content('some event description')
        within '#event-team-members' do
          expect(page).to have_content('Other User')
        end
      end

      scenario 'end date are updated after user changes the start date' do
        Timecop.travel(Time.zone.local(2013, 07, 30, 12, 00)) do
          create(:campaign, company: company)
          visit events_path

          click_button 'Create'

          within visible_modal do
            # Test both dates are the same
            expect(find_field('event_start_date').value).to eql '07/30/2013'
            expect(find_field('event_end_date').value).to eql '07/30/2013'

            # Change the start date and make sure the end date is changed automatically
            find_field('event_start_date').click
            find_field('event_start_date').set '07/29/2013'
            find_field('event_end_date').click
            expect(find_field('event_end_date').value).to eql '07/29/2013'

            # Now, change the end data to make them different and test that the difference
            # is kept after changing start date
            find_field('event_end_date').set '07/31/2013'
            find_field('event_start_date').click
            find_field('event_start_date').set '07/20/2013'
            find_field('event_end_date').click
            expect(find_field('event_end_date').value).to eql '07/22/2013'

            # Change the start time and make sure the end date is changed automatically
            # to one hour later
            find_field('event_start_time').click
            find_field('event_start_time').set '08:00am'
            find_field('event_end_time').click
            expect(find_field('event_end_time').value).to eql '9:00am'

            find_field('event_start_time').click
            find_field('event_start_time').set '4:00pm'
            find_field('event_end_time').click
            expect(find_field('event_end_time').value).to eql '5:00pm'
          end
        end
      end
    end

    feature 'edit a event' do
      scenario 'allows to edit a event' do
        create(:campaign, company: company, name: 'ABSOLUT Vodka FY2013')
        create(:event,
               start_date: 3.days.from_now.to_s(:slashes),
               end_date: 3.days.from_now.to_s(:slashes),
               start_time: '8:00 PM', end_time: '11:00 PM',
               campaign: create(:campaign, name: 'ABSOLUT Vodka FY2012', company: company))
        Sunspot.commit

        visit events_path

        within resource_item do
          click_js_link 'Edit'
        end

        within visible_modal do
          expect(find_field('event_start_date').value).to eq(3.days.from_now.to_s(:slashes))
          expect(find_field('event_end_date').value).to eq(3.days.from_now.to_s(:slashes))
          expect(find_field('event_start_time').value).to eq('8:00pm')
          expect(find_field('event_end_time').value).to eq('11:00pm')

          select_from_chosen('ABSOLUT Vodka FY2013', from: 'Campaign')
          click_js_button 'Save'
        end
        ensure_modal_was_closed
        expect(page).to have_content('ABSOLUT Vodka FY2013')
      end

      feature 'with timezone support turned ON' do
        before do
          company.update_column(:timezone_support, true)
          user.reload
        end
        scenario "should display the dates relative to event's timezone" do
          date = 3.days.from_now.to_s(:slashes)
          Time.use_zone('America/Guatemala') do
            create(:event,
                   start_date: date, end_date: date,
                   start_time: '8:00 PM', end_time: '11:00 PM',
                   campaign: create(:campaign, name: 'ABSOLUT Vodka FY2012', company: company))
          end
          Sunspot.commit

          Time.use_zone('America/New_York') do
            visit events_path

            within resource_item do
              click_js_link 'Edit'
            end

            within visible_modal do
              expect(find_field('event_start_date').value).to eq(date)
              expect(find_field('event_end_date').value).to eq(date)
              expect(find_field('event_start_time').value).to eq('8:00pm')
              expect(find_field('event_end_time').value).to eq('11:00pm')

              fill_in('event_start_time', with: '10:00pm')
              fill_in('event_end_time', with: '11:00pm')

              click_button 'Save'
            end
            ensure_modal_was_closed
            expect(page).to have_content('10:00 PM - 11:00 PM')
          end

          # Check that the event's time is displayed with the same time in a different tiem zone
          Time.use_zone('America/Los_Angeles') do
            visit events_path
            within events_list do
              expect(page).to have_content('10:00 PM - 11:00 PM')
            end
          end
        end
      end
    end

    feature '/events/:event_id', js: true do
      scenario 'a user can play and dismiss the video tutorial (scheduled event)' do
        event = create(:event,
                       start_date: '08/28/2013', end_date: '08/28/2013',
                       start_time: '8:00 PM', end_time: '11:00 PM',
                       campaign: create(:campaign, company: company))
        visit event_path(event)

        feature_name = 'Getting Started: Event Details'

        expect(page).to have_selector('h5', text: feature_name)
        expect(page).to have_content('Welcome to the Event Details page')
        click_link 'Play Video'

        within visible_modal do
          click_js_link 'Close'
        end
        ensure_modal_was_closed

        within('.new-feature') do
          click_js_link 'Dismiss'
        end
        wait_for_ajax

        visit event_path(event)
        expect(page).to have_no_selector('h5', text: feature_name)
      end

      scenario 'a user can play and dismiss the video tutorial (executed event)' do
        event = create(:approved_event,
                       start_date: '08/28/2013', end_date: '08/28/2013',
                       start_time: '8:00 PM', end_time: '11:00 PM',
                       campaign: create(:campaign, company: company))
        visit event_path(event)

        feature_name = 'Getting Started: Event Details'

        expect(page).to have_selector('h5', text: feature_name)
        expect(page).to have_content('You are viewing the Event Details page for an executed event')
        click_link 'Play Video'

        within visible_modal do
          click_js_link 'Close'
        end
        ensure_modal_was_closed

        within('.new-feature') do
          click_js_link 'Dismiss'
        end
        wait_for_ajax

        visit event_path(event)
        expect(page).to have_no_selector('h5', text: feature_name)
      end

      scenario 'GET show should display the event details page' do
        event = create(:event, campaign: campaign,
                       start_date: '08/28/2013', end_date: '08/28/2013',
                       start_time: '8:00 PM', end_time: '11:00 PM',
                       campaign: create(:campaign, name: 'Campaign FY2012', company: company))
        visit event_path(event)
        expect(page).to have_selector('h2', text: 'Campaign FY2012')
        within('.calendar-data') do
          expect(page).to have_content('WED Aug 28')
          expect(page).to have_content('8:00 PM - 11:00 PM')
        end
      end

      feature 'with timezone suport turned ON' do
        before do
          company.update_column(:timezone_support, true)
          user.reload
        end

        scenario "should display the dates relative to event's timezone" do
          event = nil
          # Create a event with the time zone "Central America"
          Time.use_zone('Central America') do
            event = create(:event, campaign: campaign,
                           start_date: '08/21/2013', end_date: '08/21/2013',
                           start_time: '10:00am', end_time: '11:00am')
          end

          # Just to make sure the current user is not in the same timezone
          expect(user.time_zone).to eq('Pacific Time (US & Canada)')

          Sunspot.commit
          visit event_path(event)

          within('.calendar-data') do
            expect(page).to have_content('WED Aug 21')
            expect(page).to have_content('10:00 AM - 11:00 AM')
          end
        end
      end

      scenario 'allows to add a member to the event', js: true do
        pablo = create(:user,
                       first_name: 'Pablo', last_name: 'Baltodano', email: 'palinair@gmail.com',
                       company_id: company.id, role_id: company_user.role_id).company_users.first
        create(:user,
               first_name: 'Anonymous', last_name: 'User', email: 'anonymous@gmail.com',
               company_id: company.id, role_id: company_user.role_id)
        Sunspot.commit

        visit event_path(event)

        click_js_button 'Add Team Member'
        within visible_modal do
          fill_in 'staff-search-item', with: 'Pab'
          expect(page).to have_text 'Pablo Baltodano'
          expect(page).to have_no_text 'Anonymous User'
          within resource_item("#staff-member-user-#{pablo.id}") do
            click_js_link "Add"
          end

          expect(page).to have_no_text("Pablo Baltodano")
        end
        close_modal

        # Re-open the modal to make sure it's not added again to the list
        click_js_button 'Add Team Member'
        within visible_modal do
          expect(page).to have_no_text("Pablo Baltodano")
          expect(page).to have_text("Anonymous User")
        end
        close_modal

        # Test the user was added to the list of event members and it can be removed
        within event_team_member(pablo) do
          expect(page).to have_content('Pablo Baltodano')
          click_js_link 'Remove Member'
        end

        confirm_prompt 'Any tasks that are assigned to Pablo Baltodano must be reassigned. ' +
                       'Would you like to remove Pablo Baltodano from the event team?'
        expect(page).not_to have_content('Pablo Baltodano')

        # Refresh the page and make sure the user is not there
        visit event_path(event)
        expect(all('#event-team-members .team-member').count).to eq(0)
      end

      scenario 'allows to add a user as contact to the event', js: true do
        create(:user, first_name: 'Pablo', last_name: 'Baltodano',
               email: 'palinair@gmail.com', company_id: company.id,
               role_id: company_user.role_id)
        Sunspot.commit

        visit event_path(event)

        click_js_button 'Add Contact'
        within visible_modal do
          fill_in 'contact-search-box', with: 'Pab'
          expect(page).to have_content('Pablo Baltodano')
          within resource_item do
            click_js_link "Add"
          end

          expect(page).to have_no_content('Pablo Baltodano')
        end
        close_modal

        # Test the user was added to the list of event members and it can be removed
        within '#event-contacts-list' do
          expect(page).to have_content('Pablo Baltodano')
          hover_and_click('.event-contact', 'Remove Contact')
        end

        # Refresh the page and make sure the user is not there
        visit event_path(event)

        expect(page).to_not have_content('Pablo Baltodano')
      end

      scenario 'allows to add a contact as contact to the event', js: true do
        event = create(:event, campaign: create(:campaign, name: 'Campaign FY2012', company: company), company: company)
        create(:contact,
               first_name: 'Guillermo', last_name: 'Vargas',
               email: 'guilleva@gmail.com', company_id: company.id)
        Sunspot.commit

        visit event_path(event)

        click_js_button 'Add Contact'
        within visible_modal do
          fill_in 'contact-search-box', with: 'Gui'
          expect(page).to have_content('Guillermo Vargas')
          within resource_item do
            click_js_link "Add"
          end

          expect(page).to have_no_content 'Guillermo Vargas'
        end
        close_modal

        # Test the user was added to the list of event members and it can be removed
        within '#event-contacts-list' do
          expect(page).to have_content('Guillermo Vargas')
          hover_and_click('.event-contact', 'Remove Contact')
        end

        # Refresh the page and make sure the user is not there
        visit event_path(event)

        expect(page).to_not have_content('Guillermo Vargas')
      end

      scenario 'allows to create a contact', js: true do
        event = create(:event, campaign: create(:campaign, name: 'Campaign FY2012', company: company), company: company)
        Sunspot.commit

        visit event_path(event)

        click_js_button 'Add Contact'
        visible_modal.click_js_link('Create New Contact')

        within '.contactevent_modal' do
          fill_in 'First name', with: 'Pedro'
          fill_in 'Last name', with: 'Picapiedra'
          fill_in 'Email', with: 'pedro@racadura.com'
          fill_in 'Phone number', with: '+1 505 22343222'
          fill_in 'Address', with: 'ABC 123'
          select_from_chosen('United States of America', from: 'Country')
          select_from_chosen('California', from: 'State')
          fill_in 'City', with: 'Los Angeles'
          fill_in 'Zip code', with: '12345'
          click_js_button 'Save'
        end

        ensure_modal_was_closed

        # Test the user was added to the list of event members and it can be removed
        within '#event-contacts-list' do
          expect(page).to have_content('Pedro Picapiedra')
        end

        # Test removal of the user
        hover_and_click('#event-contacts-list .event-contact', 'Remove Contact')

        # Refresh the page and make sure the user is not there
        visit event_path(event)

        expect(page).to_not have_content('Pedro Picapiedra')
      end

      scenario 'allows to edit a contact', js: true do
        event = create(:event, campaign: create(:campaign, name: 'Campaign FY2012', company: company), company: company)
        contact = create(:contact, first_name: 'Guillermo', last_name: 'Vargas', email: 'guilleva@gmail.com', company_id: company.id)
        create(:contact_event, event: event, contactable: contact)
        Sunspot.commit

        visit event_path(event)

        expect(page).to have_content('Guillermo Vargas')

        hover_and_click('#event-contacts-list .event-contact', 'Edit Contact')

        within visible_modal do
          fill_in 'First name', with: 'Pedro'
          fill_in 'Last name', with: 'Picapiedra'
          click_js_button 'Save'
        end
        sleep 1
        ensure_modal_was_closed

        # Test the user was added to the list of event members and it can be removed
        within '#event-contacts-list' do
          expect(page).to have_no_content('Guillermo Vargas')
          expect(page).to have_content('Pedro Picapiedra')
          # find('a.remove-member-btn').click
        end
      end

      scenario 'allows to create a new task for the event and mark it as completed' do
        event = create(:event, campaign: create(:campaign, company: company))
        juanito = create(:user, company: company, first_name: 'Juanito', last_name: 'Bazooka')
        juanito_user = juanito.company_users.first
        event.users << juanito_user
        event.users << user.company_users.first
        Sunspot.commit

        visit event_path(event)

        click_js_link 'Create Task'
        within('form#new_task') do
          fill_in 'Title', with: 'Pick up the kidz at school'
          fill_in 'Due at', with: '05/16/2013'
          select_from_chosen('Juanito Bazooka', from: 'Assigned To')
          click_js_button 'Submit'
        end

        expect(page).to have_text('0 UNASSIGNED')
        expect(page).to have_text('0 COMPLETED')
        expect(page).to have_text('1 ASSIGNED')
        expect(page).to have_text('1 LATE')

        within resource_item list: '#tasks-list' do
          expect(page).to have_content('Pick up the kidz at school')
          expect(page).to have_content('Juanito Bazooka')
          expect(page).to have_content('THU May 16')
        end

        # Mark the tasks as completed
        within('#event-tasks-container') do
          checkbox = find('.task-completed-checkbox', visible: :false)
          expect(checkbox['checked']).to be_falsey
          find('.task-completed-checkbox').trigger('click')
          wait_for_ajax

          # refresh the page to make sure the checkbox remains selected
          visit event_path(event)
          expect(find('.task-completed-checkbox', visible: :false)['checked']).to be_truthy
        end

        # Check that the totals where properly updated
        expect(page).to have_text('0 UNASSIGNED')
        expect(page).to have_text('1 COMPLETED')
        expect(page).to have_text('1 ASSIGNED')
        expect(page).to have_text('0 LATE')

        # Delete Juanito Bazooka from the team and make sure that the tasks list
        # is refreshed and the task unassigned
        hover_and_click("#event-member-#{juanito_user.id}", 'Remove Member')
        confirm_prompt 'Any tasks that are assigned to Juanito Bazooka must be reassigned. Would you like to remove Juanito Bazooka from the event team?'
        expect(page).to_not have_content('Juanito Bazooka')

        # refresh the page to make that the tasks were unassigned
        # TODO: the refresh should not be necessary but it looks like that it's not
        # removing the element from the table automatically in the test
        visit event_path(event)
        within('#event-tasks-container') do
          expect(page).to_not have_content('Juanito Bazooka')
        end
      end

      scenario 'the entered data should be saved automatically when submitting the event recap' do
        Kpi.create_global_kpis
        campaign = create(:campaign, company: company)
        kpi = create(:kpi, name: 'Test Field', kpi_type: 'number', capture_mechanism: 'integer')

        campaign.add_kpi kpi

        event = create(:event,
                       start_date: Date.yesterday.to_s(:slashes),
                       end_date: Date.yesterday.to_s(:slashes),
                       campaign: campaign)

        visit event_path(event)

        fill_in 'Test Field', with: '98765'

        click_js_link 'submit'

        expect(page).to have_content('Your post event report has been submitted for approval.')
        expect(page).to have_content('TEST FIELD 98,765')
      end

      scenario 'should not submit the event data if there are validation errors' do
        campaign = create(:campaign, company: company)
        kpi = create(:kpi, name: 'Test Field', kpi_type: 'number', capture_mechanism: 'integer')

        field = campaign.add_kpi(kpi)
        field.required = 'true'
        field.save

        event = create(:event,
                       start_date: Date.yesterday.to_s(:slashes),
                       end_date: Date.yesterday.to_s(:slashes),
                       campaign: campaign)

        visit event_path(event)

        click_js_link 'submit'

        expect(find_field('Test Field')).to have_error('This field is required.')

        expect(page).to have_no_content('Your post event report has been submitted for approval.')
      end
    end
  end

  def event_list_item(event)
    ".resource-item#event_#{event.id}"
  end

  def events_list
    "#events-list"
  end
end
