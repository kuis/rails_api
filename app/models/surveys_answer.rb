# == Schema Information
#
# Table name: surveys_answers
#
#  id          :integer          not null, primary key
#  survey_id   :integer
#  kpi_id      :integer
#  question_id :integer
#  brand_id    :integer
#  answer      :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class SurveysAnswer < ActiveRecord::Base
  belongs_to :survey
  belongs_to :kpi

  attr_accessible :answer, :brand_id, :question_id, :kpi_id

  validate :valid_answer?

  validates :answer, presence: true

  def segment
    kpi.kpis_segments.find(answer) unless answer.nil?
  end

  protected
    def valid_answer?
      if brand_id.present?
        errors.add(:brand_id, 'is not valid') unless survey.brands.map(&:id).include?(brand_id)
      end
    end
end
