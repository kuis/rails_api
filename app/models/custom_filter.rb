# == Schema Information
#
# Table name: custom_filters
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  name            :string(255)
#  apply_to        :string(255)
#  filters         :text
#  created_at      :datetime
#  updated_at      :datetime
#

class CustomFilter < ActiveRecord::Base
  belongs_to :owner, polymorphic: true

  serialize :filters

  # Required fields
  validates :owner, presence: true
  validates :name, presence: true
  validates :apply_to, presence: true
  validates :filters, presence: true

  scope :by_type, ->(type) { order("id ASC").where(apply_to: type) }
end
