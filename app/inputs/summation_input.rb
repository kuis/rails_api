class SummationInput < SimpleForm::Inputs::Base
  def input
    total = 0
    values = object.send(attribute_name)
    group = "#{object_name}_#{attribute_name}".gsub(/[\[\]]+\z/, '').gsub(/[\[\]]+/, '_').gsub(/_+/, '_')
    output_html = '<table class="summation-field"><tbody>'
    options[:collection].each do |ffo|
      field_name = "#{object_name}[#{attribute_name}][#{ffo.id}]"
      field_id = "#{group}_#{ffo.id}"
      value = values.try(:[], ffo.id.to_s)
      output_html << "<tr><td class='error-col' colspan='2'><span for=\"#{field_id}\" class=\"help-inline\" style=\"display:none;\"></span></td></tr>"
      output_html << '<tr class="field-option">'
      output_html << "<td><label for=\"#{field_id}\" class=\"control-label\">#{ERB::Util.html_escape(ffo.name)}</label></td><td>"
      output_html << @builder.text_field(nil, input_html_options.merge(name: field_name, id: field_id, value: value, 'data-group' => group))
      output_html << '</td></tr>'
      total += value.to_f
    end
    total_id = "#{object_name}_#{attribute_name}_total".gsub(/[\[\]]+\z/, '').gsub(/[\[\]]+/, '_').gsub(/_+/, '_')
    output_html << '<tr class="field-option summation-total-field"><td>'
    output_html << "<label for=\"#{total_id}\">TOTAL</label>"
    output_html << '</td><td>'
    output_html << @builder.text_field(nil, input_html_options.merge(name: 'total', id: total_id, value: total, 'data-group' => group, readonly: true))
    output_html << '</td></tr></tbody></table>'
    output_html.html_safe
  end
end
