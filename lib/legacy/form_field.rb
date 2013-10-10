# == Schema Information
#
# Table name: form_fields
#
#  id               :integer          not null, primary key
#  form_template_id :integer          not null
#  metric_id        :integer
#  position         :integer          default(0)
#  section_name     :string(255)
#  rows             :integer          default(1)
#  columns          :integer          default(1)
#  clear            :boolean          default(FALSE)
#  creator_id       :integer
#  updater_id       :integer
#  created_at       :datetime
#  updated_at       :datetime
#

class FormField < Legacy::Record
  belongs_to    :form_template
  belongs_to    :metric


  scope :custom, lambda{ not_global.joins(:metric).where('metrics.type not in (?)', ['Metric::BarSpend', 'Metric::PromoHours', 'Metric::Paragraph', 'Metric::Sentence']) }
  scope :not_global, lambda{ joins(:metric).where('(metrics.program_id is not NULL OR metrics.brand_id is not NULL OR metrics.name not in (?))', ['Age', 'Gender', 'Demographic', '# Consumer Impressions', '# Consumers Sampled','# Consumer Interactions']) }

  def has_metric?
    !metric.nil?
  end
end