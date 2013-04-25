# == Schema Information
#
# Table name: teams_users
#
#  id         :integer          not null, primary key
#  team_id    :integer
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TeamsUser < ActiveRecord::Base
  belongs_to :team, :counter_cache => :users_count
  belongs_to :user, :counter_cache => :teams_count
  # attr_accessible :title, :body
end
