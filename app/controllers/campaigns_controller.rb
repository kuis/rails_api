class CampaignsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  include DeactivableHelper

  # This helper provide the methods to add/remove campaigns members to the event
  extend TeamMembersHelper

  load_and_authorize_resource except: :index

  has_scope :with_text

  def autocomplete
    buckets = []

    # Search compaigns
    search = Sunspot.search(Campaign) do
      keywords(params[:q]) do
        fields(:name)
      end
      with(:company_id, current_company.id)
    end
    buckets.push(label: "Campaigns", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    # Search brands
    search = Sunspot.search(Brand, BrandPortfolio) do
      keywords(params[:q]) do
        fields(:name)
      end
    end
    buckets.push(label: "Brands", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    # Search places
    search = Sunspot.search(Place, Area) do
      keywords(params[:q]) do
        fields(:name)
      end
    end
    buckets.push(label: "Places", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    # Search users
    search = Sunspot.search(CompanyUser, Team) do
      keywords(params[:q]) do
        fields(:name)
      end
      with :company_id, current_company.id  # For the teams
    end
    buckets.push(label: "People", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    render :json => buckets.flatten
  end

  protected
    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)

        users = facet_search.facet(:users).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :user}) }
        teams = facet_search.facet(:teams).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :team}) }
        people = (users + teams).sort { |a, b| b[:count] <=> a[:count] }
        f.push(label: "People", items: people )
        f.push(label: "Status", items: facet_search.facet(:status).rows.map{|x| build_facet_item({label: x.value, id: x.value, name: :status, count: x.count}) })
      end
    end

    def collection_to_json
      collection.map{|campaign| {
        :id => campaign.id,
        :name => campaign.name,
        :description => campaign.description,
        :first_event => campaign.first_event.try(:start_date),
        :last_event => campaign.last_event.try(:start_date),
        :status => campaign.active? ? 'Active' : 'Inactive',
        :active => campaign.active?,
        :links => {
            edit: edit_campaign_path(campaign),
            show: campaign_path(campaign),
            activate: activate_campaign_path(campaign),
            deactivate: deactivate_campaign_path(campaign)
        }
      }}
    end
end
