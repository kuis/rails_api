class ActivitiesController < FilteredController
  belongs_to :venue, :event, polymorphic: true, optional: true
  respond_to :js, only: [:new, :create, :edit, :update]

  include DeactivableHelper

  helper_method :assignable_users, :activity_types

  def form
    @activity = Activity.new(permitted_params)
    @brands = Brand.accessible_by_user(current_company_user.id).order(:name)
    render layout: false
  end

  protected
    def assignable_users
      current_company.company_users.active.joins(:user).includes(:user).order('users.first_name ASC, users.last_name ASC')
    end

    def activity_types
      if parent.is_a?(Event)
        parent.campaign.activity_types.order('activity_types.name ASC')
      else
        current_company.activity_types.active.order(:name)
      end
    end

    def permitted_params
      params.permit(activity: [:activity_type_id, {results_attributes: [:id, :form_field_id, :value, value: []]}, :campaign_id, :company_user_id, :activity_date])[:activity]
    end
end