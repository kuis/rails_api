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
#

class FormField < ActiveRecord::Base
  belongs_to :fieldable, polymorphic: true

  has_many :options, class_name: 'FormFieldOption', dependent: :destroy, inverse_of: :form_field, foreign_key: :form_field_id, order: 'form_field_options.ordering ASC'
  accepts_nested_attributes_for :options, allow_destroy: true

  serialize :settings

  validates :fieldable_id, presence: true, numericality: true
  validates :fieldable_type, presence: true
  validates :name, presence: true
  validates :type, presence: true,
    format: { with: /\AFormField::/ }
  validates :ordering, presence: true, numericality: true

  def field_options(result)
    {as: :string}
  end

  def field_classes
    ['input-xlarge']
  end

  def store_value(value)
    value
  end

  def format_html(result)
    result.value
  end

  def css_class
    self.class.name.underscore.gsub('/', '_')
  end

  def is_hashed_value?
    false
  end

  # Allow to create new form fields from the report builder. Rails doesn't like mass-assignment of
  # the "type" attribute, so, after a basic validation, we assign this only for new fields
  def field_type=(type)
    self.type = type if new_record?
  end
end
