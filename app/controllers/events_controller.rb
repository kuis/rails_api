class EventsController < FilteredController
  load_and_authorize_resource except: [:index, :autocomplete]
  skip_authorize_resource  only: [:index]
  skip_load_resource  only: [:index]

  # This helper provide the methods to add/remove team members to the event
  extend TeamMembersHelper

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  respond_to :js, only: [:new, :create, :edit, :update]

  helper_method :filters

  def index
    Rails.logger.debug "Render INDEX"
  end

  def autocomplete
    buckets = []

    # Search compaigns
    search = Sunspot.search(Campaign) do
      keywords(params[:q]) do
        fields(:name_txt)
      end
      with(:company_id, current_company.id)
    end
    buckets.push(label: "Campaigns", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })


    # Search brands
    search = Sunspot.search(Brand) do
      keywords(params[:q]) do
        fields(:name_txt)
      end
    end
    buckets.push(label: "Brands", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    # Search places
    search = Sunspot.search(Place) do
      keywords(params[:q]) do
        fields(:name_txt)
      end
    end
    buckets.push(label: "Places", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    # Search users
    search = Sunspot.search(User, Team) do
      keywords(params[:q]) do
        fields(:name_txt)
      end
      any_of do
        with :active_company_ids, current_company.id # For the users
        with :company_id, current_company.id  # For the teams
      end
    end
    buckets.push(label: "People", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })


    render :json => buckets.flatten
  end

  protected

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :start_date, :end_date, :company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)

        # Date Ranges
        ranges = [
            {label: 'Today', id: 'today', name: :predefined_date, count: 1, ordering: 1},
            {label: 'This Week', id: 'week', name: :predefined_date, count: 1, ordering: 2},
            {label: 'This Month', id: 'month', name: :predefined_date, count: 1, ordering: 3}
        ]
        ranges += DateRange.active.map{|r| {label: r.name, id: r.id, name: :date_range, count: 5}}
        f.push(label: "Date Ranges", items: ranges )

        f.push(label: "Places", items: facet_search.facet(:place).rows.map{|x| id, name = x.value.split('||'); {label: name, id: id, name: :place, count: x.count} })
        f.push(label: "Campaigns", items: facet_search.facet(:campaign).rows.map{|x| id, name = x.value.split('||'); {label: name, id: id, name: :campaign, count: x.count} })
        f.push(label: "Brands", items: facet_search.facet(:brands).rows.map{|x| id, name = x.value.split('||'); {label: name, id: id, name: :brand, count: x.count} })
        users = facet_search.facet(:users).rows.map{|x| id, name = x.value.split('||'); {label: name, id: id, count: x.count, name: :user} }
        teams = facet_search.facet(:teams).rows.map{|x| id, name = x.value.split('||'); {label: name, id: id, count: x.count, name: :team} }
        people = (users + teams).sort_by { |k| k[:count] }
        f.push(label: "People", items: people )
        f.push(label: "Status", items: facet_search.facet(:status).rows.map{|x| {label: x.value, id: x.value, name: :status, selected: (x.value =='Active'), count: x.count} })
      end
    end

    def begin_of_association_chain
      current_company
    end

    def collection_to_json
      collection.map{|event| {
        :id => event.id,
        :start_date => event.start_date,
        :start_time => event.start_time,
        :end_date => event.end_date,
        :end_time => event.end_time,
        :active=> event.active,
        :start_at => event.start_at.to_s,
        :end_at => event.end_at.to_s,
        :place => {
            :name => event.place_name || '',
            :latitude => event.place_latitude || '',
            :longitude => event.place_longitude || '',
            :formatted_address => event.place_formatted_address || ''
        },
        :campaign => { :name => event.campaign_name },
        :status => event.active? ? 'Active' : 'Inactive',
        :links => {
            edit: edit_event_path(event),
            show: event_path(event),
            activate: activate_event_path(event),
            deactivate: deactivate_event_path(event)
        }
      }}
    end

    def controller_filters(c)
      c.includes([:campaign, :place])
    end
end
