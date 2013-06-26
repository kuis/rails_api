require 'spec_helper'

describe "Events", js: true, search: true do

  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    @company_user = @user.company_users.first
    sign_in @user
  end

  after do
    Warden.test_reset!
  end

  describe "/events", js: true, search: true  do
    it "GET index should display a table with the events" do
      events = [
        FactoryGirl.create(:event, start_date: Date.today.to_s, end_date: Date.today.to_s, start_time: '10:00am', end_time: '11:00pm', campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012'), active: true, place: FactoryGirl.create(:place, name: 'Place 1'), company: @company),
        FactoryGirl.create(:event, start_date: Date.today.to_s, end_date: Date.tomorrow.to_s, start_time: '11:00am',  end_time: '12:00pm', campaign: FactoryGirl.create(:campaign, name: 'Another Campaign April 03'), active: true, place: FactoryGirl.create(:place, name: 'Place 2'), company: @company)
      ]
      Sunspot.commit
      visit events_path

      within("table#events-list") do
        # First Row
        within("tbody tr:nth-child(1)") do
          find('td:nth-child(1)').should have_content(events[0].start_at.strftime('%^a %b %d'))
          find('td:nth-child(1)').should have_content(events[0].start_at.strftime('10:00 AM - 11:00 PM'))
          find('td:nth-child(2)').should have_content(events[0].place_name)
          find('td:nth-child(3)').should have_content(events[0].campaign_name)
          find('td:nth-child(4)').should have_content('Active')
          find('td:nth-child(5)').should have_content('Edit')
          find('td:nth-child(5)').should have_content('Deactivate')
        end
        # Second Row
        within("tbody tr:nth-child(2)") do
          find('td:nth-child(1)').should have_content(events[1].start_at.strftime('%^a %b %d at 11:00 AM'))
          find('td:nth-child(1)').should have_content(events[1].end_at.strftime('%^a %b %d at 12:00 PM'))
          find('td:nth-child(2)').should have_content(events[1].place_name)
          find('td:nth-child(3)').should have_content(events[1].campaign_name)
          find('td:nth-child(4)').should have_content('Active')
          find('td:nth-child(5)').should have_content('Edit')
          find('td:nth-child(5)').should have_content('Deactivate')
        end
      end

      assert_table_sorting ("table#events-list")
    end
  end

  describe "/events/:event_id", :js => true do
    it "GET show should display the event details page" do
      event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012', company: @company), company: @company)
      visit event_path(event)
      page.should have_selector('h2', text: 'Campaign FY2012')
    end

    it "allows to add a member to the event", :js => true do
      event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012', company: @company), company: @company)
      user = FactoryGirl.create(:user, first_name:'Pablo', last_name:'Baltodano', email: 'palinair@gmail.com', company_id: @company.id, role_id: @company_user.role_id)
      company_user = user.company_users.first
      Sunspot.commit

      visit event_path(event)

      click_link 'Add'
      find("table#select-users-list tr#user-#{company_user.id}") # Make sure the lighbox is opened
      within "table#select-users-list tr#user-#{company_user.id}" do
        page.should have_content('Pablo')
        page.should have_content('Baltodano')
        click_js_link('Add')
      end

      # Test the user was added to the list of event members and it can be removed
      within('#event-team-members #event-member-'+company_user.id.to_s) do
        page.should have_content('Pablo Baltodano')
        page.should have_content('palinair@gmail.com')
        #find('a.remove-member-btn').click
      end

      # Test removal of the user
      page.execute_script("$('#event-team-members #event-member-#{company_user.id.to_s} a').click()")
      within('.bootbox.modal.confirm-dialog') do
        page.should have_content('Any tasks that are assigned to Pablo Baltodano must be reassigned. Would you like to remove Pablo Baltodano from the event team?')
        #find('a.btn-primary').click   # The "OK" button
        page.execute_script("$('.bootbox.modal.confirm-dialog a.btn-primary').click()")
      end

      # Refresh the page and make sure the user is not there
      visit event_path(event)
      all('#event-team-members .team-member').count.should == 0
    end

    it "allows to create a new task for the event and mark it as completed" do
      event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign), company: @company)
      user = FactoryGirl.create(:user, company: @company, first_name: 'Juanito', last_name: 'Bazooka')
      company_user = user.company_users.first
      event.users << @company_user
      event.users << user.company_users.first
      Sunspot.commit

      visit event_path(event)

      click_link 'Create Task'
      within('form#new_task') do
        fill_in 'Title', with: 'Pick up the kidz at school'
        fill_in 'Due at', with: '05/16/2013'
        select('Juanito Bazooka', :from => 'Assigned To')
        #click_button 'Create Task'
        page.execute_script("$('form#new_task input[type=submit].btn-primary').click()")
      end

      within('table#tasks-list tbody tr') do
        page.should have_content('Pick up the kidz at school')
        page.should have_content('Juanito Bazooka')
        page.should have_content('THU May 16')
      end

      # Mark the tasks as completed
      within('table#tasks-list') do
        checkbox = find('#task_completed')
        checkbox['checked'].should be_false
        checkbox.click

        # refresh the page to make sure the checkbox remains selected
        visit event_path(event)

        find('#task_completed')['checked'].should be_true
      end

      # Delete Juanito Bazooka from the team and make sure that the tasks list
      # is refreshed and the task unassigned
      page.execute_script("$('#event-member-#{company_user.id.to_s} a.remove-member-btn').click()")
      find('.bootbox.modal.confirm-dialog') # Waits for the dialog to open
      page.execute_script("$('.bootbox.modal.confirm-dialog a.btn-primary').click()")

      # refresh the page to make that the tasks were unassigned
      # TODO: the refresh should not be necessary but it looks like that it's not
      # removing the element from the table automatically in the test
      visit event_path(event)
      within('table#tasks-list') do
        page.should_not have_content('Juanito Bazooka')
      end
    end
  end

end