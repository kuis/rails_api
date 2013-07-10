class CompanyUsersController < FilteredController
  include DeactivableHelper

  before_filter :load_users_for_event, only: :event

  respond_to :js, only: [:new, :create, :edit, :update, :time_zone_change]
  respond_to :json, only: [:index]

  helper_method :assignable_campaigns

  custom_actions collection: [:complete, :time_zone_change]

  def autocomplete
    buckets = autocomplete_buckets({
      users: [CompanyUser],
      teams: [Team],
      roles: [Role],
      campaigns: [Campaign],
      places: [Place]
    })

    render :json => buckets.flatten
  end

  def time_zone_change
    current_user.update_column(:detected_time_zone, params[:time_zone])
  end

  def event
    render :index
  end

  def select_company
    begin
      company = current_user.company_users.find_by_company_id_and_active(params[:company_id], true) or raise ActiveRecord::RecordNotFound
      current_user.current_company = company.company
      current_user.save
      session[:current_company_id] = company.company_id
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "You are not allowed login into this company"
    end
    redirect_to root_path
  end

  def assignable_campaigns
    current_company.campaigns.active.order('campaigns.name asc')
  end

  def update
    update! do |success, failure|
      success.js {
        if resource.user.id == current_user.id
          sign_in resource.user, :bypass => true
        end
      }
    end
  end

  protected

    def roles
      @roles ||= current_company.roles
    end

    def as_role
      { as: :admin }
    end

    def role_given?
      current_user.id != resource.user_id
    end

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)
        f.push(label: "Roles", items: facet_search.facet(:role).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :role}) } )
        f.push(label: "Campaigns", items: facet_search.facet(:campaigns).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :campaign}) })
        f.push(label: "Teams", items: facet_search.facet(:teams).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :team}) })
        f.push(label: "Status", items: facet_search.facet(:status).rows.map{|x| build_facet_item({label: x.value, id: x.value, name: :status, count: x.count}) })
      end
    end

    def delete_member_path(user)
      path = nil
      path = delete_member_team_path(params[:team], member_id: user.id) if params.has_key?(:team) && params[:team]
      path = delete_member_campaign_path(params[:campaign], member_id: user.id) if params.has_key?(:campaign) && params[:campaign]
      path
    end

    def load_users_for_event
      event = current_company.events.find(params[:event_id])
      # INNER JOIN "memberships" ON "memberships"."company_user_id" = "company_users"."id" AND "memberships"."memberable_type" = 'Event' INNER JOIN "events" ON "events"."id" = "memberships"."memberable_id"
      teams = CompanyUser.scoped_by_company_id(current_company).active.joins(:teams).where(active: true, teams: {id: event.team_ids})
      users = CompanyUser.scoped_by_company_id(current_company).active.joins(:events).where(active: true, events: {id: event.id})
      @users = CompanyUser.from("(#{teams.to_sql} UNION #{users.to_sql}) AS company_users ")
      @collection_count_scope = @users
      set_collection_ivar @users
    end

end
