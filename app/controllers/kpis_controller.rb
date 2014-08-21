class KpisController < FilteredController
  prepend_before_action :load_campaign, only: [:new, :update, :edit, :create]
  respond_to :js, only: [:new, :create, :edit, :update]

  def create
    create! do |success, failure|
      success.js do
        if params[:campaign_id].present?
          campaign = current_company.campaigns.find(params[:campaign_id])
          @field = campaign.add_kpi(resource)
        end
      end
    end
  end

  def load_campaign
    @campaign = current_company.campaigns.find(params[:campaign_id])
  end

  protected
    def permitted_params
      is_custom = params[:id].nil? || params[:id].empty? || !Kpi.global.select('id').map(&:id).include?(params[:id].to_i)
      goals_attributes = if can?(:edit_kpi_goals, @campaign)
        {goals_attributes: [:id, :goalable_id, :goalable_type, :value, :kpis_segment_id, :kpi_id]}
      end
      segment_params = if is_custom
        if can?(:create_custom_kpis, @campaign) || can?(:edit_custom_kpi, @campaign)
          {kpis_segments_attributes: [:id, :text, :_destroy, goals_attributes]}
        else
          {kpis_segments_attributes: [:id, goals_attributes]}
        end
      else
        {kpis_segments_attributes: [:id, goals_attributes]}
      end
      common_params = [segment_params, goals_attributes]

      # Allow only certain params for global KPIs like impresssions, interactions, gender, etc
      if is_custom
        if can?(:create_custom_kpis, @campaign) || can?(:edit_custom_kpi, @campaign)
          params.permit(kpi: [:name, :description, :kpi_type, :capture_mechanism] + common_params)[:kpi]
        else
          params.permit(kpi: common_params)[:kpi]
        end
      else
        params.permit(kpi: common_params)[:kpi]
      end
    end
end