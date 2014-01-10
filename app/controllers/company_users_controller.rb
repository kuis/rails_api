class CompanyUsersController < FilteredController
  include DeactivableHelper

  respond_to :js, only: [:new, :create, :edit, :update, :time_zone_change,:time_zone_update ]
  respond_to :json, only: [:index, :notifications]

  helper_method :brands_campaigns_list

  custom_actions collection: [:complete, :time_zone_change, :time_zone_update]

  before_filter :validate_parent, only: [:enable_campaigns, :disable_campaigns, :remove_campaign, :select_campaigns, :add_campaign]

  skip_load_and_authorize_resource only: [:export_status]

  caches_action :notifications, expires_in: 15.minutes, cache_path: Proc.new { {company_user_id: current_company_user.id} }

  def autocomplete
    buckets = autocomplete_buckets({
      users: [CompanyUser],
      teams: [Team],
      roles: [Role],
      campaigns: [Campaign],
      places: [Venue]
    })

    render :json => buckets.flatten
  end

  def update
    resource.user.updating_user = true if can?(:super_update, resource)
    update! do |success, failure|
      success.js {
        if resource.user.id == current_user.id
          sign_in resource.user, :bypass => true
        elsif resource.invited_to_sign_up?
          resource.user.accept_invitation!
        end
      }
    end
  end

  def time_zone_change
    current_user.update_column(:detected_time_zone, params[:time_zone])
  end

  def time_zone_update
    current_user.update_column(:time_zone, params[:time_zone])
    render nothing: true
  end

  def select_company
    begin
      company_user = current_user.company_users.find_by_company_id_and_active(params[:company_id], true) or raise ActiveRecord::RecordNotFound
      current_user.current_company = company_user.company
      current_user.update_column(:current_company_id, company_user.company.id)
      session[:current_company_id] = company_user.company_id
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "You are not allowed login into this company"
    end
    redirect_to root_path
  end

  def enable_campaigns
    if params[:parent_type] && params[:parent_id]
      parent_membership = resource.memberships.find_or_create_by_memberable_type_and_memberable_id(params[:parent_type], params[:parent_id])
      @parent = parent_membership.memberable
      @campaigns = @parent.campaigns
      # Delete all campaign associations assigned to this user directly under this brand/portfolio
      resource.memberships.where(parent_id: parent_membership.memberable.id, parent_type: parent_membership.memberable.class.name).destroy_all
    end
  end

  def disable_campaigns
    if params[:parent_type] && params[:parent_id]
      membership = resource.memberships.find_by_memberable_type_and_memberable_id(params[:parent_type], params[:parent_id])
      unless membership.nil?
        resource.memberships.where(parent_id: membership.memberable.id, parent_type: membership.memberable.class.name).destroy_all
        # Assign all the campaings directly to the user
        membership.memberable.campaigns.each do |campaign|
          resource.memberships.create({memberable: campaign, parent: membership.memberable}, without_protection: true)
        end
        membership.destroy
      end
    end
    render text: 'OK'
  end

  def remove_campaign
    if params[:campaign_id]
      if params[:parent_type]
        membership = resource.memberships.where(memberable_type: params[:parent_type], memberable_id: params[:parent_id]).first
      else
        membership = nil
      end
      # If the parent is directly assigned to the user, then remove the parent and assign all the
      # current campaigns to the user
      unless membership.nil?
        membership.memberable.campaigns.scoped_by_company_id(current_company.id).each do |campaign|
          unless campaign.id == params[:campaign_id].to_i
            resource.memberships.create({memberable: campaign, parent: membership.memberable}, without_protection: true)
          end
        end
        membership.destroy
      else
        membership = resource.memberships.where(parent_type: params[:parent_type], parent_id: params[:parent_id], memberable_type: 'Campaign', memberable_id: params[:campaign_id]).destroy_all
      end
    end
  end

  def select_campaigns
    @campaigns = []
    if params[:parent_type] && params[:parent_id]
      membership = resource.memberships.where(memberable_type: params[:parent_type], memberable_id: params[:parent_id]).first
      if membership.nil?
        parent = params['parent_type'].constantize.find(params['parent_id'])
        @campaigns = parent.campaigns.scoped_by_company_id(current_company.id).where(['campaigns.id not in (?)', resource.campaigns.children_of(parent).map(&:id)+[0]])
      end
    end
  end

  def add_campaign
    if params[:parent_type] && params[:parent_id] && params[:campaign_id]
      @parent = params['parent_type'].constantize.find(params['parent_id'])
      campaign = current_company.campaigns.find(params[:campaign_id])
      resource.memberships.create({memberable: campaign, parent: @parent}, without_protection: true)
      @campaigns = resource.campaigns.children_of(@parent)
    end
  end

  def export_status
    url = nil
    export = ListExport.find_by_id_and_company_user_id(params[:download_id], current_company_user.id)
    url = export.download_url if export.completed? && export.file_file_name
    respond_to do |format|
      format.json { render json:  {status: export.aasm_state, progress: export.progress, url: url} }
    end
  end

  def notifications
    alerts = []
    user = current_company_user

    # Gets the counts with a single Solr request
    status_counts = {late: 0, due: 0, submitted: 0, rejected: 0}
    events_search = Event.do_search({company_id: user.company_id, status: ['Active'], user: [user.id], team: user.team_ids}, true)
    events_search.facet(:status).rows.each{|r| status_counts[r.value] = r.count }
    # Due event recaps
    if status_counts[:due] > 0
      alerts.push({message: I18n.translate('notifications.event_recaps_due', count: status_counts[:due]), level: 'grey', url: events_path(user: [user.id], status: ['Active'], event_status: ['Due'], start_date: '', end_date: ''), unread: true, icon: 'icon-notification-event'})
    end

    # Late event recaps
    if status_counts[:late] > 0
      alerts.push({message: I18n.translate('notifications.event_recaps_late', count: status_counts[:late]), level: 'red', url: events_path(user: [user.id], status: ['Active'], event_status: ['Late'], start_date: '', end_date: ''), unread: true, icon: 'icon-notification-event'})
    end

    # Recaps pending approval
    if status_counts[:submitted] > 0
      alerts.push({message: I18n.translate('notifications.recaps_prending_approval', count: status_counts[:submitted]), level: 'blue', url: events_path(user: [user.id], status: ['Active'], event_status: ['Submitted'], start_date: '', end_date: ''), unread: true, icon: 'icon-notification-event'})
    end

    # Rejected recaps
    if status_counts[:rejected] > 0
      alerts.push({message: I18n.translate('notifications.rejected_recaps', count: status_counts[:rejected]), level: 'red', url: events_path(user: [user.id], status: ['Active'], event_status: ['Rejected'], start_date: '', end_date: ''), unread: true, icon: 'icon-notification-event'})
    end

    # User's teams late tasks
    count = Task.do_search({company_id: current_company.id, status: ['Active'], task_status: ['Late'], team_members: [user.id], not_assigned_to: [user.id]}).total
    if count > 0
      alerts.push({message: I18n.translate('notifications.task_late_team', count: count), level: 'red', url: my_teams_tasks_path(status: ['Active'], task_status: ['Late'], team_members: [user.id], not_assigned_to: [user.id], start_date: '', end_date: ''), unread: true, icon: 'icon-notification-task'})
    end

    # User's late tasks
    count = Task.do_search({company_id: current_company.id, status: ['Active'], task_status: ['Late'], user: [user.id]}).total
    if count > 0
      alerts.push({message: I18n.translate('notifications.task_late_user', count: count), level: 'red', url: mine_tasks_path(user: [user.id], status: ['Active'], task_status: ['Late'], start_date: '', end_date: ''), unread: true, icon: 'icon-notification-task'})
    end

    # Unread comments in user's tasks
    tasks = Task.select('id, title').where("id in (#{Comment.select('commentable_id').not_from(user.user).for_tasks_assigned_to(user).unread_by(user.user).to_sql})")
    user_tasks = [0]
    tasks.find_each do |task|
      alerts.push({message: I18n.translate('notifications.unread_tasks_comments_user', task: task.title), level: 'grey', url: mine_tasks_path(q: "task,#{task.id}", anchor: "comments-#{task.id}"), unread: true, icon: 'icon-notification-comment'})
      user_tasks.push task.id
    end

    # Unread comments in user teams' tasks
    tasks = Task.select('id, title').where("id not in (?)", user_tasks).where("id in (#{Comment.select('commentable_id').not_from(user.user).for_tasks_where_user_in_team(user).unread_by(user.user).to_sql})")
    tasks.find_each do |task|
      alerts.push({message: I18n.translate('notifications.unread_tasks_comments_team', task: task.title), level: 'grey', url: my_teams_tasks_path(q: "task,#{task.id}", anchor: "comments-#{task.id}"), unread: true, icon: 'icon-notification-comment'})
    end

    user.notifications.find_each do |notification|
      alerts.push({message: I18n.translate("notifications.#{notification.message}", notification.message_params), level: notification.level, url: notification.path + (notification.path.index('?').nil? ?  "?" : '&') + "notifid=#{notification.id}" , unread: true, icon: 'icon-notification-'+ notification.icon})
    end

    render json: alerts
  end

  protected
    def permitted_params
      allowed = {company_user: [{user_attributes: [:id, :first_name, :last_name, :email, :phone_number, :password, :password_confirmation, :country, :state, :city, :street_address, :unit_number, :zip_code, :time_zone]}] }
      if params[:id].present? && can?(:super_update, CompanyUser.find(params[:id]))
        allowed[:company_user] += [:role_id, {team_ids: []}]
      end
      params.permit(allowed)[:company_user]
    end

    def roles
      @roles ||= current_company.roles
    end

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| %w(q company_id current_company_user).include?(k)})
        facet_search = resource_class.do_search(facet_params, true)

        f.push build_role_bucket facet_search
        f.push build_campaign_bucket facet_search
        f.push build_team_bucket facet_search
        # f.push(label: "Active State", items: facet_search.facet(:status).rows.map{|x| build_facet_item({label: x.value, id: x.value, name: :status, count: x.count}) })
        f.push build_state_bucket
      end
    end

    def build_role_bucket facet_search
      items = facet_search.facet(:role).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :role}) }
      items = items.sort{|a, b| a[:label] <=> b[:label]}
      {label: "Roles", items: items}
    end

    def build_team_bucket facet_search
      items = facet_search.facet(:teams).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :team}) }
      items = items.sort{|a, b| a[:label] <=> b[:label]}
      {label: "Teams", items: items}
    end

    def build_state_bucket
      items = ['Active', 'Inactive', 'Invited'].map{|x| build_facet_item({label: x, id: x, name: :status, count: 1}) }
      items = items.sort{|a, b| a[:label] <=> b[:label]}
      {label: "Active State", items: items}
    end

    def delete_member_path(user)
      path = nil
      path = delete_member_team_path(params[:team], member_id: user.id) if params.has_key?(:team) && params[:team]
      path = delete_member_campaign_path(params[:campaign], member_id: user.id) if params.has_key?(:campaign) && params[:campaign]
      path
    end

    def brands_campaigns_list
      list = {}
      current_company.brand_portfolios.each do |portfolio|
        enabled = resource.brand_portfolios.include?(portfolio)
        list[portfolio] = {enabled: enabled, campaigns: (enabled ? portfolio.campaigns.scoped_by_company_id(current_company.id) : resource.campaigns.scoped_by_company_id(current_company.id).children_of(portfolio) ) }
      end
      Brand.for_company_campaigns(current_company).each do |brand|
        enabled = resource.brands.include?(brand)
        list[brand] = {enabled: enabled, campaigns: (enabled ? brand.campaigns.scoped_by_company_id(current_company.id) : resource.campaigns.scoped_by_company_id(current_company.id).children_of(brand) ) }
      end
      list
    end

    def validate_parent
      raise CanCan::AccessDenied unless ['BrandPortfolio', 'Brand'].include?(params[:parent_type]) || params[:parent_type].nil?
    end

end
