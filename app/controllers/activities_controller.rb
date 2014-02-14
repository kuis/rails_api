class ActivitiesController < FilteredController
  belongs_to :venue, polymorphic: true
  respond_to :js, only: [:new, :create]

  def form
    @activity = Activity.new(permitted_params)
    @users = current_company.company_users.active.joins(:user).order('users.first_name ASC')
    @brands = Brand.accessible_by_user(current_company_user.id).order(:name)
    render layout: false
  end

  protected
    def permitted_params
      params.permit(activity: [:activity_type_id, {results_attributes: [:id, :form_field_id, :value, value: []]}, :campaign_id, :company_user_id, :activity_date])[:activity]
    end
end