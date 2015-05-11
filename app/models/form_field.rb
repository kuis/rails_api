# == Schema Information
#
# Table name: form_fields
#
#  id             :integer          not null, primary key
#  fieldable_id   :integer
#  fieldable_type :string(255)
#  name           :string(255)
#  type           :string(255)
#  settings       :text
#  ordering       :integer
#  required       :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  kpi_id         :integer
#

class FormField < ActiveRecord::Base
  MIN_OPTIONS_ALLOWED = 1
  MIN_STATEMENTS_ALLOWED = 1
  VALID_RANGE_FORMATS = %w(digits characters words value)
  belongs_to :fieldable, polymorphic: true

  TRENDING_FIELDS_TYPES = %w(FormField::Text FormField::TextArea)

  has_many :options, -> { order('form_field_options.ordering ASC').where(option_type: 'option') }, class_name: 'FormFieldOption', dependent: :destroy, inverse_of: :form_field, foreign_key: :form_field_id
  has_many :statements, -> { order('form_field_options.ordering ASC').where(option_type: 'statement') }, class_name: 'FormFieldOption', dependent: :destroy, inverse_of: :form_field, foreign_key: :form_field_id
  has_many :form_field_results, dependent: :delete_all, inverse_of: :form_field, foreign_key: :form_field_id
  belongs_to :kpi
  accepts_nested_attributes_for :options, allow_destroy: true
  accepts_nested_attributes_for :statements, allow_destroy: true

  serialize :settings

  validates :fieldable_id, presence: true, numericality: true
  validates :fieldable_type, presence: true
  validates :name, presence: true
  validates :type, presence: true,
                   format: { with: /\AFormField::/ }
  validates :ordering, presence: true, numericality: true

  validate :valid_range_settings?

  validates :kpi_id,
            uniqueness: { scope: [:fieldable_id, :fieldable_type], allow_blank: true, allow_nil: true }

  scope :for_campaigns, ->(campaigns) { where(fieldable_type: 'Campaign', fieldable_id: campaigns) }
  scope :for_activity_types, ->(activity_types) { where(fieldable_type: 'ActivityType', fieldable_id: activity_types) }

  def self.for_events_in_company(companies)
    joins(
      'INNER JOIN campaigns ON campaigns.id=form_fields.fieldable_id AND
      form_fields.fieldable_type=\'Campaign\''
    ).where(campaigns: { company_id: companies })
  end

  def self.for_activities
    joins(
      'INNER JOIN activity_types ON activity_types.id=form_fields.fieldable_id AND
      form_fields.fieldable_type=\'ActivityType\''
    )
  end

  def self.in_company(company)
    joins(
      'LEFT JOIN campaigns cj ON cj.id=form_fields.fieldable_id AND
       form_fields.fieldable_type=\'Campaign\'
       LEFT JOIN activity_types atj ON atj.id=form_fields.fieldable_id AND
       form_fields.fieldable_type=\'ActivityType\''
    ).where('cj.company_id in (:company_ids) OR atj.company_id in (:company_ids)', company_ids: company)
  end

  def self.for_activity_types_in_company(companies)
    for_activities.where(activity_types: { company_id: companies })
  end

  def self.for_activity_types_in_campaigns(campaigns)
    for_activities.joins(
      'INNER JOIN activity_type_campaigns
             ON activity_type_campaigns.activity_type_id=activity_types.id'
    ).where(activity_type_campaigns: { campaign_id: campaigns })
  end

  def self.selectable_as_report_field
    where.not(type: [
      'FormField::UserDate', 'FormField::Section', 'FormField::Summation', 'FormField::LikertScale'
    ])
  end

  def self.for_trends(campaigns: nil, activity_types: nil)
    where(type: TRENDING_FIELDS_TYPES).where(
      '(form_fields.fieldable_type=? AND form_fields.fieldable_id in (?)) OR
       (form_fields.fieldable_type=? AND form_fields.fieldable_id in (?))',
      'Campaign', (campaigns || []) + [0],
      'ActivityType', (activity_types || []) + [0]
    ).order('form_fields.name ASC')
  end

  def field_options(_result)
    { as: :string }
  end

  def field_classes
    ['input-xlarge'] + (is_numeric? ? ['number'] : [])
  end

  def field_data
    {}
  end

  def store_value(value)
    value
  end

  def format_html(result)
    result.value
  end

  def format_csv(result)
    result.value
  end

  def format_chart_data(result)
    return unless is_optionable?
    if result.present?
      Hash[options_for_input.map do |s|
        [s[0], result.value[s[1].to_s].try(:to_f) || 0]
      end]
    end
  end

  def css_class
    self.class.name.underscore.gsub('/', '_')
  end

  def is_hashed_value?
    false
  end

  def is_numeric?
    false
  end

  def is_attachable?
    false
  end

  # Returns true if the field can have options associated
  def is_optionable?
    false
  end

  def trendeable?
    TRENDING_FIELDS_TYPES.include?(self.type)
  end

  def type_name
    self.class.name.split('::').last
  end

  def validate_result(result)
    if required? && (result.value.nil? || (result.value.is_a?(String) && result.value.empty?))
      result.errors.add(:value, I18n.translate('errors.messages.blank'))
    end
    if is_hashed_value?
      if required? && (result.value.nil? || (result.value.is_a?(Hash) && result.value.empty?))
        result.errors.add(:value, I18n.translate('errors.messages.blank'))
      elsif result.value.present?
        if result.value.is_a?(Hash)
          if result.value.any? { |k, v| v != '' && !is_valid_value_for_key?(k, v) }
            result.errors.add :value, :invalid
          elsif (result.value.keys.map(&:to_i) - valid_hash_keys).any?
            result.errors.add :value, :invalid  # If a invalid key was given
          end
        else
          result.errors.add :value, :invalid
        end
      end
    end

    if has_range_value_settings? && result.value.present? && !result.value.to_s.empty?
      val = result.value.to_s.strip
      if settings['range_format'] == 'characters'
        items = val.length
      elsif settings['range_format'] == 'words'
        items = val.scan(/\w+/).size
      elsif settings['range_format'] == 'digits'
        items = val.gsub(/[\.\,\s]/, '').length
      elsif settings['range_format'] == 'value'
        items = val.to_f rescue 0
      end

      min_result = !settings['range_min'].present? || (items >= settings['range_min'].to_i)
      max_result = !settings['range_max'].present? || (items <= settings['range_max'].to_i)

      if !min_result || !max_result
        result.errors.add :value, :invalid
      end
    end
  end

  def options_for_input(include_excluded = false)
    @options_for_input ||=
      if kpi_id.present?
        if include_excluded
          kpi.kpis_segments
        else
          kpi.kpis_segments.where.not(id: (settings.try(:[], 'disabled_segments') || [0]).map(&:to_i))
        end.pluck(:text, :id)
      else
        options.order(:ordering).map { |o| [o.name, o.id] }
      end
  end

  # Allow to create new form fields from the report builder. Rails doesn't like mass-assignment of
  # the "type" attribute, so, after a basic validation, we assign this only for new fields
  def field_type=(type)
    self.type = type if new_record?
  end

  def min_options_allowed
    MIN_OPTIONS_ALLOWED
  end

  def min_statements_allowed
    MIN_STATEMENTS_ALLOWED
  end

  def value_is_numeric?(value)
    true if Float(value) rescue false
  end

  def range_message
    return unless has_range_value_settings?
    if settings['range_min'].present? && settings['range_max'].present?
      I18n.translate("form_fields_ranges.#{type_name.downcase}.min_max",
                     range_min: settings['range_min'],
                     range_max: settings['range_max'],
                     range_format: settings['range_format'],
                     field_id: id)
    elsif settings['range_min'].present?
      I18n.translate("form_fields_ranges.#{type_name.downcase}.min",
                     range_min: settings['range_min'],
                     range_format: settings['range_format'],
                     field_id: id)
    elsif settings['range_max'].present?
      I18n.translate("form_fields_ranges.#{type_name.downcase}.max",
                     range_max: settings['range_max'],
                     range_format: settings['range_format'],
                     field_id: id)
    else
      ''
    end.html_safe
  end


  protected

  def valid_hash_keys
    options_for_input.map { |o| o[1] }
  end

  def is_valid_value_for_key?(_, value)
    value_is_numeric?(value)
  end

  def has_range_value_settings?
    settings &&
    settings.key?('range_format') && settings['range_format'] &&
    (
      (settings.key?('range_min') && settings['range_min'].present?) ||
      (settings.key?('range_max') && settings['range_max'].present?)
    )
  end

  def valid_range_settings?
    return unless settings

    errors.add :settings, :invalid if settings['range_format'] && !VALID_RANGE_FORMATS.include?(settings['range_format'])
    errors.add :settings, :invalid if settings['range_max'].present? && !value_is_numeric?(settings['range_max'])
    errors.add :settings, :invalid if settings['range_min'].present? && !value_is_numeric?(settings['range_min'])

    errors.add :settings, :invalid if settings['range_min'].present? && settings['range_max'].present? &&
                                      value_is_numeric?(settings['range_min']) &&
                                      value_is_numeric?(settings['range_max']) &&
                                      settings['range_min'].to_i > settings['range_max'].to_i
  end
end
