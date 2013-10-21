class Api::V1::FilteredController < Api::V1::ApiController
  inherit_resources


  def collection
    @solr_search = resource_class.do_search(search_params)
    @collection_count = @solr_search.total
    @total_pages = @solr_search.results.total_pages
    set_collection_ivar(@solr_search.results)
  end

  protected

    def search_params
      @search_params ||= params.dup.tap do |p|  # Duplicate the params array to make some modifications
        p[:company_id] = current_company.id
        p[:current_company_user] = current_company_user
      end
    end
end