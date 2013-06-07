# == Schema Information
#
# Table name: teamings
#
#  id            :integer          not null, primary key
#  team_id       :integer
#  teamable_id   :integer
#  teamable_type :string(255)
#

class Teaming < ActiveRecord::Base
  belongs_to :team
  belongs_to :teamable, polymorphic: true
end
