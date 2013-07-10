require 'spec_helper'

describe "Teams", js: true, search: true do
  before do
    @user = login
    sign_in @user
    @company = @user.companies.first
  end

  after do
    Warden.test_reset!
  end

  describe "/teams" do
    it "GET index should display a list with the teams" do
      teams = [
        FactoryGirl.create(:team, name: 'Costa Rica Team', description: 'el grupo de ticos', active: true, company_id: @company.id),
        FactoryGirl.create(:team, name: 'San Francisco Team', description: 'the guys from SF', active: true, company_id: @company.id)
      ]
      # Create a few users for each team
      teams[0].users << FactoryGirl.create_list(:company_user, 3, company_id: @company.id)
      teams[1].users << FactoryGirl.create_list(:company_user, 2, company_id: @company.id)
      visit teams_path

      within("ul#teams-list") do
        # First Row
        within("li:nth-child(1)") do
          page.should have_content('Costa Rica Team')
          page.should have_content('3 members')
          page.should have_content('el grupo de ticos')
        end
        # Second Row
        within("li:nth-child(2)") do
          page.should have_content('San Francisco Team')
          page.should have_content('2 members')
          page.should have_content('the guys from SF')
        end
      end

    end

    it 'allows the user to create a new team' do
      visit teams_path

      click_link('Create a team')

      within("form#new_team") do
        fill_in 'Name', with: 'new team name'
        fill_in 'Description', with: 'new team description'
        click_button 'Create Team'
      end

      sleep(1)
      find('h2', text: 'new team name') # Wait for the page to load
      page.should have_selector('h2', text: 'new team name')
      page.should have_selector('div.team-description', text: 'new team description')
    end
  end

  describe "/teams/:team_id", :js => true do
    it "GET show should display the team details page" do
      team = FactoryGirl.create(:team, name: 'Some Team Name', description: 'a team description', company_id: @user.current_company.id)
      visit team_path(team)
      page.should have_selector('h2', text: 'Some Team Name')
      page.should have_selector('div.team-description', text: 'a team description')
    end

    it 'diplays a list of users within the team details page' do
      team = FactoryGirl.create(:team, company_id: @user.current_company.id)
      users = [
        FactoryGirl.create(:user, first_name: 'First1', last_name: 'Last1', company_id: @user.current_company.id, role_id: FactoryGirl.create(:role, company: @company, name: 'Brand Manager').id, city: 'Miami', state:'FL', country:'US', email: 'user1@example.com'),
        FactoryGirl.create(:user, first_name: 'First2', last_name: 'Last2', company_id: @user.current_company.id, role_id: FactoryGirl.create(:role, company: @company, name: 'Staff').id, city: 'Brooklyn', state:'NY', country:'US', email: 'user2@example.com')
      ]
      users.each{|u| u.company_users.each {|cu |team.users << cu.reload } }
      Sunspot.commit
      visit team_path(team)
      within('table#team-members') do
        within("tbody tr:nth-child(1)") do
          find('td:nth-child(1)').should have_content('Last1')
          find('td:nth-child(2)').should have_content('First1')
          find('td:nth-child(3)').should have_content('Brand Manager')
          find('td:nth-child(4)').should have_content('Miami')
          find('td:nth-child(5)').should have_content('Florida')
          find('td:nth-child(6)').should have_content('user1@example.com')
          find('td:nth-child(7)').should have_content('Active')
          find('td:nth-child(8)').should have_content('Remove')
        end
        within("tbody tr:nth-child(2)") do
          find('td:nth-child(1)').should have_content('Last2')
          find('td:nth-child(2)').should have_content('First2')
          find('td:nth-child(3)').should have_content('Staff')
          find('td:nth-child(4)').should have_content('Brooklyn')
          find('td:nth-child(5)').should have_content('New York')
          find('td:nth-child(6)').should have_content('user2@example.com')
          find('td:nth-child(7)').should have_content('Active')
          find('td:nth-child(8)').should have_content('Remove')
        end
      end

    end

    it 'allows the user to activate/deactivate a team' do
      team = FactoryGirl.create(:team, active: true, company_id: @user.current_company.id)
      visit team_path(team)
      within('.active-deactive-toggle') do
        page.should have_selector('a.btn-success.active', text: 'Active')
        page.should have_selector('a', text: 'Inactive')
        page.should_not have_selector('a.btn-danger', text: 'Inactive')

        click_link('Inactive')
        page.should have_selector('a.btn-danger.active', text: 'Inactive')
        page.should have_selector('a', text: 'Active')
        page.should_not have_selector('a.btn-success', text: 'Active')
      end
    end

    it 'allows the user to activate/deactivate a team' do
      team = FactoryGirl.create(:team, active: true, company_id: @user.current_company.id)
      team.reload
      Sunspot.commit
      visit team_path(team)
      team.reload
      within('.active-deactive-toggle') do
        page.should have_selector('a.btn-success.active', text: 'Active')
        page.should have_selector('a', text: 'Inactive')
        page.should_not have_selector('a.btn-danger', text: 'Inactive')

        click_link('Inactive')
        page.should have_selector('a.btn-danger.active', text: 'Inactive')
        page.should have_selector('a', text: 'Active')
        page.should_not have_selector('a.btn-success', text: 'Active')
      end
    end

    it 'allows the user to edit the team' do
      team = FactoryGirl.create(:team, company_id: @company.id)
      Sunspot.commit
      visit team_path(team)

      click_link('Edit')

      within("form#edit_team_#{team.id}") do
        fill_in 'Name', with: 'edited team name'
        fill_in 'Description', with: 'edited team description'
        click_button 'Update Team'
      end

      sleep(1)
      find('h2', text: 'edited team name') # Wait for the page to reload
      page.should have_selector('h2', text: 'edited team name')
      page.should have_selector('div.team-description', text: 'edited team description')
    end


    it 'allows the user to add the users to the team' do
      team = FactoryGirl.create(:team, company_id: @user.current_company.id)
      user = FactoryGirl.create(:user, first_name: 'Fulanito', last_name: 'DeTal', company_id: @user.current_company.id, role_id: FactoryGirl.create(:role, company: @user.current_company, name: 'Brand Manager').id, city: 'Miami', state:'FL', country:'US', email: 'user1@example.com')
      company_user = user.company_users.first
      Sunspot.commit
      visit team_path(team)

      within('table#team-members') do
        page.should_not have_content('Fulanito')
      end

      click_link('Add Team Member')


      within visible_modal do
        find("tr#user-#{company_user.id}").click_js_link('Add')
      end

      modal_footer.click_link 'Close'

      within('table#team-members') do
        page.should have_content('Fulanito')
      end
    end
  end

end