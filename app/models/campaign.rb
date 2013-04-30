# == Schema Information
#
# Table name: campaigns
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  description   :text
#  aasm_state    :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :integer
#

class Campaign < ActiveRecord::Base
  include AASM

  # Created_by_id and updated_by_id fields
  track_who_does_it

  scoped_to_company

  attr_accessible :name, :description, :aasm_state, :team_ids

  # Required fields
  validates :name, presence: true
  validates :company_id, presence: true, numericality: true

  # Campaigns-Teams relationship
  has_and_belongs_to_many :teams

  aasm do
    state :inactive, :initial => true
    state :active
    state :closed

    event :activate do
      transitions :from => [:inactive, :closed], :to => :active
    end

    event :deactivate do
      transitions :from => :active, :to => :inactive
    end
  end
end
