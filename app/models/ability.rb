class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)


    alias_action :activate, :to => :deactivate
    alias_action :new_member, :to => :add_members

    # All users

    if user.id && !user.is_a?(AdminUser)
      can :find_similar_kpi, Campaign do
        can?(:update, Campaign) || can?(:create, Campaign)
      end

      can [:create, :update], Goal do |goal|
        can?(:edit, goal.goalable)
      end

      can :time_zone_change, CompanyUser
      can [:notifications, :select_company], CompanyUser

      # All users can update their own information
      can :update, CompanyUser, id: user.current_company_user.id
      can :update, Campaign, id: user.current_company_user.id

      can :super_update, CompanyUser do |cu|
        user.current_company_user.role.is_admin? || user.current_company_user.role.has_permission?(:update, CompanyUser)
      end

      can [:enable_campaigns, :disable_campaigns, :remove_campaign, :select_campaigns, :add_campaign], CompanyUser do |cu|
        can?(:edit, cu)
      end
    end

    # AdminUsers (logged in on Active Admin)
    if user.is_a?(AdminUser)
      # ActiveAdmin users
      can :manage, :all

    # Super Admin Users
    elsif user.is_super_admin?
      can :manage, :dashboard

      # Super Admin Users can manage any object on the same company
      can do |action, subject_class, subject|
        Rails.logger.debug "Checking #{action} on #{subject_class.to_s} :: #{subject}"
        subject.nil? || ( subject.respond_to?(:company_id) && ((subject.company_id.nil? && [:create, :new].include?(action)) || subject.company_id == user.current_company.id) )
      end

      cannot do |action, subject_class, subject|
        [Company].include?(subject_class)
      end

      # Other permissions
      can [:index, :create], Brand

      can [:new, :create], Kpi do |kpi|
        can?(:edit, Campaign)
      end

      # Special permission to allow editing global kpis (for goals setting)
      can [:edit, :update], Kpi do |kpi|
        kpi.company_id.nil? && can?(:edit, Campaign)
      end

      can :edit_data, Event

    # A logged in user
    elsif user.id
      can do |action, subject_class, subject|
        Rails.logger.debug "Checking #{action} on #{subject_class.to_s} :: #{subject}"
        user.role.permissions.select{|p| aliases_for_action(action).include?(p.action.to_sym)}.any? do |permission|
          permission.subject_class == subject_class.to_s &&
          (   subject.nil? ||
            ( subject.respond_to?(:company_id) && ((subject.company_id.nil? && [:create, :new].include?(action)) || subject.company_id == user.current_company.id) ) ||
            ( permission.subject_id.nil? || (subject.respond_to?(:id) ? permission.subject_id == subject.id : permission.subject_id == subject.to_s) )
          )
        end
      end

      can :index, Event if can?(:view_list, Event) || can?(:view_map, Event)

      # Event Data
      can :edit_data, Event do |event|
       (event.unsent? && can?(:edit_unsubmitted_data, event)) ||
       (event.submitted? && can?(:edit_submitted_data, event)) ||
       (event.approved? && can?(:edit_approved_data, event)) ||
       (event.rejected? && can?(:edit_rejected_data, event))
      end

      can :view_data, Event do |event|
       (event.unsent? && can?(:view_unsubmitted_data, event)) ||
       (event.submitted? && can?(:view_submitted_data, event)) ||
       (event.approved? && can?(:view_approved_data, event)) ||
       (event.rejected? && can?(:view_rejected_data, event))
      end

      cannot [:show, :edit], Event do |event|
        !user.current_company_user.accessible_campaign_ids.include?(event.campaign_id) ||
        (
          !Place.locations_for_index(event.place).any?{|location| user.current_company_user.accessible_locations.include?(location)} &&
          !user.current_company_user.accessible_places.include?(event.place_id)
        )
      end

      can [:select_brands, :add_brands], BrandPortfolio do |brand_portfolio|
        can?(:edit, brand_portfolio)
      end

      can :create, Brand do
        can?(:edit, BrandPortfolio)
      end

      # Team Members
      can [:add_members, :delete_member], Team do |team|
        can?(:edit, team)
      end

      # Tasks permissions
      can :tasks, Event do |event|
        user.role.has_permission?(:index_tasks, Event) && can?(:show, event)
      end

      can :update, Task do |task|
        (user.role.has_permission?(:edit_task, Event) && can?(:show, task.event)) ||
        (user.role.has_permission?(:edit_my, Task) && task.company_user_id == user.current_company_user.id) ||
        (user.role.has_permission?(:edit_team, Task) && task.company_user_id != user.current_company_user.id && task.event.user_in_team?(user.current_company_user))
      end

      can [:deactivate, :activate], Task do |task|
        (user.role.has_permission?(:deactivate_task, Event) && can?(:show, task.event)) ||
        (user.role.has_permission?(:deactivate_my, Task) && task.company_user_id == user.current_company_user.id) ||
        (user.role.has_permission?(:deactivate_team, Task) && task.company_user_id != user.current_company_user.id && task.event.user_in_team?(user.current_company_user))
      end

      can :create, Task do |task|
        user.role.has_permission?(:create_task, Event) && can?(:show, task.event)
      end

      # Documents permissions
      can :documents, Event do |event|
        user.role.has_permission?(:index_documents, Event) && can?(:show, event)
      end

      can :create, AttachedAsset do |asset|
        asset.attachable.is_a?(Event) && asset.asset_type == 'document' && user.role.has_permission?(:create_document, Event) && can?(:show, asset.attachable)
      end

      can [:deactivate, :activate], AttachedAsset do |asset|
        asset.attachable.is_a?(Event) && asset.asset_type == 'document' && user.role.has_permission?(:deactivate_document, Event) && can?(:show, asset.attachable)
      end

      # Photos permissions
      can :photos, Event do |event|
        user.role.has_permission?(:index_photos, Event) && can?(:show, event)
      end

      can :create, AttachedAsset do |asset|
        asset.attachable.is_a?(Event) && asset.asset_type == 'photo' && user.role.has_permission?(:create_photo, Event) && can?(:show, asset.attachable)
      end

      can [:deactivate, :activate], AttachedAsset do |asset|
        asset.attachable.is_a?(Event) && asset.asset_type == 'photo' && user.role.has_permission?(:deactivate_photo, Event) && can?(:show, asset.attachable)
      end

      # Event Expenses permissions
      can :expenses, Event do |event|
        user.role.has_permission?(:index_expenses, Event) && can?(:show, event)
      end

      can :update, EventExpense do |expense|
        user.role.has_permission?(:edit_expense, Event) && can?(:show, expense.event)
      end

      can :destroy, EventExpense do |expense|
        user.role.has_permission?(:deactivate_expense, Event) && can?(:show, expense.event)
      end

      can :create, EventExpense do |expense|
        user.role.has_permission?(:create_expense, Event) && can?(:show, expense.event)
      end

      # Surveys permissions
      can :surveys, Event do |event|
        user.role.has_permission?(:index_surveys, Event) && can?(:show, event)
      end

      can :update, Survey do |survey|
        user.role.has_permission?(:edit_survey, Event) && can?(:show, survey.event)
      end

      can :edit_surveys, Event do |event|
        (user.role.has_permission?(:edit_survey, Event) || user.role.has_permission?(:create_survey, Event)) && can?(:show, event)
      end

      can [:deactivate, :activate], Survey do |survey|
        user.role.has_permission?(:deactivate_survey, Event) && can?(:show, survey.event)
      end

      can :create, Survey do |survey|
        user.role.has_permission?(:create_survey, Event) && can?(:show, survey.event)
      end

      # Comments permissions
      can :comments, Event do |event|
        user.role.has_permission?(:index_comments, Event) && can?(:show, event)
      end
      can :comments, Task do |task|
        (user.role.has_permission?(:index_my_comments, Task) && task.company_user_id == user.current_company_user.id) ||
        (user.role.has_permission?(:index_team_comments, Task) && task.company_user_id != user.current_company_user.id && task.event.user_in_team?(user.current_company_user) )
      end

      can :update, Comment do |comment|
        user.role.has_permission?(:edit_comment, Event) && can?(:show, comment.commentable)
      end

      can :destroy, Comment do |comment|
        user.role.has_permission?(:deactivate_comment, Event) && can?(:show, comment.commentable)
      end

      can :create, Comment do |comment|
        (comment.commentable.is_a?(Event) && user.role.has_permission?(:create_comment, Event) && can?(:show, comment.commentable)) ||
        (comment.commentable.is_a?(Task) && user.role.has_permission?(:create_my_comment, Task) && comment.commentable.company_user_id == user.current_company_user.id) ||
        (comment.commentable.is_a?(Task) && user.role.has_permission?(:create_team_comment, Task) && comment.commentable.event.user_in_team?(user.current_company_user))
      end

      can :reject, Event do |event|
        can?(:approve, event)
      end
    end
  end
end
