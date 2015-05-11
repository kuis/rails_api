require 'rails_helper'

feature 'Events section' do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { create(:place, name: 'A Nice Place', country: 'CR', city: 'Curridabat', state: 'San Jose') }
  let(:permissions) { [] }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end
  after { Warden.test_reset! }

  shared_examples_for 'a user that can attach expenses to events' do
    let(:event) { create(:due_event, campaign: campaign, place: place) }
    let(:brand1) { create(:brand, name: 'Brand 1', company_id: company.id) }
    let(:brand2) { create(:brand, name: 'Brand 2', company_id: company.id) }

    before do
      Kpi.create_global_kpis
      campaign.brands << [brand1, brand2]
      event.campaign.update_attribute(:modules, 'expenses' => {})
    end
    scenario 'can attach a expense to event' do
      with_resque do # So the document is processed
        visit event_path(event)

        click_js_button 'Add Expense'

        within visible_modal do
          attach_file 'file', 'spec/fixtures/file.pdf'

          # Test validations
          click_js_button 'Save'
          expect(find_field('Name')).to have_error('This field is required.')

          fill_in 'Name', with: 'test expense'
          select_from_chosen 'Brand 2', from: 'Brand'
          expect(page).to have_content('File attached: file.pdf')

          wait_for_photo_to_process 15 do
            click_js_button 'Save'
          end
        end
        ensure_modal_was_closed

        within '#event-expenses' do
          expect(page).to have_content('test expense')
        end
        asset = AttachedAsset.last
        expect(asset.file_file_name).to eql 'file.pdf'

        # Test user can preview and download the receipt
        hover_and_click '#expenses-list [id^="event_expense"]', 'View Receipt'

        within visible_modal do
          src = asset.preview_url(:medium, timestamp: false)
          expect(page).to have_xpath("//img[starts-with(@src, \"#{src}\")]", wait: 10)
          find('.slider').hover

          src = asset.file.url(:original, timestamp: false).gsub('http:', 'https:')
          expect(page).to have_link('Download')
          expect(page).to have_xpath("//a[starts-with(@href, \"#{src}\")]")
        end
      end
    end
  end

  feature 'admin user', js: true, search: true do
    let(:role) { create(:role, company: company) }

    it_behaves_like 'a user that can attach expenses to events'
  end
end
