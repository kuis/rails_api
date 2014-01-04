class DateRangesController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper


  def autocomplete
    buckets = autocomplete_buckets({
      date_ranges: [DateRange]
    })
    render :json => buckets.flatten
  end


  protected
    def permitted_params
      params.permit(date_range: [:description, :name])[:date_range]
    end

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we used for the facets search
        f.push(label: "Active State", items: ['Active', 'Inactive'].map{|x| build_facet_item({label: x, id: x, name: :status, count: 1}) })
      end
    end
end
