class TeamsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  # This helper provide the methods to add/remove team members to the event
  extend TeamMembersHelper

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  load_and_authorize_resource except: :index

  has_scope :with_text

  def autocomplete
    buckets = []

    # Search teams
    search = Sunspot.search(Team) do
      keywords(params[:q]) do
        fields(:name)
      end
      with :company_id, current_company.id
    end
    buckets.push(label: "Teams", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    # Search users
    search = Sunspot.search(CompanyUser) do
      keywords(params[:q]) do
        fields(:name)
      end
      with :company_id, current_company.id
    end
    buckets.push(label: "Users", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    # Search campaigns
    search = Sunspot.search(Campaign) do
      keywords(params[:q]) do
        fields(:name)
      end
      with(:company_id, current_company.id)
    end
    buckets.push(label: "Campaigns", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    render :json => buckets.flatten
  end

  private
    def collection_to_json
      collection.map{|team| {
        :id => team.id,
        :name => team.name,
        :description => team.description,
        :users_count => team.users.active.count,
        :status => team.active? ? 'Active' : 'Inactive',
        :active => team.active?,
        :links => {
            edit: edit_team_path(team),
            show: team_path(team),
            activate: activate_team_path(team),
            deactivate: deactivate_team_path(team)
        }
      }}
    end
end