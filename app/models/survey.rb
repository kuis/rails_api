# == Schema Information
#
# Table name: surveys
#
#  id            :integer          not null, primary key
#  event_id      :integer
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Survey < ActiveRecord::Base
  belongs_to :event
  attr_accessible :surveys_answers_attributes

  has_many :surveys_answers, autosave: true

  accepts_nested_attributes_for :surveys_answers

  def brands
    field = event.campaign.form_fields.scoped_by_kpi_id(Kpi.surveys).first
    brands = []
    if field.present?
      brands = Brand.where(id: field.options['brands'])
    end
    brands || []
  end

  def age
    answer = surveys_answers.select{|a| a.kpi_id == Kpi.age.id }.first
    answer.segment.text unless answer.nil?
  end

  def gender
    answer = surveys_answers.select{|a| a.kpi_id == Kpi.gender.id }.first
    answer.segment.text unless answer.nil?
  end

  def ethnicity
    answer = surveys_answers.select{|a| a.kpi_id == Kpi.ethnicity.id }.first
    answer.segment.text unless answer.nil?
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def answer_for(question_id, brand_id, kpi_id=nil)
    if kpi_id.nil?
      surveys_answers.select{|a| a.question_id == question_id && a.brand_id == brand_id}.first || surveys_answers.build({question_id: question_id, brand_id: brand_id}, without_protection: true)
    else
      surveys_answers.select{|a| a.question_id == question_id && a.kpi_id == kpi_id}.first || surveys_answers.build({question_id: question_id, kpi_id: kpi_id}, without_protection: true)
    end
  end
end
