#
# Ascii art generated with http://patorjk.com/software/taag/#p=display&c=bash&f=Crawford2&t=Task%20Comments
require "spec_helper"
require "cancan/matchers"

describe "User" do
  describe "abilities" do
    subject(:ability){ Ability.new(user) }
    let(:user){ nil }
    let(:company) { FactoryGirl.create(:company) }

    before do
      User.current = user
    end

    context "when it is a super user" do
      let(:user){ FactoryGirl.create(:company_user,  company: company, role: FactoryGirl.create(:role, is_admin: true), user: FactoryGirl.create(:user,  current_company: company)).user }


      it{ should_not be_able_to(:manage, Company) }
      it{ should_not be_able_to(:create, Company) }
      it{ should_not be_able_to(:edit, Company) }
      it{ should_not be_able_to(:destroy, Company) }
      it{ should_not be_able_to(:index, Company) }

      it { should be_able_to(:create, Brand)}
      it { should_not be_able_to(:manage, FactoryGirl.create(:brand))}

      it { should be_able_to(:create, Event) }
      it { should be_able_to(:manage, FactoryGirl.create(:event, company_id: company.id)) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:event, company_id: company.id + 1 )) }

      it { should be_able_to(:create, Team) }
      it { should be_able_to(:manage, FactoryGirl.create(:team, company_id: company.id)) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:team, company_id: company.id + 1 )) }

      it { should be_able_to(:create, Task) }
      it { should be_able_to(:manage, FactoryGirl.create(:task, event: FactoryGirl.create(:event, company_id: company.id))) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:task, event: FactoryGirl.create(:event, company_id: company.id + 1 ))) }

      it { should be_able_to(:create, Area) }
      it { should be_able_to(:manage, FactoryGirl.create(:area, company_id: company.id)) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:area, company_id: company.id + 1 )) }

      it { should be_able_to(:create, BrandPortfolio) }
      it { should be_able_to(:manage, FactoryGirl.create(:brand_portfolio, company_id: company.id)) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:brand_portfolio, company_id: company.id + 1 )) }

      it { should be_able_to(:create, Campaign) }
      it { should be_able_to(:manage, FactoryGirl.create(:campaign, company_id: company.id)) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:campaign, company_id: company.id + 1 )) }

      it { should be_able_to(:create, DateRange) }
      it { should be_able_to(:manage, FactoryGirl.create(:date_range, company_id: company.id)) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:date_range, company_id: company.id + 1 )) }

      it { should be_able_to(:create, DateItem) }
      it { should be_able_to(:manage, FactoryGirl.create(:date_item, date_range:  FactoryGirl.create(:date_range, company_id: company.id))) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:date_item, date_range:  FactoryGirl.create(:date_range, company_id: company.id + 1) )) }

      it { should be_able_to(:create, DayPart) }
      it { should be_able_to(:manage, FactoryGirl.create(:day_part, company_id: company.id)) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:day_part, company_id: company.id + 1 )) }

      it { should be_able_to(:create, DayItem) }
      it { should be_able_to(:manage, FactoryGirl.create(:day_item, day_part:  FactoryGirl.create(:day_part, company_id: company.id))) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:day_item, day_part:  FactoryGirl.create(:day_part, company_id: company.id + 1) )) }

      it { should be_able_to(:create, Kpi) }
      it { should be_able_to(:manage, FactoryGirl.create(:kpi, company_id: company.id)) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:kpi, company_id: company.id + 1 )) }

      it { should be_able_to(:create, Place) }

      it { should be_able_to(:create, EventExpense) }
      it { should be_able_to(:manage, FactoryGirl.create(:event_expense, event: FactoryGirl.create(:event, company_id: company.id))) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:event_expense, event: FactoryGirl.create(:event, company_id: company.id + 1))) }

      it { should be_able_to(:create, Comment) }
      it { should be_able_to(:manage, FactoryGirl.create(:comment, commentable: FactoryGirl.create(:event, company_id: company.id))) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:comment, commentable: FactoryGirl.create(:event, company_id: company.id + 1))) }
      it { should be_able_to(:manage, FactoryGirl.create(:comment, commentable: FactoryGirl.create(:task, event: FactoryGirl.create(:event, company_id: company.id)))) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:comment, commentable: FactoryGirl.create(:task, event: FactoryGirl.create(:event, company_id: company.id + 1)))) }


      it { should be_able_to(:create, AttachedAsset) }
      it { should be_able_to(:manage, FactoryGirl.create(:attached_asset, attachable: FactoryGirl.create(:event, company_id: company.id))) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:attached_asset, attachable: FactoryGirl.create(:event, company_id: company.id + 1))) }

    end

    context "when it is NOT a super user" do
      let(:company_user){ FactoryGirl.create(:company_user,  company: company, role: FactoryGirl.create(:role, is_admin: false), user: FactoryGirl.create(:user,  current_company: company)) }
      let(:user){ company_user.user }


      it { should be_able_to(:notifications, CompanyUser) }


      #     ___ __ __    ___  ____   ______      ______   ____  _____ __  _  _____
      #    /  _]  |  |  /  _]|    \ |      |    |      | /    |/ ___/|  |/ ]/ ___/
      #   /  [_|  |  | /  [_ |  _  ||      |    |      ||  o  (   \_ |  ' /(   \_
      #  |    _]  |  ||    _]|  |  ||_|  |_|    |_|  |_||     |\__  ||    \ \__  |
      #  |   [_|  :  ||   [_ |  |  |  |  |        |  |  |  _  |/  \ ||     \/  \ |
      #  |     |\   / |     ||  |  |  |  |        |  |  |  |  |\    ||  .  |\    |
      #  |_____| \_/  |_____||__|__|  |__|        |__|  |__|__| \___||__|\_| \___|
      #
      describe "Event tasks permissions" do
        it "should be able to edit task in a event if has the permission :edit_task on Event" do
          event = FactoryGirl.create(:event, company: company)
          task = FactoryGirl.create(:task, event: event)
          ability.should_not be_able_to(:edit, task)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:edit_task, Event).save

          ability.should be_able_to(:edit, task)
          ability.should be_able_to(:update, task)
        end

        it "should be able to edit task  if has the permission :edit_my on Task and it's assigned to the user" do
          event = FactoryGirl.create(:event, company: company)
          task = FactoryGirl.create(:task, event: event, company_user: company_user )
          ability.should_not be_able_to(:edit, task)

          user.role.permission_for(:edit_my, Task).save

          ability.should be_able_to(:edit, task)
          ability.should be_able_to(:update, task)
        end

        it "should be able to edit task if has the permission :edit_team on Task and it belongs to a event where the users is a team member" do
          event = FactoryGirl.create(:event, company: company)
          event.users << company_user
          task = FactoryGirl.create(:task, event: event )
          ability.should_not be_able_to(:edit, task)

          user.role.permission_for(:edit_team, Task).save

          ability.should be_able_to(:edit, task)
          ability.should be_able_to(:update, task)
        end

        it "should be able to deactivate a task in a event if has the permission :deactivate_task on Event" do
          event = FactoryGirl.create(:event, company: company)
          task = FactoryGirl.create(:task, event: event)
          ability.should_not be_able_to(:deactivate, task)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:deactivate_task, Event).save

          ability.should be_able_to(:deactivate, task)
          ability.should be_able_to(:activate, task)
        end

        it "should be able to deactivate a task in if has the permission :deactivate_my on Task and it's assigned to the user" do
          event = FactoryGirl.create(:event, company: company)
          task = FactoryGirl.create(:task, event: event, company_user: company_user)
          ability.should_not be_able_to(:deactivate, task)

          user.role.permission_for(:deactivate_my, Task).save

          ability.should be_able_to(:deactivate, task)
          ability.should be_able_to(:activate, task)
        end

        it "should be able to deactivate a task in if has the permission :deactivate_team on Task and it belongs to a event where the users is a team member" do
          event = FactoryGirl.create(:event, company: company)
          event.users << company_user
          task = FactoryGirl.create(:task, event: event)
          ability.should_not be_able_to(:deactivate, task)

          user.role.permission_for(:deactivate_team, Task).save

          ability.should be_able_to(:deactivate, task)
          ability.should be_able_to(:activate, task)
        end

        it "should be able to create a task in a event if has the permission :create_task on Event" do
          event = FactoryGirl.create(:event, company: company)
          task = FactoryGirl.create(:task, event: event)
          ability.should_not be_able_to(:create, task)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:create_task, Event).save

          ability.should be_able_to(:create, task)
        end

        it "should be able to list tasks in a event if has the permission :index_tasks on Event" do
          event = FactoryGirl.create(:event, company: company)
          ability.should_not be_able_to(:tasks, event)
          ability.should_not be_able_to(:index_tasks, event)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:index_tasks, Event).save

          ability.should be_able_to(:tasks, event)
          ability.should be_able_to(:index_tasks, event)
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
      describe "Event documents permissions" do
        it "should be able to deactivate a document in a event if has the permission :deactivate_document on Event" do
          event = FactoryGirl.create(:event, company: company)
          document = FactoryGirl.create(:document, attachable: event)
          ability.should_not be_able_to(:deactivate, document)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:deactivate_document, Event).save

          ability.should be_able_to(:deactivate, document)
          ability.should be_able_to(:activate, document)
        end


        it "should be able to create a document in a event if has the permission :create_document on Event" do
          event = FactoryGirl.create(:event, company: company)
          document = FactoryGirl.create(:document, attachable: event)
          ability.should_not be_able_to(:create, document)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:create_document, Event).save

          ability.should be_able_to(:create, document)
        end


        it "should be able to list document in a event if has the permission :index_documents on Event" do
          event = FactoryGirl.create(:event, company: company)
          ability.should_not be_able_to(:documents, event)
          ability.should_not be_able_to(:index_documents, event)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:index_documents, Event).save

          ability.should be_able_to(:documents, event)
          ability.should be_able_to(:index_documents, event)
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
      describe "Event photos permissions" do
        it "should be able to deactivate a photo in a event if has the permission :deactivate_photo on Event" do
          event = FactoryGirl.create(:event, company: company)
          photo = FactoryGirl.create(:photo, attachable: event)
          ability.should_not be_able_to(:deactivate, photo)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:deactivate_photo, Event).save

          ability.should be_able_to(:deactivate, photo)
          ability.should be_able_to(:activate, photo)
        end


        it "should be able to create a photo in a event if has the permission :create_photo on Event" do
          event = FactoryGirl.create(:event, company: company)
          photo = FactoryGirl.create(:photo, attachable: event)
          ability.should_not be_able_to(:create, photo)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:create_photo, Event).save

          ability.should be_able_to(:create, photo)
        end


        it "should be able to list photo in a event if has the permission :index_photos on Event" do
          event = FactoryGirl.create(:event, company: company)
          ability.should_not be_able_to(:photos, event)
          ability.should_not be_able_to(:index_photos, event)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:index_photos, Event).save

          ability.should be_able_to(:photos, event)
          ability.should be_able_to(:index_photos, event)
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
      describe "Event event expenses permissions" do
        it "should be able to destroy a event expense in a event if has the permission :deactivate_expense on Event" do
          event = FactoryGirl.create(:event, company: company)
          event_expense = FactoryGirl.create(:event_expense, event: event)
          ability.should_not be_able_to(:destroy, event_expense)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:deactivate_expense, Event).save

          ability.should be_able_to(:destroy, event_expense)
        end

        it "should be able to edit event expense in a event if has the permission :edit_expense on Event" do
          event = FactoryGirl.create(:event, company: company)
          event_expense = FactoryGirl.create(:event_expense, event: event)
          ability.should_not be_able_to(:edit, event_expense)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:edit_expense, Event).save

          ability.should be_able_to(:edit, event_expense)
          ability.should be_able_to(:update, event_expense)
        end

        it "should be able to create a event expense in a event if has the permission :create_expense on Event" do
          event = FactoryGirl.create(:event, company: company)
          event_expense = FactoryGirl.create(:event_expense, event: event)
          ability.should_not be_able_to(:create, event_expense)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:create_expense, Event).save

          ability.should be_able_to(:create, event_expense)
        end


        it "should be able to list event expense in a event if has the permission :index_event_expenses on Event" do
          event = FactoryGirl.create(:event, company: company)
          ability.should_not be_able_to(:expenses, event)
          ability.should_not be_able_to(:index_expenses, event)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:index_expenses, Event).save

          ability.should be_able_to(:expenses, event)
          ability.should be_able_to(:index_expenses, event)
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
      describe "Event surveys permissions" do
        it "should be able to deactivate a survey in a event if has the permission :deactivate_survey on Event" do
          event = FactoryGirl.create(:event, company: company)
          survey = FactoryGirl.build(:survey, event: event)
          ability.should_not be_able_to(:deactivate, survey)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:deactivate_survey, Event).save

          ability.should be_able_to(:deactivate, survey)
          ability.should be_able_to(:activate, survey)
        end

        it "should be able to edit survey in a event if has the permission :edit_survey on Event" do
          event = FactoryGirl.create(:event, company: company)
          survey = FactoryGirl.build(:survey, event: event)
          ability.should_not be_able_to(:edit, survey)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:edit_survey, Event).save

          ability.should be_able_to(:edit, survey)
          ability.should be_able_to(:update, survey)
        end

        it "should be able to create a survey in a event if has the permission :create_survey on Event" do
          event = FactoryGirl.create(:event, company: company)
          survey = FactoryGirl.build(:survey, event: event)
          ability.should_not be_able_to(:create, survey)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:create_survey, Event).save

          ability.should be_able_to(:create, survey)
        end


        it "should be able to list survey in a event if has the permission :index_surveys on Event" do
          event = FactoryGirl.create(:event, company: company)
          ability.should_not be_able_to(:surveys, event)
          ability.should_not be_able_to(:index_surveys, event)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:index_surveys, Event).save

          ability.should be_able_to(:surveys, event)
          ability.should be_able_to(:index_surveys, event)
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
      describe "Event comments permissions" do
        it "should be able to deactivate a comment in a event if has the permission :deactivate_comment on Event" do
          event = FactoryGirl.create(:event, company: company)
          comment = FactoryGirl.build(:comment, commentable: event)
          ability.should_not be_able_to(:destroy, comment)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:deactivate_comment, Event).save

          ability.should be_able_to(:destroy, comment)
        end

        it "should be able to edit comment in a event if has the permission :edit_comment on Event" do
          event = FactoryGirl.create(:event, company: company)
          comment = FactoryGirl.build(:comment, commentable: event)
          ability.should_not be_able_to(:edit, comment)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:edit_comment, Event).save

          ability.should be_able_to(:edit, comment)
          ability.should be_able_to(:update, comment)
        end

        it "should be able to create a comment in a event if has the permission :create_comment on Event" do
          event = FactoryGirl.create(:event, company: company)
          comment = FactoryGirl.build(:comment, commentable: event)
          ability.should_not be_able_to(:create, comment)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:create_comment, Event).save

          ability.should be_able_to(:create, comment)
        end

        it "should be able to list comments in a event if has the permission :index_comments on Event" do
          event = FactoryGirl.create(:event, company: company)
          ability.should_not be_able_to(:comments, event)
          ability.should_not be_able_to(:index_comments, event)

          user.role.permission_for(:show, Event).save
          user.role.permission_for(:index_comments, Event).save

          ability.should be_able_to(:comments, event)
          ability.should be_able_to(:index_comments, event)
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
      describe "Task comments permissions" do

        it "should be able to list comments in a task if has the permission :index_my_comments on Task" do
          task = FactoryGirl.create(:task, company_user: company_user)
          ability.should_not be_able_to(:index_my_comments, Task)
          ability.should_not be_able_to(:comments, task)

          user.role.permission_for(:index_my_comments, Task).save

          ability.should be_able_to(:index_my_comments, Task)
          ability.should be_able_to(:comments, task)
        end

        it "should be able to list comments in a task if has the permission :index_team_comments on Task and the tasks is for a event where the user is part of the team" do
          event = FactoryGirl.create(:event)
          event.users << company_user
          task = FactoryGirl.create(:task, event: event)
          ability.should_not be_able_to(:index_team_comments, Task)
          ability.should_not be_able_to(:comments, task)

          user.role.permission_for(:index_team_comments, Task).save

          ability.should be_able_to(:index_team_comments, Task)
          ability.should be_able_to(:comments, task)
        end
      end

    end

  end
end