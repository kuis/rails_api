module Analysis
	module ReportsHelper
    #
    # ___________.__                _____                          __
    # \__    ___/|  |__   ____     /     \   ____   ____   _______/  |_  ___________
    #   |    |   |  |  \_/ __ \   /  \ /  \ /  _ \ /    \ /  ___/\   __\/ __ \_  __ \
    #   |    |   |   Y  \  ___/  /    Y    (  <_> )   |  \\___ \  |  | \  ___/|  | \/
    #   |____|   |___|  /\___  > \____|__  /\____/|___|  /____  > |__|  \___  >__|
    #                 \/     \/          \/            \/     \/            \/
    #  This methods fetchs all the statistics for events/promo hours used on the reports
    #  for the campaigns and staff sections
    #
    def load_events_and_promo_hours_data

      events_goal      = @goals.detect{|g| g.kpi_id == Kpi.events.id      }.try(:value) || 0
      promo_hours_goal = @goals.detect{|g| g.kpi_id == Kpi.promo_hours.id }.try(:value) || 0

      data = {
          'scheduled_events' => 0,
          'remaining_events' => 0,
          'approved_events' => 0,
          'expected_events' => 0,
          'expected_events_today' => 0,
          'events_percentage' => 0,
          'events_percentage_today' => 0,
          'events_goal' => events_goal,

          'scheduled_promo_hours' => 0,
          'approved_promo_hours' => 0,
          'remaining_promo_hours' => 0,
          'expected_promo_hours' => 0,
          'expected_promo_hours_today' => 0,
          'promo_hours_percentage' => 0,
          'promo_hours_percentage_today' => 0,
          'promo_hours_goal' => promo_hours_goal,

          'approved_events_week_avg' => 0,
          'approved_promo_hours_week_avg' => 0,
          'approved_events_this_week' => nil,
          'approved_promo_hours_this_week' => nil,

          'days' => {},
          'weeks' => {}
      }

      # Find the first and last event on scope
      result = @events_scope.select('min(start_at) as first_event_at, max(start_at) as last_event_at, count(events.id) as qty_events').first

      return data if result.nil? || result.qty_events == 0

      data['first_event_at'] = first_event_at = Timeliness.parse(result.first_event_at, zone: :current)
      data['last_event_at'] = last_event_at  = Timeliness.parse(result.last_event_at, zone: :current).end_of_day

      # Initialize the weeks array
      date = first_event_at.beginning_of_week
      while date < last_event_at
        data['weeks'][date.to_s(:numeric)] = {
          'scheduled_events' => 0,
          'approved_events' => 0,
          'approved_promo_hours' => 0,
          'scheduled_promo_hours' => 0,
          'cumulative_approved_events' => 0,
          'cumulative_scheduled_events' => 0,
          'cumulative_approved_promo_hours' => 0,
          'cumulative_scheduled_promo_hours' => 0
        }
        date = date + 1.week
      end

      # Initialize the days arrray
      data['days'] = {}
      (first_event_at.to_date..last_event_at.to_date).each{|d| data['days'][d.to_s(:numeric)] ||= {'scheduled_events' => 0, 'approved_events' => 0, 'approved_promo_hours' => 0, 'scheduled_promo_hours' => 0}}

      # Get the events/promo hours data
      tz = Time.zone.now.strftime('%Z')
      date_convert = "to_char(TIMEZONE('UTC', start_at) AT TIME ZONE '#{tz}', 'YYYY/MM/DD')"
      scope = @events_scope.select("count(events.id) as events_count, sum(promo_hours) as promo_hours, #{date_convert} as event_start, events.aasm_state as group_recap_status").group("#{date_convert}, events.aasm_state").order(date_convert)
      weeks_with_approved_events = 0
      previous_week = nil
      scope.each do |event_day|
        date = Timeliness.parse(event_day.event_start, zone: :current)
        day = date.to_s(:numeric)
        data['days'][day]['approved_promo_hours']   = event_day.promo_hours.to_i  if event_day.group_recap_status == 'approved'
        data['days'][day]['scheduled_promo_hours'] += event_day.promo_hours.to_i
        data['days'][day]['approved_events']        = event_day.events_count.to_i if event_day.group_recap_status == 'approved'
        data['days'][day]['scheduled_events']      += event_day.events_count.to_i

        # Add the total to the week
        week = date.beginning_of_week.to_s(:numeric)
        data['weeks'][week]['approved_promo_hours']   += event_day.promo_hours.to_i  if event_day.group_recap_status == 'approved'
        data['weeks'][week]['scheduled_promo_hours']  += event_day.promo_hours.to_i
        data['weeks'][week]['approved_events']        += event_day.events_count.to_i if event_day.group_recap_status == 'approved'
        data['weeks'][week]['scheduled_events']       += event_day.events_count.to_i

        # Totals
        data['approved_events']       += event_day.events_count.to_i  if event_day.group_recap_status == 'approved'
        data['scheduled_events']      += event_day.events_count.to_i
        data['approved_promo_hours']  += event_day.promo_hours.to_i if event_day.group_recap_status == 'approved'
        data['scheduled_promo_hours'] += event_day.promo_hours.to_i

        if week != previous_week and event_day.group_recap_status == 'approved'
          weeks_with_approved_events += 1
          previous_week = week
        end
      end

      scheduled_events = scheduled_promo_hours = approved_events = approved_promo_hours = 0
      data['weeks'].each do |week, values|
        approved_promo_hours += values['approved_promo_hours']
        scheduled_promo_hours += values['scheduled_promo_hours']
        approved_events += values['approved_events']
        scheduled_events += values['scheduled_events']
        # Cumulative events/promo hours
        values['cumulative_approved_promo_hours']   = approved_promo_hours
        values['cumulative_scheduled_promo_hours']  = scheduled_promo_hours
        values['cumulative_approved_events']        = approved_events
        values['cumulative_scheduled_events']       = scheduled_events
      end

      # Avg of approved events/promo hours per week
      data['approved_events_week_avg'] = data['weeks'].values.sum{|v| v['approved_events']}
      data['approved_promo_hours_week_avg']  = data['weeks'].values.sum{|v| v['approved_promo_hours']}

      this_week = Time.zone.now.beginning_of_week.to_s(:numeric)
      if data['weeks'].has_key?(this_week)
        data['approved_events_this_week'] = data['weeks'][this_week]['approved_events']
        data['approved_promo_hours_this_week'] = data['weeks'][this_week]['approved_promo_hours']
      end

      # Compute current and expectation percentages
      total_days = ((last_event_at  - first_event_at).to_i / 86400).round
      today_days = ((Time.zone.now  - first_event_at).to_i / 86400).round

      total_days = 1 if total_days == 0

      data['expected_events'] = expected_total =  events_goal > 0 ? events_goal : data['scheduled_events']
      data['remaining_events'] = expected_total - data['approved_events']
      data['remaining_events'] = 0 if data['remaining_events'] < 0
      data['events_percentage'] = data['approved_events'] * 100 / expected_total if expected_total > 0
      data['events_percentage_today'] = [100, today_days * expected_total / total_days].min
      if expected_total > 0 && total_days > 0
        data['expected_events_today'] = today_days * expected_total / total_days                             # How many events are expected to be completed today
        data['events_percentage_today'] = [100, data['expected_events_today'] * 100 / expected_total].min    # and what percentage does that represents
      end


      data['expected_promo_hours'] = expected_total =  promo_hours_goal > 0 ? promo_hours_goal : data['scheduled_promo_hours']
      data['remaining_promo_hours'] = expected_total - data['approved_promo_hours']
      data['remaining_promo_hours'] = 0 if data['remaining_promo_hours'] < 0
      data['promo_hours_percentage'] = data['approved_promo_hours'] * 100 / expected_total if expected_total > 0
      if expected_total > 0 && total_days > 0
        data['expected_promo_hours_today'] = today_days * expected_total / total_days                                   # How many promo hours are expected to be completed today
        data['promo_hours_percentage_today'] = [100, data['expected_promo_hours_today'] * 100 / expected_total].min    # and what percentage does that represents
      end


      data
    end

    def each_events_goal
      totals = @events_scope.joins(:results).where(event_results:{ kpi_id: @goals.map(&:kpi)})
                          .select('sum(scalar_value) as total_value, event_results.kpi_id, event_results.kpis_segment_id')
                          .group('event_results.kpi_id, event_results.kpis_segment_id')

      @goals.each do |goal|
        goal_scope = @events_scope
        if goal.start_date.present? || goal.due_date.present?
          goal_scope = goal_scope.where('events.start_at > ?', goal.start_date.beginning_of_day) if goal.start_date.present?
          goal_scope = goal_scope.where('events.end_at <= ?', goal.start_date.end_of_day) if goal.due_date.present?
        end

        if goal.kpis_segment_id.nil?
          # Handle special kpis types
          completed = case goal.kpi.kpi_type
          when 'expenses'
            goal_scope.joins(:event_data).sum('event_data.spent').to_i
          when 'promo_hours'
            goal_scope.sum('promo_hours')
          when 'events'
            goal_scope.count
          when 'photos'
            AttachedAsset.photos.for_events(goal_scope).count
          else
            if goal.start_date.present? || goal.due_date.present?
              data = goal_scope.joins(:results)
                          .select('sum(scalar_value) as total_value')
                          .where(event_results:{ kpi_id: goal.kpi_id})
                          .group('event_results.kpi_id').first
            else
              data = totals.detect{|row| row.kpi_id.to_i == goal.kpi_id.to_i && row.kpis_segment_id.to_i == goal.kpis_segment_id.to_i }
            end
            Rails.logger.debug "data ==> #{data.inspect}"
            data.total_value.to_i unless data.nil?
          end

          if completed.nil?
            yield goal, 0, 100, goal.value, 0
          else
            goal_value = goal.value || 0
            total_count = completed
            remaining_count =  goal_value - completed
            completed_percentage = completed * 100 / goal_value rescue 0
            remaining_percentage = 100 - completed_percentage
            yield goal, completed_percentage, remaining_percentage, remaining_count, total_count
          end
        end
      end
    end
	end
end