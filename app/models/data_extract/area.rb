# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  filters          :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#  params           :text
#

class DataExtract::Area < DataExtract
  define_columns name: 'name',
                 description: 'description',
                 created_by: 'users.first_name || \' \' || users.last_name',
                 created_at: 'to_char(areas.created_at, \'MM/DD/YYYY HH12:MI AM\')'

  def add_joins_to_scope(s)
    s = s.joins(:created_by) if columns.include?('created_by')
    s
  end

  def total_results
    Area.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
  end

  def add_filter_conditions_to_scope(s)
    return s if filters.nil? || filters.empty?
    s = s.where(active: filters['status'].map { |f| f.downcase == 'active' ? true : false }) if filters['status'].present?
    s
  end

end
