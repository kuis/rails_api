class DateItemsController < FilteredController
  belongs_to :date_range
  respond_to :js, only: [:new, :create, :destroy]
  actions :new, :create, :destroy

  skip_authorize_resource
  before_filter :edit_authorize_parent

  protected

    def build_resource(*args)
      @date ||= super
      @date.recurrence_type ||= 'daily'
      @date.recurrence_period ||= 1
      @date
    end

    def permitted_params
      params.permit(date_item: [:start_date, :end_date, :recurrence, :recurrence_days, :recurrence_period, :recurrence_type])[:date_item]
    end

    def edit_authorize_parent
      authorize! :edit, parent
    end
end
