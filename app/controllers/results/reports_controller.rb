class Results::ReportsController < InheritedResources::Base
  respond_to :js, only: [:new, :create, :edit, :update]

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  def index
    @reports = current_company.reports.active.order('reports.name ASC')
  end

  private
    def build_resource_params
      [permitted_params || {}]
    end
    def permitted_params
      params.permit(report: [
        :name, :description,
        { rows: [:field, :label, :aggregate] },
        { columns: [:field, :label, :aggregate] },
        { values: [:field, :label, :aggregate] },
        { filters: [:field, :label, :aggregate] }
      ])[:report]
    end
end
