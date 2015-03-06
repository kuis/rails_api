class BrandAmbassadors::VisitsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :xls, :pdf, only: :index

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  include EventsHelper

  helper_method :return_path

  protected

  def permitted_params
    params.permit(brand_ambassadors_visit: [:visit_type, :campaign_id, :area_id, :city, :description, :start_date, :end_date, :company_user_id])[:brand_ambassadors_visit]
  end

  def build_resource
    @visit || super.tap do |v|
      v.company_user_id ||= current_company_user.id
    end
  end

  def search_params
    if params[:start_date] && params[:end_date] && request.present? && request.format.json?
      super.merge!(per_page: 1000)
    else
      super
    end
  end

  # Returns the facets for the events controller
  def facets
    @events_facets ||= Array.new.tap do |f|
      # select what params should we use for the facets search
      f.concat build_custom_filters_bucket

      f.push build_brand_ambassadors_bucket
      f.push build_campaign_bucket
      f.push build_areas_bucket
      f.push build_city_bucket
    end
  end

  def list_exportable?
    params['mode'] == 'calendar' || super
  end

  def permitted_search_params
    [:start_date, :end_date, :page, :sorting, :sorting_dir, :per_page,
     campaign: [], area: [], user: [], city: []]
  end

  def return_path
    url_to_return = params[:return] || request.env['HTTP_REFERER'] || brand_ambassadors_root_path
    url_to_return if url_valid? url_to_return
  end
end
