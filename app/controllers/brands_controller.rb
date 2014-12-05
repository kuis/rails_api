# Brands Controller class
#
# This class handle the requests for managing the Brands
#
class BrandsController < FilteredController
  actions :index, :new, :create, :edit, :update
  belongs_to :campaign, :brand_portfolio, optional: true
  respond_to :json, :xls, :pdf, only: [:index]
  respond_to :js, only: [:new, :create, :edit, :update]

  has_scope :not_in_portfolio

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  def autocomplete
    buckets = autocomplete_buckets(
      brands: [Brand],
      active_state: [])
    render json: buckets.flatten
  end

  def create
    create! do |success, _|
      success.js do
        parent.brands << resource if parent? && parent
        render :create
      end
    end
  end

  def index
    respond_to do |format|
      format.html
      format.xls { super }
      format.pdf { super }
      format.json { render json: collection.map { |b| { id: b.id, name: b.name } } }
    end
  end

  protected

  def permitted_params
    params.permit(brand: [:name, :marques_list])[:brand]
  end

  def authorize_actions
    authorize! :index, resource_class
  end

  def facets
    @facets ||= Array.new.tap do |f|
      f.push(label: 'Active State', items: %w(Active Inactive).map do |x|
        build_facet_item(label: x, id: x, name: :status, count: 1)
      end)
    end
  end

  def permitted_search_params
    [:page, :sorting, :sorting_dir, :per_page,
     brand: [], status: [], brand_portfolio: [], campaign: []]
  end
end
