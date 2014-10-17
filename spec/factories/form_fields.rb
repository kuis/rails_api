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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :form_field do
    fieldable nil
    sequence(:name) { |n| "Form Field #{n}" }
    type nil
    settings nil
    ordering 1
    required false
  end

  factory :form_field_text_area, class: FormField::TextArea do
    sequence(:name) { |n| "Form Field TextArea #{n}" }
    type 'FormField::TextArea'
    ordering 1
  end

  factory :form_field_number, class: FormField::Number do
    sequence(:name) { |n| "Form Field Number #{n}" }
    type 'FormField::Number'
    ordering 1
  end

  factory :form_field_text, class: FormField::Text do
    sequence(:name) { |n| "Form Field Text #{n}" }
    type 'FormField::Text'
    ordering 1
  end

  factory :form_field_radio, class: FormField::Radio do
    sequence(:name) { |n| "Form Field Radio #{n}" }
    type 'FormField::Radio'
    ordering 1
  end

  factory :form_field_checkbox, class: FormField::Checkbox do
    sequence(:name) { |n| "Form Field Checkbox #{n}" }
    type 'FormField::Checkbox'
    ordering 1
  end

  factory :form_field_percentage, class: FormField::Percentage do
    sequence(:name) { |n| "Form Field Percentage #{n}" }
    type 'FormField::Percentage'
    ordering 1
  end

  factory :form_field_summation, class: FormField::Summation do
    sequence(:name) { |n| "Form Field Summation #{n}" }
    type 'FormField::Summation'
    ordering 1
  end

  factory :form_field_dropdown, class: FormField::Dropdown do
    sequence(:name) { |n| "Form Field Dropdown #{n}" }
    type 'FormField::Dropdown'
    ordering 1
  end

  factory :form_field_brand, class: FormField::Brand do
    sequence(:name) { |n| "Form Field Brand #{n}" }
    type 'FormField::Brand'
    ordering 1
  end

  factory :form_field_marque, class: FormField::Marque do
    sequence(:name) { |n| "Form Field Marque #{n}" }
    type 'FormField::Marque'
    ordering 1
  end
end
