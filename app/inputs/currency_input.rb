class CurrencyInput < SimpleForm::Inputs::Base
  def input(_wrapper_options)
    "<div class=\"input-prepend\"><span class=\"add-on\">$</span>#{@builder.text_field(attribute_name, input_html_options)}</div>".html_safe
  end
end
