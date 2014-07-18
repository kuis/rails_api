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

class FormField::Marque < FormField::Dropdown
  def field_options(result)
    marques = []
    ff_brand  = FormField.where(fieldable_id: fieldable_id, fieldable_type: fieldable_type, type: 'FormField::Brand').first
    # ff_brand = if result.resultable.is_a?(Activity)
    #   result.resultable.activity_type.form_fields.select{|f| f.type == 'FormField::Brand' }
    # elsif result.resultable.respond_to?
    #   result.resultable.form_fields.select{|f| f.type == 'FormField::Brand' }
    # end
    if ff_brand.present?
      if result.id
        results = result.resultable.results_for([ff_brand])
        brand_id = results.first.value if results.present? &&  results.any?
      elsif result.resultable.respond_to?(:campaign) && result.resultable.campaign
        ids = result.resultable.campaign.brand_ids
        brand_id = ids.first if ids.count == 1
      end

      if brand_id.present?
        marques = ::Marque.where(brand_id: brand_id)
      end
    end
    {as: :select, collection: marques, label: self.name, field_id: self.id, options: self.settings, required: self.required, input_html: {value: result.value, class: 'form-field-marque', multiple: self.multiple?, required: (self.required? ? 'required' : nil)}}
  end

  def is_optionable?
    true
  end

  def format_html(result)
    unless result.value.nil? || result.value.empty?
      ::Marque.where(id: result.value).pluck(:name).join(', ')
    end
  end
end
