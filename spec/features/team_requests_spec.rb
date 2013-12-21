require 'spec_helper'

feature "Teams", js: true, search: true do
  before do
    @user = login
    sign_in @user
    @company = @user.companies.first
  end

  after do
    Warden.test_reset!
  end

  feature "/teams" do
    scenario "GET index should display a list with the teams" do
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
          expect(page).to have_content('Costa Rica Team')
          expect(page).to have_selector('span.members>b', text: '3')
          expect(page).to have_content('el grupo de ticos')
        end
        # Second Row
        within("li:nth-child(2)") do
          expect(page).to have_content('San Francisco Team')
           expect(page).to have_selector('span.members>b', text: '2')
          expect(page).to have_content('the guys from SF')
        end
      end

    end

    scenario "allows the user to activate/deactivate teams" do
      FactoryGirl.create(:team, name: 'Costa Rica Team', description: 'el grupo de ticos', active: true, company: @company)
      Sunspot.commit

      visit teams_path

      within("ul#teams-list") do
        expect(page).to have_content('Costa Rica Team')
        hover_and_click 'li', 'Deactivate'
      end
      within visible_modal do
        expect(page).to have_content('Are you sure you want to deactivate this team?')
        click_link("OK")
      end
      ensure_modal_was_closed
      within("ul#teams-list") do
        expect(page).to have_no_content('Costa Rica Team')
      end

      # Make it show only the inactive elements
      filter_section('ACTIVE STATE').unicheck('Inactive')
      filter_section('ACTIVE STATE').unicheck('Active')

      within("ul#teams-list") do
        expect(page).to have_content('Costa Rica Team')
        hover_and_click 'li', 'Activate'
        expect(page).to have_no_content('Costa Rica Team')
      end

    end

    it 'allows the user to create a new team' do
      visit teams_path

      click_link('New Team')

      within visible_modal do
        fill_in 'Name', with: 'new team name'
        fill_in 'Description', with: 'new team description'
        click_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'new team name') # Wait for the page to load
      expect(page).to have_selector('h2', text: 'new team name')
      expect(page).to have_selector('div.description-data', text: 'new team description')
    end
  end

  feature "/teams/:team_id", :js => true do
    scenario "GET show should display the team details page" do
      team = FactoryGirl.create(:team, name: 'Some Team Name', description: 'a team description', company_id: @user.current_company.id)
      visit team_path(team)
      expect(page).to have_selector('h2', text: 'Some Team Name')
      expect(page).to have_selector('div.description-data', text: 'a team description')
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
      within('#team-members-list') do
        within("div.team-member:nth-child(1)") do
          expect(page).to have_content('First1 Last1')
          expect(page).to have_content('Brand Manager')
          expect(page).to have_selector('a.remove-member-btn', visible: false)
        end
        within("div.team-member:nth-child(2)") do
          expect(page).to have_content('First2 Last2')
          expect(page).to have_content('Staff')
          expect(page).to have_selector('a.remove-member-btn', visible: false)
        end
      end

    end

    it 'allows the user to activate/deactivate a team' do
      team = FactoryGirl.create(:team, active: true, company_id: @user.current_company.id)
      visit team_path(team)
      within('.links-data') do
         click_link('Deactivate')
       end
       within visible_modal do
        expect(page).to have_content("Are you sure you want to deactivate this team?")
        click_link("OK")
      end
       ensure_modal_was_closed
       within('.links-data') do
         click_link('Activate')
         expect(page).to have_link('Deactivate') # test the link have changed
       end
    end

    it 'allows the user to edit the team' do
      team = FactoryGirl.create(:team, company_id: @company.id)
      Sunspot.commit
      visit team_path(team)

      click_link('Edit')

      within visible_modal do
        fill_in 'Name', with: 'edited team name'
        fill_in 'Description', with: 'edited team description'
        click_button 'Save'
      end

      find('h2', text: 'edited team name') # Wait for the page to reload
      expect(page).to have_selector('h2', text: 'edited team name')
      expect(page).to have_selector('div.description-data', text: 'edited team description')
    end


    it 'allows the user to add the users to the team' do
      team = FactoryGirl.create(:team, company_id: @user.current_company.id)
      user = FactoryGirl.create(:user, first_name: 'Fulanito', last_name: 'DeTal', company_id: @user.current_company.id, role_id: FactoryGirl.create(:role, company: @user.current_company, name: 'Brand Manager').id, city: 'Miami', state:'FL', country:'US', email: 'user1@example.com')
      company_user = user.company_users.first
      Sunspot.commit
      visit team_path(team)

      expect(page).to_not have_content('Fulanito')

      click_link('Add Team Member')


      within visible_modal do
        find("#staff-member-user-#{company_user.id}").click_link('Add')
      end

      close_modal

      within('#team-members-list')  do
        expect(page).to have_content('Fulanito')
      end
    end
  end

end