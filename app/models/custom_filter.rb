# == Schema Information
#
# Table name: custom_filters
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  apply_to     :string(255)
#  filters      :text
#  created_at   :datetime
#  updated_at   :datetime
#  owner_id     :integer
#  owner_type   :string(255)
#  group        :string(255)
#  default_view :boolean          default(FALSE)
#

class CustomFilter < ActiveRecord::Base
  belongs_to :owner, polymorphic: true

  SAVED_FILTERS_NAME = 'Saved Filters'

  # Required fields
  validates :owner, presence: true
  validates :name, presence: true
  validates :group, presence: true
  validates :apply_to, presence: true
  validates :filters, presence: true

  scope :by_type, ->(type) { order('id ASC').where(apply_to: type) }
  scope :user_saved_filters, -> { where(group: SAVED_FILTERS_NAME) }
  scope :not_user_saved_filters, -> { where.not(group: SAVED_FILTERS_NAME) }

  scope :for_company_user, ->(company_user) {
    where(
      '(owner_type=? AND owner_id=?) OR (owner_type=? AND owner_id=?)',
      'Company', company_user.company_id, 'CompanyUser', company_user.id
    )
  }
end
