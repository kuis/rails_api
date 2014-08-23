module DocumentIconHelper
  def document_icon(file_extension)
    icon_folder = 'file-types/32px/'
    icon_filename = icon_folder + file_extension.to_s + '.png'
    unless File.exist?("#{Rails.root}/app/assets/images/#{icon_filename}")
      icon_filename = icon_folder + '_blank.png'
    end
    image_tag(icon_filename)
  end
end