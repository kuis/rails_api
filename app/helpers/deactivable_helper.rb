module DeactivableHelper

  module ViewMethods
    def active_inactive_buttons(resource, message=nil)
      has_parent ||= respond_to?(:parent?) && parent?
      if resource.active?
        link_to(content_tag(:i, '', class: 'icon-remove-sign'),  [:deactivate, (has_parent ? [parent, resource] : resource)].flatten, class: 'toggle-inactive active-toggle-btn-'+resource.class.name.underscore.downcase+'-'+resource.id.to_s, confirm: message, remote: true, title: 'Deactivate')
      else
        link_to(content_tag(:i, '', class: 'icon-check-sign'), [:activate, (has_parent ? [parent, resource] : resource)].flatten, class: 'toggle-active active-toggle-btn-'+resource.class.name.underscore.downcase+'-'+resource.id.to_s, remote: true, title: 'Activate')
      end
    end
  end


  module InstanceMethods
    include DeactivableHelper::ViewMethods
    def deactivate
      if resource.active?
        resource.deactivate!
      end
    end

    def activate
      unless resource.active?
        resource.activate!
      end
      render 'deactivate'
    end
  end


  def self.included(receiver)
    receiver.send(:include,  InstanceMethods)
  end
end
