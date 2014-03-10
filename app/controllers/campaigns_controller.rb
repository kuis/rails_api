class CampaignsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update, :new_date_range]

  include DeactivableHelper

  # This helper provide the methods to add/remove campaigns members to the event
  extend TeamMembersHelper

  skip_authorize_resource only: :tab

  layout false, only: :kpis

  def update_post_event_form
    attrs = params[:fields].dup
    attrs.each{|index, field| normalize_brands(field[:options][:brands]) if field[:options].present? && field[:options][:brands].present? }
    resource.form_fields_attributes = attrs
    resource.save
    render text: 'OK'
  end

  def autocomplete
    buckets = autocomplete_buckets({
      campaigns: [Campaign],
      brands: [Brand, BrandPortfolio],
      places: [Venue],
      people: [CompanyUser, Team]
    })
    render :json => buckets.flatten
  end

  def find_similar_kpi
    search = Sunspot.search(Kpi) do
      keywords(params[:name]) do
        fields(:name)
      end
      with(:company_id, [-1, current_company.id])
    end
    render json: search.results
  end

  def remove_kpi
    @field = resource.form_fields.where(kpi_id: params[:kpi_id]).find(:first)
    @field.destroy
  end

  def add_kpi
    if resource.form_fields.where(kpi_id: params[:kpi_id]).count == 0
      kpi = Kpi.global_and_custom(current_company).find(params[:kpi_id])
      @field = resource.add_kpi(kpi)
    else
      render text: ''
    end
  end
  
    def remove_activity_type
      activity_type = current_company.activity_types.find(params[:activity_type_id])
      if resource.activity_types.include?(activity_type)
        resource.activity_types.delete(activity_type) 
      else
        render text: ''
      end
      
  end

  def add_activity_type
    activity_type = current_company.activity_types.find(params[:activity_type_id])
    unless resource.activity_types.include?(activity_type)
      resource.activity_types << activity_type
    else
      render text: ''
    end
  end

  def new_date_range
    @date_ranges = current_company.date_ranges.where('date_ranges.id not in (?)', resource.date_range_ids + [0])
  end

  def add_date_range
    date_range = current_company.date_ranges.find(params[:date_range_id])
    if date_range.present? && !resource.date_ranges.include?(date_range)
      resource.date_ranges << date_range
    end
  end

  def delete_date_range
    date_range = resource.date_ranges.find(params[:date_range_id])
    resource.date_ranges.delete(date_range)
  end

  def new_day_part
    @day_parts = current_company.day_parts.where('day_parts.id not in (?)', resource.day_part_ids + [0])
  end

  def add_day_part
    day_part = current_company.day_parts.find(params[:day_part_id])
    if day_part.present? && !resource.day_parts.include?(day_part)
      resource.day_parts << day_part
    end
  end

  def delete_day_part
    day_part = resource.day_parts.find(params[:day_part_id])
    resource.day_parts.delete(day_part)
  end

  def tab
    authorize! "view_#{params[:tab]}", resource
    render layout: false
  end

  protected
    def permitted_params
      params.permit(campaign: [:name, :start_date, :end_date, :description, :brands_list, {brand_portfolio_ids: []}])[:campaign]
    end

    def normalize_brands(brands)
      unless brands.empty?
        brands.each_with_index do |b, index|
          b = Brand.find_or_create_by_name(b).id unless  b.is_a?(Integer) || b =~ /\A[0-9]+\z/
          brands[index] = b.to_i
        end
      end
    end

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| %w(q company_id).include?(k)})
        facet_search = resource_class.do_search(facet_params, true)

        f.push build_brand_bucket facet_search
        f.push build_brand_portfolio_bucket facet_search

        f.push build_people_bucket facet_search
        f.push build_state_bucket facet_search
      end
    end

    def build_brand_bucket facet_search
      items = facet_search.facet(:brands).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :brand}) }
      items = items.sort{|a, b| a[:label] <=> b[:label]}
      {label: "Brands", items: items  }
    end

    def build_brand_portfolio_bucket facet_search
      items = facet_search.facet(:brand_portfolios).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :brand_portfolio}) }
      items = items.sort{|a, b| a[:label] <=> b[:label] }
      {label: "Brand Portfolios", items: items}
    end

    def build_people_bucket facet_search
      users = facet_search.facet(:users).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :user}) }
      teams = facet_search.facet(:teams).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :team}) }
      people = (users + teams).sort { |a, b| a[:label] <=> b[:label] }
      {label: "People", items: people}
    end
end
