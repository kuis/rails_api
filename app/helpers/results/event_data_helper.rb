module Results
  module EventDataHelper
    def custom_fields_to_export_headers
      @_headers ||= custom_columns.values.map(&:upcase)
    end

    def custom_fields_to_export_values(event)
      # We are reusing the same object for each result to reduce memory usage
      @result ||= EventResult.new
      event_values = empty_values_hash
      ActiveRecord::Base.connection.select_all(
        event.results.where(form_field_id: active_fields_for_campaign(event.campaign_id)).
                  select('event_results.form_field_id, event_results.kpis_segment_id, event_results.value').to_sql
      ).each do |row|
        @result.form_field = custom_fields_to_export[row['form_field_id'].to_i]
        @result.value = row['value']
        @result.kpis_segment_id = row['kpis_segment_id']
        id = @result.form_field.kpi_id.nil? ? "field_#{@result.form_field_id}" : "kpi_#{@result.form_field.kpi_id}"
        unless @result.kpis_segment_id.nil?
          event_values["#{id}-#{@result.kpis_segment_id}"] = @result.display_value
        else
          event_values[id] = @result.display_value
        end
      end
      event_values.values
    end

    def area_for_event(event)
      campaign_from_cache(event.campaign_id).areas.select{|a| a.place_in_scope?(event.place) }.map(&:name).join(', ') unless event.place.nil?
    end

    def team_member_for_event(event)
      ActiveRecord::Base.connection.select_values("
        #{event.users.joins(:user).select('users.first_name || \' \' || users.last_name AS name' ).reorder(nil).to_sql}
        UNION ALL
        #{event.teams.select('teams.name').reorder(nil).to_sql}
        ORDER BY name
      ").join(', ')
    end

    def url_for_event(event)
      Rails.application.routes.url_helpers.event_url(event)
    end

    private
      # Returns an array of nils that need to be populated by the event
      # where the key is the id of the field + the id of the segment id if the field is segmentable
      def empty_values_hash
        @empty_values_hash ||= custom_columns.dup
        @empty_values_hash.each{|k,v| @empty_values_hash[k] = nil }
        @empty_values_hash
      end

      # Returns and array of Form Field IDs that are assigned to a campaign
      def active_fields_for_campaign(campaign_id)
        @campaign_fields ||= {}
        @campaign_fields[campaign_id] ||= campaign_from_cache(campaign_id).form_fields.where(id: custom_fields_to_export.keys).map(&:id)
        @campaign_fields[campaign_id]
      end

      def custom_fields_to_export
        @kpis_to_export ||= begin
          campaign_ids = []
          campaign_ids = params[:campaign] if params[:campaign] && params[:campaign].any?
          if params[:q].present? && match = /\Acampaign,([0-9]+)/.match(params[:q])
            campaign_ids+= [match[1]]
          end
          campaign_ids = campaign_ids.uniq.compact
          unless current_company_user.is_admin?
            if campaign_ids.any?
              campaign_ids = campaign_ids.map(&:to_i) & current_company_user.accessible_campaign_ids
            else
              campaign_ids = current_company_user.accessible_campaign_ids
            end
          end
          if campaign_ids.any?
            fields_scope = CampaignFormField.joins('LEFT JOIN kpis on kpis.id=campaign_form_fields.kpi_id').
                                      where("kpis.company_id is null or kpis.company_id=?", current_company_user.company_id).
                                      where('campaign_form_fields.kpi_id is null or (kpis.module=? or kpis.id=?)', 'custom', Kpi.age.id).
                                      order('case when kpis.module is null or kpis.module=\'custom\' then 2 else 1 end ASC, campaign_form_fields.name ASC')
            fields_scope = fields_scope.where(campaign_id: campaign_ids) unless current_company_user.is_admin? and campaign_ids.empty?
            Hash[fields_scope.map{|field| [field.id, field]}]
          else
            {}
          end
        end
        @kpis_to_export
      end

      def custom_columns
        @custom_columns ||= Hash[*custom_fields_to_export.map do |id, field|
          if field.is_segmented?
            field.kpi.kpis_segments.map{|s| ["kpi_#{field.kpi_id}-#{s.id}", "#{field.kpi.name}: #{s.text}"]}
          else
            field.kpi_id.nil? ? ["field_#{id}", field.name] : ["kpi_#{field.kpi_id}", field.kpi.name]
          end
        end.flatten]
      end

      def campaign_from_cache(id)
        @_campaign_cache ||= {}
        @_campaign_cache[id] ||= Campaign.find(id)
        @_campaign_cache[id]
      end
  end
end