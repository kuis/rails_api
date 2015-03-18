class DataExtract < ActiveRecord::Base
  belongs_to :company
  track_who_does_it

  serialize :columns
  serialize :filters

  cattr_accessor :exportable_columns

  DATA_SOURCES = [
    ['Events', :event], ['Post Event Data (PERs)', :event_data], ['Activities', :activity],
    ['Attendance', :invite], ['Comments', :comment], ['Contacts', :contact], ['Expenses', :event_expense],
    ['Surveys', :survey], ['Tasks', :task], ['Venues', :venue], ['Users', :user], ['Teams', :team],
    ['Roles', :role], ['Campaign', :campaign], ['Brands', :brands], ['Activity Types', :activity_type],
    ['Areas', :area], ['Brand Porfolios', :brand_porfolio], ['Data Ranges', :date_range], ['Day Parts', :day_part]
  ]

  def rows(page = 1)
    model.do_search((filters || {}).merge(company_id: company.id, page: page)).results.map do |e|
      (columns || self.class.exportable_columns).map { |c| e.send(c) }
    end
  end

  def model
    @model ||= "::#{self.class.name.split('::')[1]}".constantize
  end
end
