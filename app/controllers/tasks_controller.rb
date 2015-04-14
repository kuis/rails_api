class TasksController < FilteredController
  belongs_to :event, :company_user, optional: true

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper
  include ApplicationHelper

  respond_to :js, only: [:new, :create, :edit, :update, :show]

  has_scope :by_users

  helper_method :assignable_users, :calendar_highlights

  before_action :set_body_class, only: :index
  after_action :force_resource_reindex, only: [:create, :update]

  def assignable_users
    if resource.event.present?
      (company_users.active.by_events(resource.event).for_dropdown +
        company_users.active.by_teams(resource.event.team_ids).for_dropdown
      ).uniq.sort_by { |a| a[0].downcase }
    else
      current_company.company_users.active.for_dropdown
    end
  end

  def calendar_highlights
    @calendar_highlights ||= Hash.new.tap do |hsh|
      tz = ActiveSupport::TimeZone.zones_map[Time.zone.name].tzinfo.identifier
      Task.select("to_char(TIMEZONE('UTC', due_at) AT TIME ZONE '#{tz}', 'YYYY/MM/DD') as due_date, count(tasks.id) as count").due_today_and_late
        .where(company_user_id: user_ids_scope)
        .group("to_char(TIMEZONE('UTC', due_at) AT TIME ZONE '#{tz}', 'YYYY/MM/DD')").map do |day|
        parts = day.due_date.split('/').map(&:to_i)
        hsh.merge!(parts[0] => { parts[1] => { parts[2] => day.count.to_i } }) { |_year, months1, months2| months1.merge(months2) { |_month, days1, days2| days1.merge(days2) { |_day, day_count1, day_count2| day_count1 + day_count2 } }  }
      end
    end
  end

  private

  def permitted_params
    params.permit(task: [:completed, :due_at, :title, :company_user_id, :event_id])[:task]
  end

  def collection_search
    @solr_search ||= resource_class.do_search(search_params, true)
  end

  def authorize_actions
    if params[:scope] == 'user'
      authorize!(:index_my, Task)
    elsif params[:scope] == 'teams'
      authorize!(:index_team, Task)
    else
      authorize!(:index, Task)
    end
  end

  def parent
    if params[:scope] == 'user'
      current_company_user
    else
      super
    end
  end

  def search_params
    @search_params || (super.tap do |p|
      # Get a list of new tasks notifications to obtain the list of ids, then delete them as they are already seen, but
      # store them in the session to allow the user to navigate, paginate, etc
      if params.key?(:new_at) && params[:new_at]
        p[:id] = session["new_tasks_#{params[:scope]}_at_#{params[:new_at].to_i}"] ||= begin
          notifications = current_company_user.notifications.new_tasks
          ids = notifications.map { |n| n.params['task_id'] }.compact
          notifications.destroy_all
          ids
        end
      end
    end)
  end

  def base_search_params
    p = super
    if p.key?(:user) && p[:user].present?
      p
    else
      p.merge! Task.search_params_for_scope(params[:scope], current_company_user)
    end
  end

  # TODO: this doesn't work for teams, but tomorrow is the demo
  # and there is no much time to fix it
  def user_ids_scope
    ids = nil
    if params[:scope] == 'user'
      ids = [current_company_user.id]
    elsif params[:scope] == 'teams'
      ids = current_company_user.find_users_in_my_teams
      ids = [0] if ids.empty?
    end
    ids
  end

  def set_body_class
    @custom_body_class = params[:scope]
  end
end
