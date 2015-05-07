module EventPhases
  extend ActiveSupport::Concern

  def phases
    {
      current_phase: current_phase,
      next_step: next_step,
      phases: {
        plan: plan_phases,
        execute: execute_phases,
        results: results_phases
      }
    }
  end

  # Returns the current phase the event is based in the following rules:
  # * plan: if the event is in the future
  # * execute: if the event is NOT in the future and no results have been entered
  # * results: if the event is NOT in the future and results have been entered
  def current_phase
    if in_future?
      :plan
    elsif event_data?
      :results
    else
      :execute
    end
  end

  def next_step
    { plan: plan_phases,
      execute: execute_phases,
      results: results_phases }[current_phase].find { |p| p[:complete] == false }
  end

  def plan_phases
    @plan_phases ||= [].tap do |phases|
      phases.push({ id: :info, title: 'Basic Info', complete: true })
      phases.push({ id: :contacts, title: 'Contacts', complete: contacts.any? })
      phases.push({ id: :tasks, title: 'Tasks', complete: tasks.any? })
      phases.push({ id: :documents, title: 'Documents', complete: documents.any? })
    end
  end

  def execute_phases
    @execute_phases ||= [].tap do |phases|
      phases.push(id: :per, title: 'Post Event Recap', complete: event_data?)
      phases.push(id: :activities, title: 'Activities',
                  complete: activities.any?,
                  conditions: -> { can?(:show, Activity) }
                 ) if campaign.activity_types.any?
      phases.push(id: :attendance, title: 'Attendance',
                  complete: invites.any?, if: proc { |_| can?(:show, Activity) }
                 ) if campaign.enabled_modules.include?('attendance')
      phases.push(id: :expenses, title: 'Expenses',
                  complete: expenses_complete?, if: proc { |event| can?(:expenses, event) }
                 ) if campaign.enabled_modules.include?('expenses')
      phases.push(id: :photos, title: 'Photos',
                  complete: photos_complete?, if: proc { |event| can?(:photos, event) }
                 ) if campaign.enabled_modules.include?('photos')
      phases.push(id: :comments, title: 'Consumer Comments',
                  complete: comments_complete?, if: proc { |event| can?(:comments, event) }
                 ) if campaign.enabled_modules.include?('comments')
    end
  end

  def results_phases
    @results_phases ||= [].tap do |phases|
      phases.push(id: :approve_per, title: 'Approve PER', complete: approved?,
                  if: proc { |event| can?(:approve, event) })
    end
  end

  def expenses_complete?
    module_have_items_and_in_valid_range?('expenses', event_expenses.count)
  end

  def photos_complete?
    module_have_items_and_in_valid_range?('photos', photos.active.count)
  end

  def comments_complete?
    module_have_items_and_in_valid_range?('comments', comments.count)
  end

  def module_items_valid?(module_name, count)
    min = campaign.module_setting(module_name, 'range_min')
    max = campaign.module_setting(module_name, 'range_max')
    (min.blank? || (count >= min.to_i)) && (max.blank? || (count <= max.to_i))
  end

  # A module is considered complete if there are not range validation defined
  # and have at least one item. If there are range validations, then it's completed
  # only if those are met.
  def module_have_items_and_in_valid_range?(module_name, count)
    (module_range_settings_empty?(module_name) && count > 0) ||
      (!module_range_settings_empty?(module_name) && module_items_valid?(module_name, count))
  end

  def module_range_settings_empty?(module_name)
    campaign.module_setting(module_name, 'range_min').blank? &&
      campaign.module_setting(module_name, 'range_max').blank?
  end
end