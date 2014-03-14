class Results::ReportsController < InheritedResources::Base
  respond_to :js, only: [:new, :create, :edit, :update, :share_form, :show]

  load_and_authorize_resource except: [:index]

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  def index
    @reports = current_company.reports.active.accessible_by_user(current_company_user).order('reports.name ASC')
  end

  def preview
    @report = Report.new(permitted_params.merge(company_id: current_company.id, name: resource.name))
    @report.set_page(1)
  end

  def build
  end

  def show
    if request.format.csv?
      @export = ListExport.create({controller: self.class.name,  params: filter_params, export_format: :csv, company_user: current_company_user}, without_protection: true)
      if @export.new?
        @export.queue!
      end
      render action: :new_export, formats: [:js]
    else
      resource.set_page(1)
    end
  end

  def rows
    resource.set_page params[:page].to_i
    render layout: false
  end

  def share_form
    @sharing_collection = ActiveRecord::Base.connection.select_all("
      #{current_company.company_users.select('company_users.id, users.first_name || \' \' || users.last_name as name, \'company_user\' as type').active.joins(:user).to_sql}
      UNION ALL
      #{current_company.roles.select('roles.id, roles.name, \'role\' as type').active.to_sql}
      UNION ALL
      #{current_company.teams.select('teams.id, teams.name, \'team\' as type').active.to_sql}
      ORDER BY name ASC
    ").map{|r| [r['name'], "#{r['type']}:#{r['id']}", {class: r['type']}] }
  end

  private
    def export_list(export)
      render_to_string(text: resource.to_csv {|total, i| export.update_column(:progress, (i*100/total).round) })
    end

    def build_resource_params
      [permitted_params || {}]
    end

    def permitted_params
      params.permit(report: [
        :name, :description, :sharing, {sharing_selections: []},
        { rows: [:field, :label, :aggregate] },
        { columns: [:field, :label] },
        { values: [:field, :label, :aggregate, :display] },
        { filters: [:field, :label] }
      ])[:report] || {}
    end

    def filter_params
      params.permit(:id, {campaing: []}, {area: []})
    end

    def export_file_name
      sanitize_filename resource.name
    end

    def sanitize_filename(filename)
      filename.strip.tap do |name|
       # NOTE: File.basename doesn't work right with Windows paths on Unix
       # get only the filename, not the whole path
       name.gsub!(/^.*(\\|\/)/, '')

       # Strip out the non-ascii character
       name.gsub!(/[^0-9A-Za-z.\-]/, '_')
      end
    end
end
