module Html
  class EventGuidedMessagePresenter < BasePresenter
    def current_steps
      @current_steps ||= begin
        if @model.rejected?
          [{ id: 'rejected' }]
        else
          name, steps = phases[:phases].find { |name, _| name == phases[:current_phase] }
          steps.select { |s| !s[:complete] && self.respond_to?("#{name}_#{s[:id]}") } +
          [{ id: :last }]
        end
      end
    end

    def incomplete_steps
      @incomplete_steps ||= begin
        name, steps = phases[:phases].find { |name, _| name == phases[:current_phase] }
        steps.select { |s| !s[:complete] && s[:required] }
      end
    end

    def plan_contacts
      yes_or_skip_or_back 'Do you want to keep track of any contacts?', :contacts
    end

    def plan_tasks
      yes_or_skip_or_back 'Are there any tasks that need to be completed for your event?', :tasks
    end

    def plan_documents
      yes_or_skip_or_back 'Are there any supporting documents to add?', :documents
    end

    def plan_last
      info 'Done! You\'ve completed the planning phase of your event.', :last
    end

    def execute_per
      yes_or_skip_or_back 'Ready to fill out your Post Event Recap? This is required.', :per
    end

    def execute_activities
      yes_or_skip_or_back 'Do you have any activities to add?', :activities
    end

    def execute_attendance
      yes_or_skip_or_back 'Want to add attendees?', :attendance
    end

    def execute_photos
      yes_or_skip_or_back "Do you have any photos to upload? #{module_range_message('photos')}", :photos
    end

    def execute_comments
      yes_or_skip_or_back "What were attendees saying? Do you have consumer comments to add? #{module_range_message('comments')}", :comments
    end

    def execute_expenses
      yes_or_skip_or_back "Do you have any expenses to add? #{module_range_message('expenses')}", :expenses
    end

    def execute_surveys
      yes_or_skip_or_back 'Do you have any surveys to add?', :surveys
    end

    def execute_last
      if can?(:submit) && @model.valid_results?
        message_with_buttons 'It looks like you\'ve collected all required post event info. '\
                             'Are you ready to submit your report for approval? ', :last,
                             [submit_button]
      else
        if incomplete_steps.empty?
          info 'Done! You\'ve completed the execute phase of your event.', :last
        else
          info "You must #{incomplete_messages} before the execute phase is complete.", :last
        end
      end
    end

    def execute_rejected
      message_with_buttons "Your post event report form was rejected #{rejected_at} for the following reasons: <i>" +
                           (@model.reject_reason.present? ? @model.reject_reason : '') +
                           '</i>. Please make the necessary changes and resubmit when ready ', :last,
                           [submit_button]
    end

    def results_approve_per
      if can?(:approve)
        rejection_message = if @model.reject_reason.to_s.present?
          "It was previously rejected #{rejected_at} for the following reason: <i>#{@model.reject_reason}.</i> "
        end
        message_with_buttons "Your post event report has been submitted for approval #{submitted_at}. #{rejection_message}" +
                            'Please review and either approve or reject.', :approve_per,
                            [approve_button, reject_button]
      else
        info "Your post event report has been submitted for approval #{submitted_at}. Once your report has been reviewed you will be alerted in your notifications.", :approve_per
      end
    end

    def results_last
      return '' unless @model.approved?
      message_with_buttons 'Your post event report has been approved. Check out your post event results below for a recap of your event.', :last,
                           [unapprove_button]
    end

    def module_range_message(module_name)
      return unless @model.campaign.range_module_settings?(module_name)
      min = @model.campaign.module_setting(module_name, 'range_min')
      max = @model.campaign.module_setting(module_name, 'range_max')
      if min.present? && max.present?
        I18n.translate("campaign_module_ranges.#{module_name}.min_max", range_min: min, range_max: max)
      elsif min.present?
        I18n.translate("campaign_module_ranges.#{module_name}.min", range_min: min)
      elsif max.present?
        I18n.translate("campaign_module_ranges.#{module_name}.max", range_max: max)
      else
        ''
      end.html_safe
    end

    def incomplete_messages
      incomplete_steps.map do |incomplete|
        I18n.translate("incomplete_execute_steps.#{incomplete[:id]}")
      end.to_sentence(last_word_connector: ' and ')
    end

    def yes_or_skip_or_back(message, step)
      target = "#event-#{step}"
      next_target = next_target_after(step)
      prev_target = prev_target_before(step)
      first_step = current_steps.first[:id] == step
      [
        h.content_tag(:span, '', class: 'transitional-message'),
        message,
        h.link_to(first_step ? '(Yes)' : '', step_link(target), class: 'step-yes-link smooth-scroll', data: { spytarget: target }),
        prev_target.present? ? h.link_to('(Back)', prev_target, class: 'step-back-link smooth-scroll', data: { spyignore: 'ignore' }) : '',
        h.link_to('(Skip)', next_target, class: 'step-skip-link smooth-scroll', data: { spyignore: 'ignore' })
        
      ].join.html_safe
    end

    def info(message, step)
      prev_target = prev_target_before(step)
      [
        h.link_to('', "#event-#{step}", data: { spytarget: "#event-#{step}" }),
        message,
        prev_target.present? ? h.link_to('(Back)', prev_target, class: 'step-back-link smooth-scroll', data: { spyignore: 'ignore' }) : ''
      ].join.html_safe
    end

    def message_with_buttons(message, step, buttons)
      ([
         h.link_to('', "#event-#{step}", data: { spytarget: "#event-#{step}" }),
         message
       ] + [h.content_tag(:div, buttons.compact.join.html_safe, class: 'step-buttons')]).join.html_safe
    end

    def next_target_after(step)
      index = current_steps.index { |s| s[:id] == step }
      next_step = current_steps[index + 1] || nil
      next_step ? "#event-#{next_step[:id]}" : ''
    end

    def prev_target_before(step)
      index = current_steps.index { |s| s[:id] == step }
      prev_step = index > 0 ? current_steps[index - 1] : nil
      prev_step ? "#event-#{prev_step[:id]}" : ''
    end

    def unapprove_button
      return unless can?(:unapprove)
      h.button_to 'Unapprove', h.unapprove_event_path(@model, return: h.return_path),
                  method: :put, class: 'btn btn-cancel'
    end

    def approve_button
      return unless can?(:approve)
      h.button_to 'Approve', h.approve_event_path(@model, return: h.return_path),
                  method: :put, class: 'btn btn-primary'
    end

    def reject_button
      return unless can?(:reject)
      h.button_to 'Reject', h.reject_event_path(@model, format: :js, return: h.return_path),
                  form: { id: 'reject-post-event' },
                  method: :put, class: 'btn btn-cancel', remote: true
    end

    def submit_button
      return unless can?(:submit)
      h.button_to 'Submit', h.submit_event_path(@model, format: :js, return: h.return_path),
                  class: 'btn btn-cancel', method: :put,
                  remote: true, data: { disable_with: 'submitting' }
    end

    def rejected_at
      date = @model.rejected_at || @model.updated_at
      timeago_tag(date)
    end

    def submitted_at
      date = @model.submitted_at || @model.updated_at
      timeago_tag(date)
    end

    def step_link(target)
      if h.present(@model).current_phase != phases[:current_phase]
        h.phase_event_path(@model, phase: phases[:current_phase]) + target
      else
        target
      end
    end

  end
end
