class AreasCampaignsController < FilteredController
  respond_to :js, only: [:edit, :update]

  defaults finder: :find_by_area_id!

  belongs_to :campaign

  def exclude_place
    resource.exclusions = (resource.exclusions + [params[:place_id].to_i]).uniq
    resource.save
  end

  def include_place
    resource.exclusions = resource.exclusions - [params[:place_id].to_i]
    resource.save
  end
end