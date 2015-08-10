# == Schema Information
#
# Table name: form_field_results
#
#  id              :integer          not null, primary key
#  form_field_id   :integer
#  value           :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  hash_value      :hstore
#  scalar_value    :decimal(15, 2)   default(0.0)
#  resultable_id   :integer
#  resultable_type :string(255)
#

class FormFieldResult < ActiveRecord::Base
  belongs_to :resultable, polymorphic: true
  belongs_to :form_field

  validate :valid_value?
  validates :form_field_id, numericality: true, presence: true

  delegate :company_id, to: :resultable

  has_one :attached_asset, as: :attachable, dependent: :destroy, inverse_of: :attachable

  before_validation :prepare_for_store
  after_commit :reindex_trending

  scope :for_kpi, -> (kpi) { joins(:form_field).where(form_fields: { kpi_id: kpi }) }

  scope :for_event_campaign, -> (campaign) { joins('INNER JOIN events ON events.id=form_field_results.resultable_id AND form_field_results.resultable_type=\'Event\'').where(events: { campaign_id: campaign }) }

  scope :for_place_in_company, -> (place, company) { joins('INNER JOIN events ON events.id=form_field_results.resultable_id AND form_field_results.resultable_type=\'Event\'').where(events: { company_id: company, place_id: place }) }

  def value
    if form_field.present? && form_field.is_hashed_value?
      if form_field.type == 'FormField::Checkbox'
        (attributes['hash_value'].try(:keys) || attributes['value'] || []).map(&:to_i)
      else
        attributes['hash_value'] || attributes['value'] || {}
      end
    elsif form_field.present? && form_field.settings.present? && form_field.settings.key?('multiple') && form_field.settings['multiple']
      attributes['value'].try(:split, ',')
    else
      attributes['value']
    end
  end

  def to_html
    form_field.format_html self
  end

  def to_csv
    form_field.format_csv self
  end

  def to_chart_data
    form_field.format_chart_data self
  end

  protected

  def valid_value?
    return if form_field.nil?
    form_field.validate_result(self)
  end

  def prepare_for_store
    if self.value_changed?
      self.value = form_field.store_value(attributes['value'])
      if form_field.is_hashed_value?
        (self.hash_value, self.value) = [attributes['value'], nil]
      elsif form_field.is_attachable?
        build_attached_asset(direct_upload_url: value) unless value.nil? || value == ''
      end
    end
    self.scalar_value = value.to_f rescue 0 if value.present? && value.to_s =~ /\A[0-9\.\,]+\z/
    true
  end

  def reindex_trending
    return unless form_field.trendeable?
    Sunspot.index(TrendObject.new(resultable, self))
  end
end
