class Results::EventStatusController < ApplicationController
  before_filter :campaign, except: :index
  before_filter :authorize_actions

  helper_method :return_path

  def index
    @campaigns = current_company.campaigns.accessible_by_user(current_company_user).order('name ASC')
  end

  def report
    authorize_actions
  end

  private
    def campaign
      @campaign ||= current_company.campaigns.find(params[:report][:campaign_id])
    end

    def authorize_actions
      if params[:report] && params[:report][:campaign_id]
        authorize! :event_status_report_campaign, campaign
      else
        authorize! :event_status, Campaign
      end
    end

    def return_path
      results_reports_path
    end
end