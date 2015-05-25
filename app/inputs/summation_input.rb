class SummationInput < SimpleForm::Inputs::Base
  def input
    output_html = ''
    total = 0
    values = object.send(attribute_name)
    group = "#{object_name}_#{attribute_name}".gsub(/[\[\]]+\z/, '').gsub(/[\[\]]+/, '_').gsub(/_+/, '_')
    field_id = options[:field_id].to_s
    options[:collection].each do |ffo|
      field_name = "#{object_name}[#{attribute_name}][#{ffo.id}]"
      option_id = "#{group}_#{ffo.id}"
      value = values.try(:[], ffo.id.to_s)
      output_html << '<div class="field-option" data-field-id="' + field_id + '">'
      output_html << "<span for=\"#{option_id}\" class=\"help-inline\" style=\"display:none;\"></span>"
      output_html << '<div class="clearfix"></div>'
      output_html << "<label for=\"#{option_id}\" class=\"control-label\">#{ERB::Util.html_escape(ffo.name)}</label>"
      output_html << @builder.text_field(nil, input_html_options.merge(name: field_name, maxlength: 10, id: option_id, value: value, 'data-group' => group))
      output_html << '</div>'
      total += value.to_f
    end
    total_id = "#{object_name}_#{attribute_name}_total".gsub(/[\[\]]+\z/, '').gsub(/[\[\]]+/, '_').gsub(/_+/, '_')
    output_html << '<div class="field-option summation-total-field" data-field-id="' + field_id + '">'
    output_html << "<label for=\"#{total_id}\">TOTAL:</label>"
    output_html << @builder.text_field(nil, input_html_options.merge(name: 'total', id: total_id, value: total, 'data-group' => group, readonly: true))
    output_html << '</label></div>'
    output_html.html_safe
  end
end
