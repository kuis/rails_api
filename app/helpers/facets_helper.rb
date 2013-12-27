module FacetsHelper
  def search_params
    @search_params ||= params.dup.tap do |p|  # Duplicate the params array to make some modifications
      p[:company_id] = current_company.id
      p[:current_company_user] = current_company_user
    end
  end

  # Facet helper methods
  def build_facet(klass, title, name, facets)
    if klass.name == 'CompanyUser'
      items = klass.where(id: facets.map(&:value)).joins(:user).includes(:user).order('users.first_name, users.last_name')
    else
      items = klass.where(id: facets.map(&:value)).order(:name)
    end
    items = items.map{|x| build_facet_item({label: x.name, id: x.id, name: name})}

    {label: title, items: items}
  end

  def build_facet_item(options)
    options[:selected] ||= params.has_key?(options[:name]) && ((params[options[:name]].is_a?(Array) and (params[options[:name]].include?(options[:id]) || params[options[:name]].include?(options[:id].to_s))) || (params[options[:name]] == options[:id]) || (params[options[:name]] == options[:id].to_s))
    options
  end

  def facets
    @facets ||= respond_to?("#{controller_name}_facets") ? send("#{controller_name}_facets") : []
  end

  def build_brands_bucket(campaigns)
    campaigns_counts = Hash[campaigns.map{|x| [x.value.to_i, x.count] }]
    brands = {}
    Campaign.includes(:brands).where(id: campaigns_counts.keys).each do |campaign|
      campaing_brands = Hash[campaign.brands.map{|b| [b.id, build_facet_item({label: b.name, id: b.id, name: :brand, count: campaigns_counts[campaign.id]})] }]
      brands.merge!(campaing_brands){|k,a1,a2|  a1.merge({count: (a1[:count] + a2[:count])}) }
    end
    brands = brands.values.sort{|a, b| a[:label] <=> b[:label] }
    {label: 'Brands', items: brands}
  end

  def build_locations_bucket(search)
    locations = {}
    counts = Hash[search.facet(:place_id).rows.map{|x| [x.value, x.count] }]
    locations = Place.where(id: counts.keys.uniq).load_organized(current_company.id, counts)

    first_five = (search.facet(:place).rows.map{|x| id, name = x.value.split('||'); [Base64.strict_encode64(x.value), name, x.count, :place]} + locations[:areas].map{|a| [a.id, a.name, a.events_count, :area]}).sort{|a,b| b[3] <=> a[3] }.first(5)

    first_five = first_five.map{|x| build_facet_item({label: x[1], id: x[0], count: x[2], name: x[3]}) }.first(5)
    items = locations[:locations].sort{|a, b| a[:label] <=> b[:label] }
    {label: 'Locations', top_items: first_five, items: items}
  end


  def build_areas_bucket(search)
    counts = Hash[search.facet(:place_id).rows.map{|x| [x.value, x.count] }]
    places = Place.where(id: counts.keys.uniq).all
    list = {label: :root, items: [], id: nil, path: nil}

    areas = Area.scoped_by_company_id(current_company.id).order(:name).active

    Place.unscoped do
      places.each do |p|
        parents = [p.continent_name, p.country_name, p.state_name, p.city].compact
        areas.each{|area| area.count_events(p, parents, counts[p.id])} if counts.has_key?(p.id) && counts[p.id] > 0
      end
    end

    areas.reject!{|a| a.events_count.nil? || !a.events_count}
    areas = areas.map{|a| build_facet_item({label: a.name, id: a.id, count: a.events_count, name: :area}) }
    {label: 'Areas', items: areas}
  end

  def build_people_bucket(facet_search)
    users = build_facet(CompanyUser, 'User', :user, facet_search.facet(:user_ids).rows)[:items]
    teams = build_facet(Team, 'Team', :team, facet_search.facet(:team_ids).rows)[:items]
    people = (users + teams).sort{ |a, b| a[:label] <=> b[:label] }
    {label: 'People', items: people }
  end

  def build_state_bucket counters
    {label: 'Active State', items: ['Active', 'Inactive'].map{|x| build_facet_item({label: x, id: x, name: :status, count: counters.try(:[], x) || 0}) }}
  end

  def build_status_bucket counters
    {label: 'Event Status', items: ['Late', 'Due', 'Submitted', 'Rejected', 'Approved'].
        map{|x| build_facet_item({label: x, id: x, name: :event_status, count: counters.try(:[], x) || 0}) }.
        sort{ |a, b| a[:label] <=> b[:label] }}
  end

  def build_campaign_bucket facet_search
      items = facet_search.facet(:campaigns).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :campaign}) }
      items = items.sort{|a, b| a[:label] <=> b[:label]}
      {label: 'Campaigns', items: items}
    end

  # Returns the facets for the events controller
  def events_facets
    @events_facets ||= Array.new.tap do |f|
      # select what params should we use for the facets search
      facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| ['company_id', 'current_company_user', 'with_event_data_only', 'with_surveys_only'].include?(k)})
      facet_search = resource_class.do_search(facet_params, true)

      f.push build_facet( Campaign, 'Campaigns', :campaign, facet_search.facet(:campaign_id).rows)
      f.push build_brands_bucket(facet_search.facet(:campaign_id).rows)
      #f.push build_locations_bucket(facet_search)
      f.push build_areas_bucket( facet_search )
      f.push build_people_bucket( facet_search )

      counters = Hash[facet_search.facet(:status).rows.map{|r| [r.value.to_s.capitalize, r.count]}]
      f.push build_state_bucket( counters )
      f.push build_status_bucket( counters )
      f.push()
    end
  end

end