# Renders an ItemContainer as a <ul> element and its containing items as <li> elements.
# Prepared to use inside the topbar of Twitter Bootstrap http://twitter.github.com/bootstrap/#navigation
#
# Register the renderer and use following code in your view:
#   render_navigation(level: 1..2, renderer: :bootstrap_topbar_list, expand_all: true)
class SimpleNavigationBootstrap < SimpleNavigation::Renderer::Base
  def render(item_container)
    if options[:is_subnavigation]
      ul_class = 'dropdown-menu'
    else
      ul_class = "nav #{options[:nav_class]}"
    end

    list_content = item_container.items.reduce([]) do |list, item|
      li_options = item.html_options.reject { |k, _v| k == :link }
      if include_sub_navigation?(item)
        li_options[:class] = [li_options[:class], 'dropdown'].flatten.compact.join(' ')
      end
      li_content = tag_for(item)
      if include_sub_navigation?(item)
        li_content << render_sub_navigation_for(item)
      end
      list << content_tag(:li, li_content, li_options)
    end.join
    if skip_if_empty? && item_container.empty?
      ''
    else
      content_tag(:ul, list_content, id: item_container.dom_id, class: [item_container.dom_class, ul_class].flatten.compact.join(' '))
    end
  end

  def render_sub_navigation_for(item)
    item.sub_navigation.render(options.merge(is_subnavigation: true))
  end

  protected

  def tag_for(item)
    name = item.name
    opts =  link_options_for(item)
    if opts[:icon_class]
      name = content_tag(:span, '', class: opts[:icon_class]) + name
      opts = opts.except(:icon_class)
    end
    if item.url.nil?
      content_tag('span', name, opts.except(:method))
    else
      link_to(name, item.url, opts)
    end
  end

  # Extracts the options relevant for the generated link
  #
  def link_options_for(item)
    special_options = { method: item.method }.reject { |_k, v| v.nil? }
    link_options = item.html_options[:link] || {}
    opts = special_options.merge(link_options)
    opts[:class] = [link_options[:class], item.selected_class, dropdown_link_class(item)].flatten.compact.join(' ')
    opts.delete(:class) if opts[:class].nil? || opts[:class] == ''
    opts
  end

  def dropdown_link_class(item)
    if include_sub_navigation?(item) && !options[:is_subnavigation]
      'dropdown-toggle'
    end
  end
end
