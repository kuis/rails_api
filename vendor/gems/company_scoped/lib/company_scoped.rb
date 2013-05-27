require "company_scoped/version"
require 'active_record'
require 'company_scoped/callback'
require 'company_scoped/railtie'

module CompanyScoped
  def scoped_to_company(options = {})
    before_validation CompanyScoped::Callback.new

    if column_names.include?('company_id')
      belongs_to :company
    end
  end
end
