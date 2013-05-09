class LocationInput < SimpleForm::Inputs::Base
  def input
    "#{@builder.hidden_field(attribute_name, input_html_options)} <input type='text' id='#{attribute_name}_ac' data-hidden='##{input_class}' value='#{object.send(attribute_name)}' class='places-autocomplete' placeholder='Enter a place' />".html_safe
  end
end