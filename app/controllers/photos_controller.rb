class PhotosController < FilteredController
  respond_to :js, only: :create

  belongs_to :event, optional: true

  include DeactivableHelper

  defaults :resource_class => AttachedAsset

  skip_load_and_authorize_resource

  def autocomplete
    buckets = autocomplete_buckets({
      campaigns: [Campaign],
      brands: [Brand, BrandPortfolio],
      places: [Place]
    })
    render :json => buckets.flatten
  end

  private

    def search_params
      @search_params ||= begin
        super
        @search_params[:asset_type] = 'photo'
        @search_params
      end
    end
end