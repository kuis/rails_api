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

class FormField::LikertScale < FormField
  def field_options(result)
    {as: :likert_scale, collection: self.options.order(:ordering), statements: self.statements.order(:ordering), label: self.name, field_id: self.id, options: self.settings, required: self.required, input_html: {value: result.value, class: field_classes, min: 0, step: 'any', required: (self.required? ? 'required' : nil)}}
  end

  def field_classes
    []
  end

  def is_hashed_value?
    true
  end
end