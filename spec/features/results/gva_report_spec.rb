require 'rails_helper'

feature 'Results Goals vs Actuals Page', js: true, search: true  do

  before do
    @company = user.companies.first
    sign_in user
  end

  feature '/results/gva', js: true, search: true  do
    feature 'with a non admin user', search: false do
      let(:company) { create(:company) }
      let(:user) { create(:user, first_name: 'Juanito', last_name: 'Bazooka', company: company, role_id: create(:non_admin_role, company: company).id) }
      let(:company_user) { user.company_users.first }

      before { Kpi.create_global_kpis }

      scenario 'a user can play and dismiss the video tutorial' do
        company_user.role.permissions.create(action: :gva_report_campaigns, subject_class: 'Campaign', mode: 'campaigns')

        visit results_gva_path

        feature_name = 'GETTING STARTED: GOALS VS. ACTUAL'

        expect(page).to have_content(feature_name)
        expect(page).to have_content('The Goals vs. Actual section allows you')
        click_link 'Play Video'

        within visible_modal do
          click_js_link 'Close'
        end
        ensure_modal_was_closed

        within('.new-feature') do
          click_js_link 'Dismiss'
        end
        wait_for_ajax

        visit results_gva_path
        expect(page).to have_no_content(feature_name)
      end

      scenario 'should display the GvA stats for selected campaign and grouping' do
        company_user.role.permissions.create(action: :gva_report_campaigns, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_places, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_users, subject_class: 'Campaign', mode: 'campaigns')
        campaign = create(:campaign, name: 'Test Campaign FY01', start_date: '07/21/2013', end_date: '03/30/2014', company: company)
        kpi = Kpi.samples
        campaign.add_kpi kpi

        place = create(:place, name: 'Place 1')
        campaign.places << place
        company_user.campaigns << campaign
        company_user.places << place

        create(:goal, goalable: campaign, kpi: kpi, value: '100')
        create(:goal, parent: campaign, goalable: company_user, kpi: kpi, value: 100)
        create(:goal, parent: campaign, goalable: company_user, kpi: Kpi.events, value: 3)
        create(:goal, parent: campaign, goalable: place, kpi: kpi, value: 150)
        create(:goal, parent: campaign, goalable: place, kpi: Kpi.events, value: 2)
        create(:goal, parent: campaign, goalable: place, kpi: Kpi.promo_hours, value: 4)
        create(:goal, parent: campaign, goalable: place, kpi: Kpi.expenses, value: 50)

        event1 = create(:approved_event, company: company, campaign: campaign, place: place)
        event1.result_for_kpi(kpi).value = '25'
        event1.save
        event1.users << company_user

        event2 = create(:submitted_event, company: company, campaign: campaign, place: place)
        event2.result_for_kpi(kpi).value = '20'
        event2.save
        event2.users << company_user

        event3 = create(:rejected_event, company: company, campaign: campaign, place: place)
        event3.result_for_kpi(kpi).value = '33'
        event3.save
        event3.users << company_user

        ### Setting data to test Activities
        activity_type = create(:activity_type, name: 'Activity Type', company: company)
        campaign.activity_types << activity_type

        # Activities settings for Place
        area1 = create(:area, name: 'Area 1', company: company)
        area2 = create(:area, name: 'Area 2', company: company)
        place1 = create(:place, name: 'Place 2')
        place2 = create(:place, name: 'Place 3')
        area1.places << place1
        area2.places << place2
        campaign.areas << [area1, area2]
        company_user.areas << [area1, area2]
        venue1 = create(:venue, place: place1, company: company)
        venue2 = create(:venue, place: place2, company: company)
        # Activities settings for Staff
        another_user = create(:company_user, company: company)
        team1 = create(:team, name: 'Team 1', company: company)
        team1.users << another_user
        event1.teams << team1
        campaign.teams << team1

        # Activities goals for Place
        create(:goal, parent: campaign, goalable: area1, activity_type_id: activity_type.id, value: 5)
        create(:goal, parent: campaign, goalable: area2, activity_type_id: activity_type.id, value: 10)
        # Activities goals for Staff
        create(:goal, parent: campaign, goalable: team1, activity_type_id: activity_type.id, value: 8)

        # Activities for Place
        create(:activity, activity_type: activity_type, activitable: venue1, campaign: campaign,
                          company_user: company_user, activity_date: '2013-07-22')
        create(:activity, activity_type: activity_type, activitable: venue1, campaign: campaign,
                          company_user: company_user, activity_date: '2013-07-23')
        create(:activity, activity_type: activity_type, activitable: venue2, campaign: campaign,
                          company_user: company_user, activity_date: '2013-07-24')
        # Activities for Staff
        create(:activity, activity_type: activity_type, activitable: venue2, campaign: campaign,
                          company_user: another_user, activity_date: '2013-07-25')
        create(:activity, activity_type: activity_type, activitable: event1, campaign: campaign,
                          company_user: another_user, activity_date: '2013-07-26')

        Sunspot.commit

        visit results_gva_path

        choose_campaign('Test Campaign FY01')

        ### Testing group by Campaign
        within('.container-kpi-trend') do
          expect(page).to have_content('Samples')
          find('.progress').hover
          expect(page).to have_selector('.executed-label', text: '25')
          expect(page).to have_selector('.submitted-label', text: '20')
          expect(page).to have_selector('.rejected-label', text: '33')
          expect(page).to have_content('100 GOAL')
          expect(page).to have_css('.today-line-indicator')
          within('.progress-label') do
            expect(page).to have_content('78%')
            expect(page).to have_content('78 OF 100 GOAL')
          end
        end

        ### Testing group by Place
        report_form.find('label', text: 'Place').click

        within('#gva-result-Place' + place.id.to_s + ' .item-summary') do
          expect(page).to have_content('Place 1')
          within('.goals-summary') do
            expect(page).to have_content('50% EVENTS')
            expect(page).to have_content('50% PROMO HOURS')
            expect(page).to have_content('0% EXPENSES')
            expect(page).to have_content('52% SAMPLES')
          end
        end

        within('#gva-result-Place' + place.id.to_s + ' .accordion-heading') do
          click_js_link('Place 1')
        end
        within('#gva-result-Place' + place.id.to_s + ' .kpi-trend:nth-child(3)') do
          expect(page).to have_content('Samples')
          find('.progress').hover
          expect(page).to have_selector('.executed-label', text: '25')
          expect(page).to have_selector('.submitted-label', text: '20')
          expect(page).to have_selector('.rejected-label', text: '33')
          expect(page).to have_css('.today-line-indicator')
          within('.progress-label') do
            expect(page).to have_content('52%')
            expect(page).to have_content('78 OF 150 GOAL')
          end
        end
        within('#gva-result-Place' + place.id.to_s + ' .accordion-heading') do
          click_js_link('Place 1')
        end

        # Checking that activities for Venues are in the corresponding Area only
        within('#gva-result-Area' + area1.id.to_s + ' .accordion-heading') do
          click_js_link('Area 1')
        end
        within('#gva-result-Area' + area1.id.to_s + ' .kpi-trend:nth-child(1)') do
          expect(page).to have_content('Activity Type')
          find('.progress').hover
          expect(page).to have_selector('.executed-label', text: '2')
          expect(page).to have_selector('.submitted-label', text: '0')
          expect(page).to have_selector('.rejected-label', text: '0')
          expect(page).to have_css('.today-line-indicator')
          within('.progress-label') do
            expect(page).to have_content('40%')
            expect(page).to have_content('2 OF 5 GOAL')
          end
        end
        within('#gva-result-Area' + area1.id.to_s + ' .accordion-heading') do
          click_js_link('Area 1')
        end

        within('#gva-result-Area' + area2.id.to_s + ' .accordion-heading') do
          click_js_link('Area 2')
        end
        within('#gva-result-Area' + area2.id.to_s + ' .kpi-trend:nth-child(1)') do
          expect(page).to have_content('Activity Type')
          find('.progress').hover
          expect(page).to have_selector('.executed-label', text: '2')
          expect(page).to have_selector('.submitted-label', text: '0')
          expect(page).to have_selector('.rejected-label', text: '0')
          expect(page).to have_css('.today-line-indicator')
          within('.progress-label') do
            expect(page).to have_content('20%')
            expect(page).to have_content('2 OF 10 GOAL')
          end
        end

        ### Testing group by Staff
        report_form.find('label', text: 'Staff').click

        within('#gva-result-CompanyUser' + company_user.id.to_s + ' .item-summary') do
          expect(page).to have_content('Juanito Bazooka')
          within('.goals-summary') do
            expect(page).to have_content('100% EVENTS')
            expect(page).to have_content('78% SAMPLES')
          end
        end

        within('#gva-result-CompanyUser' + company_user.id.to_s + ' .accordion-heading') do
          click_js_link('Juanito Bazooka')
        end
        within('#gva-result-CompanyUser' + company_user.id.to_s + ' .kpi-trend:nth-child(2)') do
          expect(page).to have_content('Samples')
          find('.progress').hover
          expect(page).to have_selector('.executed-label', text: '25')
          expect(page).to have_selector('.submitted-label', text: '20')
          expect(page).to have_selector('.rejected-label', text: '33')
          expect(page).to have_css('.today-line-indicator')
          within('.progress-label') do
            expect(page).to have_content('78%')
            expect(page).to have_content('78 OF 100 GOAL')
          end
        end
        within('#gva-result-CompanyUser' + company_user.id.to_s + ' .accordion-heading') do
          click_js_link('Juanito Bazooka')
        end

        # Checking that activities for Venues are in the corresponding Team only
        within('#gva-result-Team' + team1.id.to_s + ' .accordion-heading') do
          click_js_link('Team 1')
        end
        within('#gva-result-Team' + team1.id.to_s + ' .kpi-trend:nth-child(1)') do
          expect(page).to have_content('Activity Type')
          find('.progress').hover
          expect(page).to have_selector('.executed-label', text: '2')
          expect(page).to have_selector('.submitted-label', text: '0')
          expect(page).to have_selector('.rejected-label', text: '0')
          expect(page).to have_css('.today-line-indicator')
          within('.progress-label') do
            expect(page).to have_content('25%')
            expect(page).to have_content('2 OF 8 GOAL')
          end
        end
      end

      scenario 'should remove items from GvA results' do
        company_user.role.permissions.create(action: :gva_report_campaigns, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_places, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_users, subject_class: 'Campaign', mode: 'campaigns')
        campaign = create(:campaign, name: 'Test Campaign FY01', company: company)
        kpi = create(:kpi, name: 'Interactions', company: company)
        campaign.add_kpi kpi

        place = create(:place, name: 'Place 1')
        campaign.places << place
        company_user.campaigns << campaign
        company_user.places << place

        create(:goal, goalable: campaign, kpi: kpi)
        create(:goal, parent: campaign, goalable: place, kpi: kpi)

        event1 = create(:approved_event, company: company, campaign: campaign, place: place)
        event1.save

        visit results_gva_path

        report_form.find('label', text: 'Place').click

        choose_campaign('Test Campaign FY01')

        within('#gva-results') do
          expect(page).to have_content('Place 1')
          within('.accordion-heading') do
            click_js_link('Remove Place 1')
          end
          expect(page).to_not have_content('Place 1')
        end
      end

      scenario 'should display the places GvA stats for selected campaign whithout select group by when it is the unique permission' do
        company_user.role.permissions.create(action: :gva_report_places, subject_class: 'Campaign', mode: 'campaigns')
        campaign = create(:campaign, name: 'Test Campaign FY01', company: company)
        kpi = create(:kpi, name: 'Interactions', company: company)
        campaign.add_kpi kpi

        place = create(:place, name: 'Place 1')
        campaign.places << place
        company_user.campaigns << campaign
        company_user.places << place

        create(:goal, goalable: campaign, kpi: kpi)
        create(:goal, parent: campaign, goalable: place, kpi: kpi)

        event1 = create(:approved_event, company: company, campaign: campaign, place: place)
        event1.save

        visit results_gva_path

        choose_campaign('Test Campaign FY01')

        within('#gva-results') do
          expect(page).to have_content('Place 1')
        end
      end

      scenario 'should export the overall campaign GvA to Excel' do
        company_user.role.permissions.create(action: :gva_report_campaigns, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_places, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_users, subject_class: 'Campaign', mode: 'campaigns')
        campaign = create(:campaign, name: 'Test Campaign FY01', start_date: '07/21/2013', end_date: '03/30/2014', company: company)
        campaign.add_kpi Kpi.samples
        campaign.add_kpi Kpi.events

        place1 = create(:place, name: 'Place 1')
        campaign.places << place1
        company_user.campaigns << campaign
        company_user.places << place1

        create(:goal, goalable: campaign, kpi: Kpi.samples, value: '100')
        create(:goal, goalable: campaign, kpi: Kpi.events, value: '2')

        event1 = create(:approved_event, company: company, campaign: campaign, place: place1)
        event1.result_for_kpi(Kpi.samples).value = '25'
        event1.save

        event2 = create(:submitted_event, company: company, campaign: campaign, place: place1)
        event2.result_for_kpi(Kpi.samples).value = '20'
        event2.save

        visit results_gva_path

        choose_campaign('Test Campaign FY01')

        # Export
        export_report

        expect(ListExport.last).to have_rows([
          ['METRIC', 'GOAL', 'ACTUAL', 'ACTUAL %', 'PENDING', 'PENDING %'],
          ['Events', '2', '1', '0.5', '2', '1'],
          ['Samples', '100', '25', '0.25', '45', '0.45']
        ])
      end

      scenario 'should export the GvA grouped by Place to Excel' do
        company_user.role.permissions.create(action: :gva_report_campaigns, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_places, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_users, subject_class: 'Campaign', mode: 'campaigns')
        campaign = create(:campaign, name: 'Test Campaign FY01', start_date: '07/21/2013', end_date: '03/30/2014', company: company)
        kpi = Kpi.samples
        kpi2 = Kpi.events
        campaign.add_kpi kpi
        campaign.add_kpi kpi2

        place1 = create(:place, name: 'Place 1')
        campaign.places << place1
        company_user.campaigns << campaign
        company_user.places << place1

        create(:goal, parent: campaign, goalable: place1, kpi: kpi, value: 150)
        create(:goal, parent: campaign, goalable: place1, kpi: kpi2, value: 2)
        create(:goal, parent: campaign, goalable: place1, kpi: Kpi.promo_hours, value: 4)
        create(:goal, parent: campaign, goalable: place1, kpi: Kpi.expenses, value: 50)

        event1 = create(:approved_event, company: company, campaign: campaign, place: place1)
        event1.result_for_kpi(kpi).value = '25'
        event1.save

        event2 = create(:submitted_event, company: company, campaign: campaign, place: place1)
        event2.result_for_kpi(kpi).value = '20'
        event2.save

        visit results_gva_path

        choose_campaign('Test Campaign FY01')

        report_form.find('label', text: 'Place').click

        # Export
        export_report

        expect(ListExport.last).to have_rows([
          ['PLACE/AREA', 'METRIC', 'GOAL', 'ACTUAL', 'ACTUAL %', 'PENDING', 'PENDING %'],
          ['Place 1', 'Events', '2', '1', '0.5', '2', '1'],
          ['Place 1', 'Promo Hours', '4', '2', '0.5', '4', '1'],
          ['Place 1', 'Samples', '150', '25', '0.17', '45', '0.3']
        ])
      end

      scenario 'should export the GvA grouped by Staff to Excel' do
        company_user.role.permissions.create(action: :gva_report_campaigns, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_places, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_users, subject_class: 'Campaign', mode: 'campaigns')
        campaign = create(:campaign, name: 'Test Campaign FY01', start_date: '07/21/2013', end_date: '03/30/2014', company: company)
        kpi = Kpi.samples
        kpi2 = Kpi.events
        campaign.add_kpi kpi
        campaign.add_kpi kpi2

        place1 = create(:place, name: 'Place 1')
        campaign.places << place1
        company_user.campaigns << campaign
        company_user.places << place1

        create(:goal, parent: campaign, goalable: company_user, kpi: kpi, value: 50)
        create(:goal, parent: campaign, goalable: company_user, kpi: kpi2, value: 1)

        event1 = create(:approved_event, company: company, campaign: campaign, place: place1)
        event1.result_for_kpi(kpi).value = '25'
        event1.save

        event2 = create(:submitted_event, company: company, campaign: campaign, place: place1)
        event2.result_for_kpi(kpi).value = '20'
        event2.save

        event1.users << company_user
        event2.users << company_user

        visit results_gva_path

        choose_campaign('Test Campaign FY01')

        report_form.find('label', text: 'Staff').click

        # Export
        export_report

        expect(ListExport.last).to have_rows([
          ['USER/TEAM', 'METRIC', 'GOAL', 'ACTUAL', 'ACTUAL %', 'PENDING', 'PENDING %'],
          ['Juanito Bazooka', 'Events', '1', '1', '1', '2', '2'],
          ['Juanito Bazooka', 'Samples', '50', '25', '0.5', '45', '0.9']
        ])
      end
    end
  end

  def report_form
    find('form#report-settings')
  end

  def choose_campaign(name)
    select_from_chosen(name, from: 'report[campaign_id]')
  end

  def export_report(format = 'XLS')
    with_resque do
      expect do
        click_js_link('Download')
        click_js_link("Download as #{format}")
        wait_for_ajax(10)
        within visible_modal do
          expect(page).to have_content('We are processing your request, the download will start soon...')
        end
        wait_for_ajax(30)
        ensure_modal_was_closed
      end.to change(ListExport, :count).by(1)
    end
  end
end
