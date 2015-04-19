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
#
class DataExtract::CompanyUser < DataExtract
  define_columns first_name: 'users.first_name',
  last_name: 'users.last_name', 
  teams_name: 'array_to_string(ARRAY(SELECT teams.name FROM teams 
              LEFT JOIN memberships ON memberable_type=\'Team\' AND memberable_id=teams.id 
              WHERE company_users.id=memberships.company_user_id  ),\', \') AS teams_name', 
  email: 'users.email', 
  phone_number: 'users.phone_number', 
  role_name: 'roles.name',
  address1: 'users.street_address', 
  address2: 'users.unit_number', 
  country: 'users.country', 
  state: 'users.state', 
  zip_code: 'users.zip_code', 
  time_zone: 'users.time_zone', 
  created_at: proc { "to_char(users.created_at, 'MM/DD/YYYY')" },
  created_by: '(SELECT trim(us.first_name || \' \' || us.last_name) FROM users as us WHERE users.created_by_id=us.id)',
  active_state: 'CASE WHEN company_users.active=\'t\' THEN \'Active\' ELSE \'Inactive\' END'
  
  def add_joins_to_scope(s)
    s = s.joins('LEFT JOIN users ON users.id=company_users.user_id')
    if columns.include?('role_name')
      s = s.joins('LEFT JOIN roles ON roles.id=company_users.role_id')
    end
    s
  end

  def total_results
    CompanyUser.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
  end
end