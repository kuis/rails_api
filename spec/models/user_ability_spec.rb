#
# Ascii art generated with http://patorjk.com/software/taag/#p=display&c=bash&f=Crawford2&t=Task%20Comments
require 'rails_helper'
require 'cancan/matchers'

describe Ability, type: :model do
  describe 'abilities' do
    subject(:ability) { described_class.new(user) }
    let(:user) { nil }
    let(:company) { create(:company) }
    let(:other_company) { create(:company) }
    let(:event) { create(:event, campaign: campaign, company: company, place_id: place.id) }
    let(:event_in_other_company) do
      without_current_user{ create(:event, campaign: create(:campaign), place: create(:place)) }
    end
    let(:place) { create(:place) }
    let(:campaign) { create(:campaign, company: company) }
    let(:venue) { create(:venue, place: place, company: company) }
    let(:venue_in_other_company) { create(:venue, place: place, company: other_company) }
    let(:activity) do
      create(:activity, activity_type: create(:activity_type, company: company),
                        activitable: venue,
                        company_user: create(:company_user,  company: company))
    end
    let(:activity_in_other_company) do
      create(:activity, activity_type: create(:activity_type, company: other_company),
                        activitable: venue_in_other_company,
                        company_user: create(:company_user,  company_id: other_company.id))
    end

    before do
      User.current = user
    end

    context 'when it is a super user' do
      let(:user) do
        create(:company_user, company: company, role: create(:role, is_admin: true),
                              user: create(:user,  current_company: company)).user
      end

      it { is_expected.not_to be_able_to(:manage, Company) }
      it { is_expected.not_to be_able_to(:create, Company) }
      it { is_expected.not_to be_able_to(:edit, Company) }
      it { is_expected.not_to be_able_to(:destroy, Company) }
      it { is_expected.not_to be_able_to(:index, Company) }

      it { is_expected.to be_able_to(:create, Brand) }
      it { is_expected.not_to be_able_to(:manage, without_current_user { create(:brand) }) }

      it { is_expected.to be_able_to(:create, Event) }
      it { is_expected.to be_able_to(:manage, create(:event, campaign: campaign, company: company)) }
      it { is_expected.not_to be_able_to(:manage, without_current_user {  create(:event) }) }

      it { is_expected.to be_able_to(:create, Team) }
      it { is_expected.to be_able_to(:manage, create(:team, company_id: company.id)) }
      it { is_expected.not_to be_able_to(:manage, create(:team, company: other_company)) }

      it { is_expected.to be_able_to(:create, Task) }
      it { is_expected.to be_able_to(:manage, create(:task, event: event)) }
      it { is_expected.not_to be_able_to(:manage, without_current_user {  create(:task, event: event_in_other_company) }) }

      it { is_expected.to be_able_to(:create, Area) }
      it { is_expected.to be_able_to(:manage, create(:area, company_id: company.id)) }
      it { is_expected.not_to be_able_to(:manage, create(:area, company: other_company)) }

      it { is_expected.to be_able_to(:create, ActivityType) }
      it { is_expected.to be_able_to(:manage, create(:activity_type, company: company)) }
      it { is_expected.not_to be_able_to(:manage, create(:activity_type, company: other_company)) }

      it { is_expected.to be_able_to(:create, BrandPortfolio) }
      it { is_expected.to be_able_to(:manage, create(:brand_portfolio, company_id: company.id)) }
      it { is_expected.not_to be_able_to(:manage, create(:brand_portfolio, company: other_company)) }

      it { is_expected.to be_able_to(:create, Campaign) }
      it { is_expected.to be_able_to(:manage, create(:campaign, company_id: company.id)) }
      it { is_expected.not_to be_able_to(:manage, create(:campaign, company: other_company)) }

      it { is_expected.to be_able_to(:create, DateRange) }
      it { is_expected.to be_able_to(:manage, create(:date_range, company_id: company.id)) }
      it { is_expected.not_to be_able_to(:manage, create(:date_range, company: other_company)) }

      it { is_expected.to be_able_to(:create, DateItem) }
      it { is_expected.to be_able_to(:manage, create(:date_item, date_range:  create(:date_range, company_id: company.id))) }
      it { is_expected.not_to be_able_to(:manage, create(:date_item, date_range:  create(:date_range, company_id: company.id + 1))) }

      it { is_expected.to be_able_to(:create, DayPart) }
      it { is_expected.to be_able_to(:manage, create(:day_part, company_id: company.id)) }
      it { is_expected.not_to be_able_to(:manage, create(:day_part, company: other_company)) }

      it { is_expected.to be_able_to(:create, DayItem) }
      it { is_expected.to be_able_to(:manage, create(:day_item, day_part:  create(:day_part, company_id: company.id))) }
      it { is_expected.not_to be_able_to(:manage, create(:day_item, day_part:  create(:day_part, company_id: company.id + 1))) }

      it { is_expected.to be_able_to(:create, Kpi) }
      it { is_expected.to be_able_to(:manage, create(:kpi, company_id: company.id)) }
      it { is_expected.not_to be_able_to(:manage, create(:kpi, company_id: company.id + 1)) }

      it { is_expected.to be_able_to(:create, Place) }

      it { is_expected.to be_able_to(:create, EventExpense) }
      it { is_expected.to be_able_to(:manage, create(:event_expense, event: create(:event, campaign: campaign, company: company))) }
      it { is_expected.not_to be_able_to(:manage, without_current_user {  create(:event_expense, event: create(:event, company: other_company)) }) }

      it { is_expected.to be_able_to(:create, Comment) }
      it { is_expected.to be_able_to(:manage, create(:comment, commentable: event)) }
      it { is_expected.not_to be_able_to(:manage, without_current_user {  create(:comment, commentable: create(:event, company: other_company)) }) }
      it { is_expected.to be_able_to(:manage, create(:comment, commentable: create(:task, event: event))) }
      it { is_expected.not_to be_able_to(:manage, without_current_user { create(:comment, commentable: create(:task, event: event_in_other_company)) }) }

      it { is_expected.to be_able_to(:create, AttachedAsset) }
      it { is_expected.to be_able_to(:manage, create(:attached_asset, attachable: create(:event, campaign: campaign, company: company))) }
      it { is_expected.to be_able_to(:rate, AttachedAsset) }
      it { is_expected.to be_able_to(:view_rate, AttachedAsset) }
      it { is_expected.not_to be_able_to(:manage, without_current_user { create(:attached_asset, attachable: event_in_other_company) }) }

      it { is_expected.to be_able_to(:create, Activity) }
      it { is_expected.to be_able_to(:manage, activity) }
      it { is_expected.not_to be_able_to(:manage, activity_in_other_company) }

      it { is_expected.to be_able_to(:export_fieldable, activity) }
      it { is_expected.not_to be_able_to(:export_fieldable, activity_in_other_company) }

      it { is_expected.to be_able_to(:export_fieldable, event) }
      it { is_expected.not_to be_able_to(:export_fieldable, without_current_user {  create(:event, company_id: other_company.id) }) }

      it { is_expected.to be_able_to(:export_fieldable, campaign) }
      it { is_expected.not_to be_able_to(:export_fieldable, create(:campaign, company: other_company)) }

      it { is_expected.to be_able_to(:export_fieldable, create(:activity_type, company: company)) }
      it { is_expected.not_to be_able_to(:export_fieldable, create(:activity_type, company: other_company)) }
    end

    context 'when it is NOT a super user' do
      let(:company_user) { create(:company_user, company: company, place_ids: [place.id], campaign_ids: [campaign.id], role: create(:role, is_admin: false), user: create(:user,  current_company: company)) }
      let(:user) { company_user.user }

      it { is_expected.to be_able_to(:notifications, CompanyUser) }

      describe 'Event permissions' do
        let(:campaign) { create(:campaign, company: company) }
        let(:event) do
          without_current_user do
            create(:event, campaign: campaign,
                                       place: create(:place))
          end
        end

        it 'should be able to update event if can see the event and has permission :edit_data' do
          expect(ability).not_to be_able_to(:update, event)
          expect(ability).not_to be_able_to(:edit_data, event)

          expect(ability).not_to be_able_to(:update, event_in_other_company)
          expect(ability).not_to be_able_to(:edit_data, event_in_other_company)

          user.role.permission_for(:edit_unsubmitted_data, Event).save

          expect(ability).not_to be_able_to(:edit, event)
          expect(ability).not_to be_able_to(:update, event)
          expect(ability).not_to be_able_to(:edit_data, event)

          user.current_company_user.campaigns << campaign
          user.current_company_user.places << event.place

          expect(ability).to be_able_to(:access, event)
          expect(ability).not_to be_able_to(:access, event_in_other_company)

          expect(ability).to be_able_to(:edit_data, event)
          expect(ability).not_to be_able_to(:edit_data, event_in_other_company)

          expect(ability).not_to be_able_to(:update, event)
          expect(ability).not_to be_able_to(:update, event_in_other_company)

          expect(ability).not_to be_able_to(:edit, Event)
        end

        it 'should be able to :edit Event if the role have the :update permission' do
          expect(ability).not_to be_able_to(:edit, Event)
          user.role.permission_for(:update, Event).save
          expect(ability).to be_able_to(:edit, Event)
        end
      end

      describe 'Campaign permissions' do
        it 'should be able to activate kpis if has the :activate_kpis permission' do
          campaign = create(:campaign, company: company)
          campaign_in_other_comapany = create(:campaign, company: create(:company))

          expect(ability).not_to be_able_to(:add_kpi, campaign)
          expect(ability).not_to be_able_to(:remove_kpi, campaign)

          expect(ability).not_to be_able_to(:add_kpi, campaign_in_other_comapany)
          expect(ability).not_to be_able_to(:remove_kpi, campaign_in_other_comapany)

          user.role.permission_for(:activate_kpis, Campaign).save

          expect(ability).to be_able_to(:add_kpi, campaign)
          expect(ability).to be_able_to(:remove_kpi, campaign)

          expect(ability).not_to be_able_to(:add_kpi, campaign_in_other_comapany)
          expect(ability).not_to be_able_to(:remove_kpi, campaign_in_other_comapany)
        end

        it 'should be able to activate activity types if has the :activate_kpis permission' do
          campaign = create(:campaign, company: company)
          expect(ability).not_to be_able_to(:add_activity_type, campaign)
          expect(ability).not_to be_able_to(:remove_activity_type, campaign)

          user.role.permission_for(:activate_kpis, Campaign).save

          expect(ability).to be_able_to(:add_activity_type, campaign)
          expect(ability).to be_able_to(:remove_activity_type, campaign)
        end
      end

      it { should be_able_to(:verify_phone, company_user) }
      it { should be_able_to(:send_code, company_user) }

      #     ___ __ __    ___  ____   ______      ___ ___    ___  ___ ___  ____     ___  ____    _____
      #    /  _]  |  |  /  _]|    \ |      |    |   |   |  /  _]|   |   ||    \   /  _]|    \  / ___/
      #   /  [_|  |  | /  [_ |  _  ||      |    | _   _ | /  [_ | _   _ ||  o  ) /  [_ |  D  )(   \_
      #  |    _]  |  ||    _]|  |  ||_|  |_|    |  \_/  ||    _]|  \_/  ||     ||    _]|    /  \__  |
      #  |   [_|  :  ||   [_ |  |  |  |  |      |   |   ||   [_ |   |   ||  O  ||   [_ |    \  /  \ |
      #  |     |\   / |     ||  |  |  |  |      |   |   ||     ||   |   ||     ||     ||  .  \ \    |
      #  |_____| \_/  |_____||__|__|  |__|      |___|___||_____||___|___||_____||_____||__|\_|  \___|
      #
      describe 'Event member permissions' do
        it 'should be able to view event members if has the permission :view_members on Event and can view the event' do
          user.role.permission_for(:show, Event).save
          other_event = without_current_user do
            create(:event, campaign: create(:campaign, company: create(:company)))
          end
          expect(ability).not_to be_able_to(:view_members, event)

          user.role.permission_for(:view_members, Event).save

          expect(ability).to be_able_to(:view_members, event)
          expect(ability).not_to be_able_to(:view_members, other_event)
        end

        it 'should be able to add members to event if has the permission :add_members on Event and can view the event' do
          user.role.permission_for(:show, Event).save
          other_event = without_current_user do
            create(:event, campaign: create(:campaign, company: create(:company)))
          end
          expect(ability).not_to be_able_to(:add_members, event)

          user.role.permission_for(:add_members, Event).save

          expect(ability).to be_able_to(:add_members, event)
          expect(ability).not_to be_able_to(:add_members, other_event)
        end

        it 'should be able to remove members from a event if has the permission :delete_member on Event and can view the event' do
          user.role.permission_for(:show, Event).save
          other_event = without_current_user do
            create(:event, campaign: create(:campaign, company: create(:company)))
          end
          expect(ability).not_to be_able_to(:delete_member, event)

          user.role.permission_for(:delete_member, Event).save

          expect(ability).to be_able_to(:delete_member, event)
          expect(ability).not_to be_able_to(:delete_member, other_event)
        end
      end

      #     ___ __ __    ___  ____   ______         __   ___   ____   ______   ____    __ ______  _____
      #    /  _]  |  |  /  _]|    \ |      |       /  ] /   \ |    \ |      | /    |  /  ]      |/ ___/
      #   /  [_|  |  | /  [_ |  _  ||      |      /  / |     ||  _  ||      ||  o  | /  /|      (   \_
      #  |    _]  |  ||    _]|  |  ||_|  |_|     /  /  |  O  ||  |  ||_|  |_||     |/  / |_|  |_|\__  |
      #  |   [_|  :  ||   [_ |  |  |  |  |      /   \_ |     ||  |  |  |  |  |  _  /   \_  |  |  /  \ |
      #  |     |\   / |     ||  |  |  |  |      \     ||     ||  |  |  |  |  |  |  \     | |  |  \    |
      #  |_____| \_/  |_____||__|__|  |__|       \____| \___/ |__|__|  |__|  |__|__|\____| |__|   \___|
      #
      describe 'Event contacts permissions' do
        it 'should be able to view event contacts if has the permission :view_contacts on Event and can view the event' do
          user.role.permission_for(:show, Event).save
          other_event = without_current_user do
            create(:event, campaign: create(:campaign, company: create(:company)))
          end
          expect(ability).not_to be_able_to(:view_contacts, event)

          user.role.permission_for(:view_contacts, Event).save

          expect(ability).to be_able_to(:view_contacts, event)
          expect(ability).not_to be_able_to(:view_contacts, other_event)
        end

        it 'should be able to add contacts to event if has the permission :create_contacts on Event and can view the event' do
          user.role.permission_for(:show, Event).save
          other_event = without_current_user do
            create(:event, campaign: create(:campaign, company: create(:company)))
          end
          expect(ability).not_to be_able_to(:create_contacts, event)

          user.role.permission_for(:create_contacts, Event).save

          expect(ability).to be_able_to(:create_contacts, event)
          expect(ability).not_to be_able_to(:create_contacts, other_event)
        end

        it 'should be able to remove contacts from a event if has the permission :delete_contact on Event and can view the event' do
          user.role.permission_for(:show, Event).save
          other_event = without_current_user do
            create(:event, campaign: create(:campaign, company: create(:company)))
          end
          expect(ability).not_to be_able_to(:delete_contact, event)

          user.role.permission_for(:delete_contact, Event).save

          expect(ability).to be_able_to(:delete_contact, event)
          expect(ability).not_to be_able_to(:delete_contact, other_event)
        end

        it 'should be able to remove contacts from a event if has the permission :delete_contact on Event and can view the event' do
          user.role.permission_for(:show, Event).save
          other_event = without_current_user do
            create(:event, campaign: create(:campaign, company: create(:company)))
          end
          expect(ability).not_to be_able_to(:delete_contact, event)

          user.role.permission_for(:delete_contact, Event).save

          expect(ability).to be_able_to(:delete_contact, event)
          expect(ability).not_to be_able_to(:delete_contact, other_event)
        end
      end

      #     ___ __ __    ___  ____   ______      ______   ____  _____ __  _  _____
      #    /  _]  |  |  /  _]|    \ |      |    |      | /    |/ ___/|  |/ ]/ ___/
      #   /  [_|  |  | /  [_ |  _  ||      |    |      ||  o  (   \_ |  ' /(   \_
      #  |    _]  |  ||    _]|  |  ||_|  |_|    |_|  |_||     |\__  ||    \ \__  |
      #  |   [_|  :  ||   [_ |  |  |  |  |        |  |  |  _  |/  \ ||     \/  \ |
      #  |     |\   / |     ||  |  |  |  |        |  |  |  |  |\    ||  .  |\    |
      #  |_____| \_/  |_____||__|__|  |__|        |__|  |__|__| \___||__|\_| \___|
      #
      describe 'Event tasks permissions' do
        it 'should be able to edit task in a event if has the permission :edit_task on Event' do
          task = create(:task, event: event)
          expect(ability).not_to be_able_to(:edit, task)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:edit_task, Event).save

          expect(ability).to be_able_to(:edit, task)
          expect(ability).to be_able_to(:update, task)
        end

        it "should be able to edit task  if has the permission :edit_my on Task and it's assigned to the user" do
          task = create(:task, event: event, company_user: company_user)
          expect(ability).not_to be_able_to(:edit, task)

          user.role.permission_for(:edit_my, Task).save

          expect(ability).to be_able_to(:edit, task)
          expect(ability).to be_able_to(:update, task)
        end

        it 'should be able to edit task if has the permission :edit_team on Task and it belongs to a event where the users is a team member' do
          event.users << company_user
          task = create(:task, event: event)
          expect(ability).not_to be_able_to(:edit, task)

          user.role.permission_for(:edit_team, Task).save

          expect(ability).to be_able_to(:edit, task)
          expect(ability).to be_able_to(:update, task)
        end

        it 'should be able to deactivate a task in a event if has the permission :deactivate_task on Event' do
          task = create(:task, event: event)
          expect(ability).not_to be_able_to(:deactivate, task)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:deactivate_task, Event).save

          expect(ability).to be_able_to(:deactivate, task)
          expect(ability).to be_able_to(:activate, task)
        end

        it "should be able to deactivate a task in if has the permission :deactivate_my on Task and it's assigned to the user" do
          task = create(:task, event: event, company_user: company_user)
          expect(ability).not_to be_able_to(:deactivate, task)

          user.role.permission_for(:deactivate_my, Task).save

          expect(ability).to be_able_to(:deactivate, task)
          expect(ability).to be_able_to(:activate, task)
        end

        it 'should be able to deactivate a task in if has the permission :deactivate_team on Task and it belongs to a event where the users is a team member' do
          event.users << company_user
          task = create(:task, event: event)
          expect(ability).not_to be_able_to(:deactivate, task)

          user.role.permission_for(:deactivate_team, Task).save

          expect(ability).to be_able_to(:deactivate, task)
          expect(ability).to be_able_to(:activate, task)
        end

        it 'should be able to create a task in a event if has the permission :create_task on Event' do
          task = create(:task, event: event)
          expect(ability).not_to be_able_to(:create, task)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:create_task, Event).save

          expect(ability).to be_able_to(:create, task)
        end

        it 'should be able to list tasks in a event if has the permission :index_tasks on Event' do
          expect(ability).not_to be_able_to(:tasks, event)
          expect(ability).not_to be_able_to(:index_tasks, event)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:index_tasks, Event).save

          expect(ability).to be_able_to(:tasks, event)
          expect(ability).to be_able_to(:index_tasks, event)
        end
      end

      #     ___ __ __    ___  ____   ______      ___     ___     __  __ __  ___ ___    ___  ____   ______  _____
      #    /  _]  |  |  /  _]|    \ |      |    |   \   /   \   /  ]|  |  ||   |   |  /  _]|    \ |      |/ ___/
      #   /  [_|  |  | /  [_ |  _  ||      |    |    \ |     | /  / |  |  || _   _ | /  [_ |  _  ||      (   \_
      #  |    _]  |  ||    _]|  |  ||_|  |_|    |  D  ||  O  |/  /  |  |  ||  \_/  ||    _]|  |  ||_|  |_|\__  |
      #  |   [_|  :  ||   [_ |  |  |  |  |      |     ||     /   \_ |  :  ||   |   ||   [_ |  |  |  |  |  /  \ |
      #  |     |\   / |     ||  |  |  |  |      |     ||     \     ||     ||   |   ||     ||  |  |  |  |  \    |
      #  |_____| \_/  |_____||__|__|  |__|      |_____| \___/ \____| \__,_||___|___||_____||__|__|  |__|   \___|
      #
      describe 'Event documents permissions' do
        it 'should be able to deactivate a document in a event if has the permission :deactivate_document on Event' do
          document = create(:document, attachable: event)
          expect(ability).not_to be_able_to(:deactivate, document)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:deactivate_document, Event).save

          expect(ability).to be_able_to(:deactivate, document)
          expect(ability).to be_able_to(:activate, document)
        end

        it 'should be able to create a document in a event if has the permission :create_document on Event' do
          document = create(:document, attachable: event)
          expect(ability).not_to be_able_to(:create_document, Event)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:create_document, Event).save

          expect(ability).to be_able_to(:create_document, Event)
        end

        it 'should be able to list document in a event if has the permission :index_documents on Event' do
          expect(ability).not_to be_able_to(:documents, event)
          expect(ability).not_to be_able_to(:index_documents, event)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:index_documents, Event).save

          expect(ability).to be_able_to(:documents, event)
          expect(ability).to be_able_to(:index_documents, event)
        end
      end

      #     ___ __ __    ___  ____   ______      ____  __ __   ___   ______   ___   _____
      #    /  _]  |  |  /  _]|    \ |      |    |    \|  |  | /   \ |      | /   \ / ___/
      #   /  [_|  |  | /  [_ |  _  ||      |    |  o  )  |  ||     ||      ||     (   \_
      #  |    _]  |  ||    _]|  |  ||_|  |_|    |   _/|  _  ||  O  ||_|  |_||  O  |\__  |
      #  |   [_|  :  ||   [_ |  |  |  |  |      |  |  |  |  ||     |  |  |  |     |/  \ |
      #  |     |\   / |     ||  |  |  |  |      |  |  |  |  ||     |  |  |  |     |\    |
      #  |_____| \_/  |_____||__|__|  |__|      |__|  |__|__| \___/   |__|   \___/  \___|
      #
      describe 'Event photos permissions' do
        it 'should be able to deactivate a photo in a event if has the permission :deactivate_photo on Event' do
          photo = create(:photo, attachable: event)
          expect(ability).not_to be_able_to(:deactivate, photo)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:deactivate_photo, Event).save

          expect(ability).to be_able_to(:deactivate, photo)
          expect(ability).to be_able_to(:activate, photo)
        end

        it 'should be able to create a photo in a event if has the permission :create_photo on Event' do
          photo = create(:photo, attachable: event)
          expect(ability).not_to be_able_to(:create, AttachedAsset)
          expect(ability).not_to be_able_to(:create, Event)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:create_photo, Event).save

          expect(ability).not_to be_able_to(:create, AttachedAsset)
          expect(ability).to be_able_to(:create_photo, Event)
        end

        it 'should be able to list photo in a event if has the permission :index_photos on Event' do
          expect(ability).not_to be_able_to(:photos, event)
          expect(ability).not_to be_able_to(:index_photos, event)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:index_photos, Event).save

          expect(ability).to be_able_to(:photos, event)
          expect(ability).to be_able_to(:index_photos, event)
        end

        it 'should be able to view rate of the photo' do
          asset = build(:photo, attachable: Event.new(company: company))
          expect(ability).not_to be_able_to(:view_rate, asset)

          user.role.permission_for(:view_rate, AttachedAsset).save

          expect(ability).to be_able_to(:view_rate, asset)
        end

        it 'should be able to rate a photo' do
          asset = build(:photo, attachable: Event.new(company: company))
          expect(ability).not_to be_able_to(:rate, asset)

          user.role.permission_for(:rate, AttachedAsset).save

          expect(ability).to be_able_to(:rate, asset)
        end
      end

      #     ___ __ __    ___  ____   ______        ___  __ __  ____   ___  ____   _____   ___  _____
      #    /  _]  |  |  /  _]|    \ |      |      /  _]|  |  ||    \ /  _]|    \ / ___/  /  _]/ ___/
      #   /  [_|  |  | /  [_ |  _  ||      |     /  [_ |  |  ||  o  )  [_ |  _  (   \_  /  [_(   \_
      #  |    _]  |  ||    _]|  |  ||_|  |_|    |    _]|_   _||   _/    _]|  |  |\__  ||    _]\__  |
      #  |   [_|  :  ||   [_ |  |  |  |  |      |   [_ |     ||  | |   [_ |  |  |/  \ ||   [_ /  \ |
      #  |     |\   / |     ||  |  |  |  |      |     ||  |  ||  | |     ||  |  |\    ||     |\    |
      #  |_____| \_/  |_____||__|__|  |__|      |_____||__|__||__| |_____||__|__| \___||_____| \___|
      #
      describe 'Event event expenses permissions' do
        it 'should be able to destroy a event expense in a event if has the permission :deactivate_expense on Event' do
          event_expense = create(:event_expense, event: event)
          expect(ability).not_to be_able_to(:destroy, event_expense)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:deactivate_expense, Event).save

          expect(ability).to be_able_to(:destroy, event_expense)
        end

        it 'should be able to edit event expense in a event if has the permission :edit_expense on Event' do
          event_expense = create(:event_expense, event: event)
          expect(ability).not_to be_able_to(:edit, event_expense)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:edit_expense, Event).save

          expect(ability).to be_able_to(:edit, event_expense)
          expect(ability).to be_able_to(:update, event_expense)
        end

        it 'should be able to create a event expense in a event if has the permission :create_expense on Event' do
          event_expense = create(:event_expense, event: event)
          expect(ability).not_to be_able_to(:create, event_expense)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:create_expense, Event).save

          expect(ability).to be_able_to(:create, event_expense)
        end

        it 'should be able to list event expense in a event if has the permission :index_event_expenses on Event' do
          expect(ability).not_to be_able_to(:expenses, event)
          expect(ability).not_to be_able_to(:index_expenses, event)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:index_expenses, Event).save

          expect(ability).to be_able_to(:expenses, event)
          expect(ability).to be_able_to(:index_expenses, event)
        end
      end

      #     ___ __ __    ___  ____   ______       _____ __ __  ____  __ __    ___  __ __  _____
      #    /  _]  |  |  /  _]|    \ |      |     / ___/|  |  ||    \|  |  |  /  _]|  |  |/ ___/
      #   /  [_|  |  | /  [_ |  _  ||      |    (   \_ |  |  ||  D  )  |  | /  [_ |  |  (   \_
      #  |    _]  |  ||    _]|  |  ||_|  |_|     \__  ||  |  ||    /|  |  ||    _]|  ~  |\__  |
      #  |   [_|  :  ||   [_ |  |  |  |  |       /  \ ||  :  ||    \|  :  ||   [_ |___, |/  \ |
      #  |     |\   / |     ||  |  |  |  |       \    ||     ||  .  \\   / |     ||     |\    |
      #  |_____| \_/  |_____||__|__|  |__|        \___| \__,_||__|\_| \_/  |_____||____/  \___|
      #
      describe 'Event surveys permissions' do
        it 'should be able to deactivate a survey in a event if has the permission :deactivate_survey on Event' do
          survey = build(:survey, event: event)
          expect(ability).not_to be_able_to(:deactivate, survey)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:deactivate_survey, Event).save

          expect(ability).to be_able_to(:deactivate, survey)
          expect(ability).to be_able_to(:activate, survey)
        end

        it 'should be able to edit survey in a event if has the permission :edit_survey on Event' do
          survey = build(:survey, event: event)
          expect(ability).not_to be_able_to(:edit, survey)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:edit_survey, Event).save

          expect(ability).to be_able_to(:edit, survey)
          expect(ability).to be_able_to(:update, survey)
        end

        it 'should be able to create a survey in a event if has the permission :create_survey on Event' do
          survey = build(:survey, event: event)
          expect(ability).not_to be_able_to(:create, survey)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:create_survey, Event).save

          expect(ability).to be_able_to(:create, survey)
        end

        it 'should be able to list survey in a event if has the permission :index_surveys on Event' do
          expect(ability).not_to be_able_to(:surveys, event)
          expect(ability).not_to be_able_to(:index_surveys, event)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:index_surveys, Event).save

          expect(ability).to be_able_to(:surveys, event)
          expect(ability).to be_able_to(:index_surveys, event)
        end
      end

      #     ___ __ __    ___  ____   ______         __   ___   ___ ___  ___ ___    ___  ____   ______  _____
      #    /  _]  |  |  /  _]|    \ |      |       /  ] /   \ |   |   ||   |   |  /  _]|    \ |      |/ ___/
      #   /  [_|  |  | /  [_ |  _  ||      |      /  / |     || _   _ || _   _ | /  [_ |  _  ||      (   \_
      #  |    _]  |  ||    _]|  |  ||_|  |_|     /  /  |  O  ||  \_/  ||  \_/  ||    _]|  |  ||_|  |_|\__  |
      #  |   [_|  :  ||   [_ |  |  |  |  |      /   \_ |     ||   |   ||   |   ||   [_ |  |  |  |  |  /  \ |
      #  |     |\   / |     ||  |  |  |  |      \     ||     ||   |   ||   |   ||     ||  |  |  |  |  \    |
      #  |_____| \_/  |_____||__|__|  |__|       \____| \___/ |___|___||___|___||_____||__|__|  |__|   \___|
      #
      describe 'Event comments permissions' do
        it 'should be able to deactivate a comment in a event if has the permission :deactivate_comment on Event' do
          comment = build(:comment, commentable: event)
          expect(ability).not_to be_able_to(:destroy, comment)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:deactivate_comment, Event).save

          expect(ability).to be_able_to(:destroy, comment)
        end

        it 'should be able to edit comment in a event if has the permission :edit_comment on Event' do
          comment = build(:comment, commentable: event)
          expect(ability).not_to be_able_to(:edit, comment)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:edit_comment, Event).save

          expect(ability).to be_able_to(:edit, comment)
          expect(ability).to be_able_to(:update, comment)
        end

        it 'should be able to create a comment in a event if has the permission :create_comment on Event' do
          comment = build(:comment, commentable: event)
          expect(ability).not_to be_able_to(:create, comment)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:create_comment, Event).save

          expect(ability).to be_able_to(:create, comment)
        end

        it 'should be able to list comments in a event if has the permission :index_comments on Event' do
          expect(ability).not_to be_able_to(:comments, event)
          expect(ability).not_to be_able_to(:index_comments, event)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:index_comments, Event).save

          expect(ability).to be_able_to(:comments, event)
          expect(ability).to be_able_to(:index_comments, event)
        end
      end

      #     ___ __ __    ___  ____   ______         __   ___   ____   ______   ____    __ ______  _____
      #    /  _]  |  |  /  _]|    \ |      |       /  ] /   \ |    \ |      | /    |  /  ]      |/ ___/
      #   /  [_|  |  | /  [_ |  _  ||      |      /  / |     ||  _  ||      ||  o  | /  /|      (   \_
      #  |    _]  |  ||    _]|  |  ||_|  |_|     /  /  |  O  ||  |  ||_|  |_||     |/  / |_|  |_|\__  |
      #  |   [_|  :  ||   [_ |  |  |  |  |      /   \_ |     ||  |  |  |  |  |  _  /   \_  |  |  /  \ |
      #  |     |\   / |     ||  |  |  |  |      \     ||     ||  |  |  |  |  |  |  \     | |  |  \    |
      #  |_____| \_/  |_____||__|__|  |__|       \____| \___/ |__|__|  |__|  |__|__|\____| |__|   \___|
      #
      describe 'Event contacts permissions' do
        it 'should be able to delete a contact in a event if has the permission :delete_contact on Event' do
          contact = build(:contact_event, event: event)
          expect(ability).not_to be_able_to(:destroy, contact)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:delete_contact, Event).save

          expect(ability).to be_able_to(:destroy, contact)
        end

        it 'should be able to edit comment in a event if has the permission :edit_contacts on Event' do
          contact = build(:contact_event, event: event)
          expect(ability).not_to be_able_to(:edit, contact)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:edit_contacts, Event).save

          expect(ability).to be_able_to(:edit, contact)
          expect(ability).to be_able_to(:update, contact)
        end

        it 'should be able to create a contact in a event if has the permission :create_contacts on Event' do
          contact = build(:contact_event, event: event)
          expect(ability).not_to be_able_to(:create, contact)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:create_contacts, Event).save

          expect(ability).to be_able_to(:create, contact)
          expect(ability).not_to be_able_to(:create, build(:contact_event, event: event_in_other_company))
        end

        it 'should be able to list comments in a event if has the permission :view_contacts on Event' do
          expect(ability).not_to be_able_to(:view_contacts, event)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:view_contacts, Event).save

          expect(ability).to be_able_to(:view_contacts, event)
          expect(ability).not_to be_able_to(:view_contacts, event_in_other_company)
        end
      end

      #   ______   ____  _____ __  _         __   ___   ___ ___  ___ ___    ___  ____   ______  _____
      #  |      | /    |/ ___/|  |/ ]       /  ] /   \ |   |   ||   |   |  /  _]|    \ |      |/ ___/
      #  |      ||  o  (   \_ |  ' /       /  / |     || _   _ || _   _ | /  [_ |  _  ||      (   \_
      #  |_|  |_||     |\__  ||    \      /  /  |  O  ||  \_/  ||  \_/  ||    _]|  |  ||_|  |_|\__  |
      #    |  |  |  _  |/  \ ||     \    /   \_ |     ||   |   ||   |   ||   [_ |  |  |  |  |  /  \ |
      #    |  |  |  |  |\    ||  .  |    \     ||     ||   |   ||   |   ||     ||  |  |  |  |  \    |
      #    |__|  |__|__| \___||__|\_|     \____| \___/ |___|___||___|___||_____||__|__|  |__|   \___|
      #
      describe 'Task comments permissions' do

        it 'should be able to list comments in a task if has the permission :index_my_comments on Task' do
          task = create(:task, company_user: company_user)
          expect(ability).not_to be_able_to(:index_my_comments, Task)
          expect(ability).not_to be_able_to(:comments, task)

          user.role.permission_for(:index_my_comments, Task).save

          expect(ability).to be_able_to(:index_my_comments, Task)
          expect(ability).to be_able_to(:comments, task)
        end

        it 'should be able to list comments in a task if has the permission :index_team_comments on Task and the tasks is for a event where the user is part of the team' do
          company_user.places << place
          event = create(:event, campaign: campaign, company: company, place: place)
          event.users << company_user
          task = create(:task, event: event)
          expect(ability).not_to be_able_to(:index_team_comments, Task)
          expect(ability).not_to be_able_to(:comments, task)

          user.role.permission_for(:index_team_comments, Task).save

          expect(ability).to be_able_to(:index_team_comments, Task)
          expect(ability).to be_able_to(:comments, task)
        end
      end

      #   ___     ____  _____ __ __  ____    ___    ____  ____   ___
      #  |   \   /    |/ ___/|  |  ||    \  /   \  /    ||    \ |   \
      #  |    \ |  o  (   \_ |  |  ||  o  )|     ||  o  ||  D  )|    \
      #  |  D  ||     |\__  ||  _  ||     ||  O  ||     ||    / |  D  |
      #  |     ||  _  |/  \ ||  |  ||  O  ||     ||  _  ||    \ |     |
      #  |     ||  |  |\    ||  |  ||     ||     ||  |  ||  .  \|     |
      #  |_____||__|__| \___||__|__||_____| \___/ |__|__||__|\_||_____|
      #
      describe 'Dashboard permissions' do

        it 'should be able to view calendar module' do
          expect(ability).not_to be_able_to(:calendar_module, :dashboard)
          user.role.permission_for(:calendar_module, Symbol, 'dashboard').save
          expect(ability).to be_able_to(:calendar_module, :dashboard)
        end

        it 'should be able to view kpi trends module' do
          expect(ability).not_to be_able_to(:kpi_trends_module, :dashboard)
          user.role.permission_for(:kpi_trends_module, Symbol, 'dashboard').save
          expect(ability).to be_able_to(:kpi_trends_module, :dashboard)
        end

        it 'should be able to view upcomings events module' do
          expect(ability).not_to be_able_to(:upcomings_events_module, :dashboard)
          user.role.permission_for(:upcomings_events_module, Symbol, 'dashboard').save
          expect(ability).to be_able_to(:upcomings_events_module, :dashboard)
        end

        it 'should be able to view dashboard module' do
          expect(ability).not_to be_able_to(:demographics_module, :dashboard)
          user.role.permission_for(:demographics_module, Symbol, 'dashboard').save
          expect(ability).to be_able_to(:demographics_module, :dashboard)
        end

        it 'should be able to view incomplete task module' do
          expect(ability).not_to be_able_to(:incomplete_tasks_module, :dashboard)
          user.role.permission_for(:incomplete_tasks_module, Symbol, 'dashboard').save
          expect(ability).to be_able_to(:incomplete_tasks_module, :dashboard)
        end

        it 'should be able to view recent photos module' do
          expect(ability).not_to be_able_to(:recent_photos_module, :dashboard)
          user.role.permission_for(:recent_photos_module, Symbol, 'dashboard').save
          expect(ability).to be_able_to(:recent_photos_module, :dashboard)
        end

        it 'should be able to view venue performance module' do
          expect(ability).not_to be_able_to(:venue_performance_module, :dashboard)
          user.role.permission_for(:venue_performance_module, Symbol, 'dashboard').save
          expect(ability).to be_able_to(:venue_performance_module, :dashboard)
        end
      end

      #   ______   ____   ____  _____
      #  |      | /    | /    |/ ___/
      #  |      ||  o  ||   __(   \_
      #  |_|  |_||     ||  |  |\__  |
      #    |  |  |  _  ||  |_ |/  \ |
      #    |  |  |  |  ||     |\    |
      #    |__|  |__|__||___,_| \___|
      #
      describe 'Event photo tag permissions' do
        it 'should be able to deactivate a tag if has the permission :deactivate on Tag' do
          tag = create(:tag, company: company)
          expect(ability).not_to be_able_to(:remove, tag)

          user.role.permission_for(:remove, Tag).save

          expect(ability).to be_able_to(:remove, tag)
        end
        it 'should be able to activate a tag if has the permission :activate on Tag' do
          tag = create(:tag, company: company)
          expect(ability).not_to be_able_to(:activate, tag)

          user.role.permission_for(:activate, Tag).save

          expect(ability).to be_able_to(:activate, tag)
        end

        it 'should NOT be able to activate a tag if has the permission :remove on Tag but not the :activate permission' do
          tag = create(:tag, company: company)
          expect(ability).not_to be_able_to(:activate, tag)

          user.role.permission_for(:remove, Tag).save

          expect(ability).not_to be_able_to(:activate, tag)
        end
      end

      #    ____   ___    ____  _     _____     __ __  _____      ____    __ ______  __ __   ____  _     _____
      #   /    | /   \  /    || |   / ___/    |  |  |/ ___/     /    |  /  ]      ||  |  | /    || |   / ___/
      #  |   __||     ||  o  || |  (   \_     |  |  (   \_     |  o  | /  /|      ||  |  ||  o  || |  (   \_
      #  |  |  ||  O  ||     || |___\__  |    |  |  |\__  |    |     |/  / |_|  |_||  |  ||     || |___\__  |
      #  |  |_ ||     ||  _  ||     /  \ |    |  :  |/  \ |    |  _  /   \_  |  |  |  :  ||  _  ||     /  \ |
      #  |     ||     ||  |  ||     \    |     \   / \    |    |  |  \     | |  |  |     ||  |  ||     \    |
      #  |___,_| \___/ |__|__||_____|\___|      \_/   \___|    |__|__|\____| |__|   \__,_||__|__||_____|\___|
      #
      describe 'GvA reports' do
        it 'should be able to access the GvA report' do
          expect(ability).not_to be_able_to(:gva_report, Campaign)

          user.role.permission_for(:gva_report, Campaign).save

          expect(ability).to be_able_to(:gva_report, Campaign)
        end
        it 'should be able to view the GvA report for a specific campaign' do
          campaign = create(:campaign, company: company)
          other_campaign = create(:campaign)
          expect(ability).not_to be_able_to(:gva_report, Campaign)
          expect(ability).not_to be_able_to(:gva_report_campaign, campaign)

          user.role.permission_for(:gva_report, Campaign).save

          expect(ability).to be_able_to(:gva_report, Campaign)
          expect(ability).not_to be_able_to(:gva_report_campaign, campaign)

          User.current.current_company_user.campaigns << campaign
          User.current.current_company_user.instance_variable_set(:@accessible_campaign_ids,  nil)

          expect(ability).to be_able_to(:gva_report, Campaign)
          expect(ability).to be_able_to(:gva_report_campaign, campaign)
          expect(ability).not_to be_able_to(:gva_report_campaign, other_campaign)
        end
      end

      #     ___ __ __    ___  ____   ______       _____ ______   ____  ______  __ __  _____
      #    /  _]  |  |  /  _]|    \ |      |     / ___/|      | /    ||      ||  |  |/ ___/
      #   /  [_|  |  | /  [_ |  _  ||      |    (   \_ |      ||  o  ||      ||  |  (   \_
      #  |    _]  |  ||    _]|  |  ||_|  |_|     \__  ||_|  |_||     ||_|  |_||  |  |\__  |
      #  |   [_|  :  ||   [_ |  |  |  |  |       /  \ |  |  |  |  _  |  |  |  |  :  |/  \ |
      #  |     |\   / |     ||  |  |  |  |       \    |  |  |  |  |  |  |  |  |     |\    |
      #  |_____| \_/  |_____||__|__|  |__|        \___|  |__|  |__|__|  |__|   \__,_| \___|
      #
      describe 'Event Status report' do
        it 'should be able to access the Event Status report' do
          expect(ability).not_to be_able_to(:gva_report, Campaign)

          user.role.permission_for(:gva_report, Campaign).save

          expect(ability).to be_able_to(:gva_report, Campaign)
        end

        it 'should be able to view the Event Status report for a specific campaign' do
          campaign = create(:campaign, company: company)
          other_campaign = create(:campaign)
          expect(ability).not_to be_able_to(:event_status, Campaign)
          expect(ability).not_to be_able_to(:event_status_report_campaign, campaign)

          user.role.permission_for(:event_status, Campaign).save

          expect(ability).to be_able_to(:event_status, Campaign)
          expect(ability).not_to be_able_to(:event_status_report_campaign, campaign)

          User.current.current_company_user.campaigns << campaign
          User.current.current_company_user.instance_variable_set(:@accessible_campaign_ids,  nil)

          expect(ability).to be_able_to(:event_status, Campaign)
          expect(ability).to be_able_to(:event_status_report_campaign, campaign)
          expect(ability).not_to be_able_to(:event_status_report_campaign, other_campaign)
        end
      end

      #      __  __ __  _____ ______   ___   ___ ___      ____     ___  ____   ___   ____  ______  _____
      #     /  ]|  |  |/ ___/|      | /   \ |   |   |    |    \   /  _]|    \ /   \ |    \|      |/ ___/
      #    /  / |  |  (   \_ |      ||     || _   _ |    |  D  ) /  [_ |  o  )     ||  D  )      (   \_
      #   /  /  |  |  |\__  ||_|  |_||  O  ||  \_/  |    |    / |    _]|   _/|  O  ||    /|_|  |_|\__  |
      #  /   \_ |  :  |/  \ |  |  |  |     ||   |   |    |    \ |   [_ |  |  |     ||    \  |  |  /  \ |
      #  \     ||     |\    |  |  |  |     ||   |   |    |  .  \|     ||  |  |     ||  .  \ |  |  \    |
      #   \____| \__,_| \___|  |__|   \___/ |___|___|    |__|\_||_____||__|   \___/ |__|\_| |__|   \___|
      #
      describe 'Custom Report' do
        it 'should be able to view a list of custom reports' do
          expect(ability).not_to be_able_to(:index, Report)

          user.role.permission_for(:index, Report).save

          expect(ability).to be_able_to(:index, Report)
        end

        it 'should be able to run a custom report that was created by him' do
          report  = company.reports.create(created_by_id: user.id)
          expect(ability).not_to be_able_to(:show, report)

          user.role.permission_for(:show, Report).save

          expect(ability).to be_able_to(:show, report)
        end

        it 'should be able to run a custom report that was shared with him' do
          report  = create(:report, company: company, sharing: 'custom', sharing_selections: ["company_user:#{company_user.id}"])
          report.update_attribute(:created_by_id, user.id + 100)
          non_shared_report  = create(:report, company: company, sharing: 'custom')
          non_shared_report.update_attribute(:created_by_id, user.id + 100)
          expect(ability).not_to be_able_to(:show, report)

          user.role.permission_for(:show, Report).save

          expect(ability).to be_able_to(:show, report)
          expect(ability).not_to be_able_to(:show, non_shared_report)
        end

        it 'should be able to update a custom report if was created by him and has permissions to create reports' do
          report  = create(:report, company: company, created_by_id: user.id)
          expect(ability).not_to be_able_to(:update, report)

          user.role.permission_for(:create, Report).save

          expect(ability).to be_able_to(:update, report)
        end

        it 'should be able to update a custom report if have permissions to update reports' do
          report = without_current_user { create(:report, company: company, created_by_id: user.id + 100) }
          expect(ability).not_to be_able_to(:update, report)
          expect(ability).not_to be_able_to(:edit, report)

          user.role.permission_for(:update, Report).save

          expect(ability).not_to be_able_to(:update, report)
          expect(ability).not_to be_able_to(:edit, report)

          report.update_attributes(sharing: 'custom', sharing_selections: ["company_user:#{company_user.id}"])
          expect(ability).to be_able_to(:update, report)
          expect(ability).to be_able_to(:edit, report)
        end

        it 'should NOT be able to update a custom report if does not have permissions to update reports' do
          report = without_current_user { create(:report, company: company, created_by_id: user.id + 100) }
          expect(ability).not_to be_able_to(:update, report)

          user.role.permission_for(:create, Report).save

          expect(ability).not_to be_able_to(:update, report)
        end

        it 'should be able to edit a custom report that was created by him' do
          report  = create(:report, company: company, created_by_id: user.id)
          expect(ability).not_to be_able_to(:edit, report)
          expect(ability).not_to be_able_to(:update, report)

          user.role.permission_for(:update, Report).save

          expect(ability).to be_able_to(:edit, report)
          expect(ability).to be_able_to(:update, report)
        end

        it 'should be able to edit a custom report that was shared with him' do
          report  = create(:report, company: company)
          report.update_attribute(:created_by_id, user.id + 100)
          expect(ability).not_to be_able_to(:edit, report)
          expect(ability).not_to be_able_to(:update, report)

          user.role.permission_for(:update, Report).save

          expect(ability).not_to be_able_to(:edit, report)
          expect(ability).not_to be_able_to(:update, report)

          report.update_attributes(sharing: 'custom', sharing_selections: ["company_user:#{company_user.id}"])
          expect(ability).to be_able_to(:edit, report)
          expect(ability).to be_able_to(:update, report)
        end

        it 'should be able to share a custom report that was created by him' do
          report  = create(:report, company: company, created_by_id: user.id)
          expect(ability).not_to be_able_to(:share, report)

          user.role.permission_for(:share, Report).save

          expect(ability).to be_able_to(:share, report)
        end

        it 'should be able to share a custom report that was shared with him' do
          report = without_current_user { create(:report, company: company, created_by_id: user.id + 100) }

          expect(ability).not_to be_able_to(:share, report)

          user.role.permission_for(:share, Report).save

          expect(ability).not_to be_able_to(:share, report)

          report.update_attributes(sharing: 'custom', sharing_selections: ["company_user:#{company_user.id}"])
          expect(ability).to be_able_to(:share, report)
        end
      end

      #   ____    ____      ___     ___     __  __ __  ___ ___    ___  ____   ______  _____
      #  |    \  /    |    |   \   /   \   /  ]|  |  ||   |   |  /  _]|    \ |      |/ ___/
      #  |  o  )|  o  |    |    \ |     | /  / |  |  || _   _ | /  [_ |  _  ||      (   \_
      #  |     ||     |    |  D  ||  O  |/  /  |  |  ||  \_/  ||    _]|  |  ||_|  |_|\__  |
      #  |  O  ||  _  |    |     ||     /   \_ |  :  ||   |   ||   [_ |  |  |  |  |  /  \ |
      #  |     ||  |  |    |     ||     \     ||     ||   |   ||     ||  |  |  |  |  \    |
      #  |_____||__|__|    |_____| \___/ \____| \__,_||___|___||_____||__|__|  |__|   \___|
      #
      describe 'Brand ambassador documents permissions' do
        it 'should be able to list documents if has the permission :index on BrandAmbassadors::Document' do
          expect(ability).not_to be_able_to(:index, BrandAmbassadors::Document)

          user.role.permission_for(:index, BrandAmbassadors::Document).save

          expect(ability).to be_able_to(:index, BrandAmbassadors::Document)
        end

        it 'should be able to create/move/edit/destory documents if has the permission :create on BrandAmbassadors::Document' do
          expect(ability).not_to be_able_to(:create, BrandAmbassadors::Document)
          expect(ability).not_to be_able_to(:move, BrandAmbassadors::Document)
          expect(ability).not_to be_able_to(:update, BrandAmbassadors::Document)
          expect(ability).not_to be_able_to(:edit, BrandAmbassadors::Document)
          expect(ability).not_to be_able_to(:destroy, BrandAmbassadors::Document)
          expect(ability).not_to be_able_to(:new, BrandAmbassadors::Document)

          user.role.permission_for(:create, BrandAmbassadors::Document).save

          ability = Ability.new(user)

          expect(ability).to be_able_to(:create, BrandAmbassadors::Document)
          expect(ability).to be_able_to(:move, BrandAmbassadors::Document)
          expect(ability).to be_able_to(:update, BrandAmbassadors::Document)
          expect(ability).to be_able_to(:edit, BrandAmbassadors::Document)
          expect(ability).to be_able_to(:destroy, BrandAmbassadors::Document)
          expect(ability).to be_able_to(:new, BrandAmbassadors::Document)
        end

        it 'should be able to update  documents if has the permission :update on BrandAmbassadors::Document' do
          document = create(:brand_ambassadors_document, attachable: company)
          document_not_allowed = create(:brand_ambassadors_document, attachable: create(:company))
          expect(ability).not_to be_able_to(:update, document)
          expect(ability).not_to be_able_to(:edit, document)

          user.role.permission_for(:update, BrandAmbassadors::Document).save

          expect(ability).to be_able_to(:update, document)
          expect(ability).to be_able_to(:edit, document)

          expect(ability).not_to be_able_to(:update, document_not_allowed)
          expect(ability).not_to be_able_to(:edit, document_not_allowed)
        end

        it 'should be able to activate/deactivate  documents if has the permission :update on BrandAmbassadors::Document' do
          document = BrandAmbassadors::Document.new(attachable: company)
          expect(ability).not_to be_able_to(:deactivate, document)
          expect(ability).not_to be_able_to(:activate, document)

          user.role.permission_for(:deactivate, BrandAmbassadors::Document).save

          expect(ability).to be_able_to(:deactivate, document)
          expect(ability).to be_able_to(:activate, document)
        end
      end
      #   _____   ___   ____   ___ ___        ___  __ __  ____   ___   ____  ______  _____
      #  |     | /   \ |    \ |   |   |      /  _]|  |  ||    \ /   \ |    \|      |/ ___/
      #  |   __||     ||  D  )| _   _ |     /  [_ |  |  ||  o  )     ||  D  )      (   \_
      #  |  |_  |  O  ||    / |  \_/  |    |    _]|_   _||   _/|  O  ||    /|_|  |_|\__  |
      #  |   _] |     ||    \ |   |   |    |   [_ |     ||  |  |     ||    \  |  |  /  \ |
      #  |  |   |     ||  .  \|   |   |    |     ||  |  ||  |  |     ||  .  \ |  |  \    |
      #  |__|    \___/ |__|\_||___|___|    |_____||__|__||__|   \___/ |__|\_| |__|   \___|
      #
      describe 'PDF form exports' do
        it 'can export campaign forms if has the permission :view_event_form on Campaign' do
          expect(ability).not_to be_able_to(:export_fieldable, campaign)

          user.role.permission_for(:view_event_form, Campaign).save

          expect(ability).to be_able_to(:export_fieldable, campaign)
        end

        it 'can export activity types forms if has the permission :show on ActivityType' do
          activity_type = company.activity_types.create(name: 'Prueba')
          expect(ability).not_to be_able_to(:export_fieldable, activity_type)

          user.role.permission_for(:show, ActivityType).save

          expect(ability).to be_able_to(:export_fieldable, activity_type)
        end

        it 'can export activities forms if has the permission :show on Activity' do
          campaign.activity_types << create(:activity_type, company: company)
          event = create(:event, campaign: campaign, place: place)
          activity = create(:activity,
                            activitable: event, company_user: user.company_users.first,
                            activity_type: campaign.activity_types.first)
          expect(ability).not_to be_able_to(:export_fieldable, activity)

          user.role.permission_for(:show, Activity).save

          expect(ability).to be_able_to(:export_fieldable, activity)
        end

        it 'can export post event data forms if can the permission :edit_unsubmitted_data on Event' do
          event = create(:event, campaign: campaign, place: place)
          expect(ability).not_to be_able_to(:export_fieldable, event)

          user.role.permission_for(:edit_unsubmitted_data, Event).save

          expect(ability).to be_able_to(:export_fieldable, event)
        end

        it 'can export post event data forms if can the permission :edit_submitted_data on Event' do
          event = create(:submitted_event, campaign: campaign, place: place)
          expect(ability).not_to be_able_to(:export_fieldable, event)

          user.role.permission_for(:edit_submitted_data, Event).save

          expect(ability).to be_able_to(:export_fieldable, event)
        end

        it 'can export post event data forms if can the permission :edit_approved_data on Event' do
          event = create(:approved_event, campaign: campaign, place: place)
          expect(ability).not_to be_able_to(:export_fieldable, event)

          user.role.permission_for(:edit_approved_data, Event).save

          expect(ability).to be_able_to(:export_fieldable, event)
        end

        it 'can export post event data forms if can the permission :edit_rejected_data on Event' do
          event = create(:rejected_event, campaign: campaign, place: place)
          expect(ability).not_to be_able_to(:export_fieldable, event)

          user.role.permission_for(:edit_rejected_data, Event).save

          expect(ability).to be_able_to(:export_fieldable, event)
        end

        it 'can export post event data forms if can the permission :view_unsubmitted_data on Event' do
          event = create(:event, campaign: campaign, place: place)
          expect(ability).not_to be_able_to(:export_fieldable, event)

          user.role.permission_for(:view_unsubmitted_data, Event).save

          expect(ability).to be_able_to(:export_fieldable, event)
        end

        it 'can export post event data forms if can the permission :view_submitted_data on Event' do
          event = create(:submitted_event, campaign: campaign, place: place)
          expect(ability).not_to be_able_to(:export_fieldable, event)

          user.role.permission_for(:view_submitted_data, Event).save

          expect(ability).to be_able_to(:export_fieldable, event)
        end

        it 'can export post event data forms if can the permission :view_approved_data on Event' do
          event = create(:approved_event, campaign: campaign, place: place)
          expect(ability).not_to be_able_to(:export_fieldable, event)

          user.role.permission_for(:view_approved_data, Event).save

          expect(ability).to be_able_to(:export_fieldable, event)
        end

        it 'can export post event data forms if can the permission :view_rejected_data on Event' do
          event = create(:rejected_event, campaign: campaign, place: place)
          expect(ability).not_to be_able_to(:export_fieldable, event)

          user.role.permission_for(:view_rejected_data, Event).save

          expect(ability).to be_able_to(:export_fieldable, event)
        end
      end


      #   ____  ____   __ __  ____  ______    ___  _____
      #  |    ||    \ |  |  ||    ||      |  /  _]/ ___/
      #   |  | |  _  ||  |  | |  | |      | /  [_(   \_
      #   |  | |  |  ||  |  | |  | |_|  |_||    _]\__  |
      #   |  | |  |  ||  :  | |  |   |  |  |   [_ /  \ |
      #   |  | |  |  | \   /  |  |   |  |  |     |\    |
      #  |____||__|__|  \_/  |____|  |__|  |_____| \___|
      #
      describe 'invites' do
        it 'can create invites on events' do
          event = create(:event, campaign: campaign, place: place)
          expect(ability).not_to be_able_to(:index_invites, event)

          user.role.permission_for(:index_invites, Event).save

          expect(ability).to be_able_to(:index_invites, event)
        end

        it 'can create invites on events' do
          event = create(:event, campaign: campaign, place: place)
          invite = build(:invite, invitable: event)
          expect(ability).not_to be_able_to(:create, invite)

          user.role.permission_for(:create_invite, Event).save

          expect(ability).to be_able_to(:create, invite)
        end

      end
    end
  end
end
