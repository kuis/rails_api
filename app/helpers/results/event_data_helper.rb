require "benchmark"
module Results
  module EventDataHelper
    def custom_fields_to_export_headers
      custom_fields_to_export.map{|id, f| f.is_segmented? ? f.kpi.kpis_segments.map{|s| "#{f.name}: #{s.text}"} : f.name }.flatten.map(&:upcase)
    end

    def custom_fields_to_export_values(event)
      event_values = empty_values_hash
      results = event.results.where(form_field_id: active_fields_for_campaign(event.campaign_id)).all
      results.each do |result|
        result.form_field = custom_fields_to_export[result.form_field_id]
        unless result.kpis_segment_id.nil?
          event_values["#{result.form_field_id}-#{result.kpis_segment_id}"] = result.display_value
        else
          event_values[result.form_field_id.to_s] = result.display_value
        end
      end
      event_values.values
    end

    def area_for_event(event)
      campaign_from_cache(event.campaign_id).areas.select{|a| a.place_in_scope?(event.place) }.map(&:name).join(', ') unless event.place.nil?
    end

    private
      # Returns an array of nils that need to be populated by the event
      # where the key is the id of the field + the id of the segment id if the field is segmentable
      def empty_values_hash
        @empty_values_hash ||= Hash[*custom_fields_to_export.map{|id, field| field.is_segmented? ? field.kpi.kpis_segments.map{|s| ["#{id}-#{s.id}", nil]} : [id.to_s, nil]}.flatten]
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
          unless current_company_user.is_admin?
            if campaign_ids.any?
              campaign_ids = campaign_ids.map(&:to_i) & current_company_user.accessible_campaign_ids
            else
              campaign_ids = current_company_user.accessible_campaign_ids
            end
          end
          if campaign_ids.any?
            fields_scope = CampaignFormField.joins('LEFT JOIN kpis on kpis.id=campaign_form_fields.kpi_id').
                                      where(kpis: {company_id: current_company_user.company_id}).
                                      where('campaign_form_fields.kpi_id is null or kpis.module=?', 'custom').
                                      order('campaign_form_fields.name ASC')
            fields_scope = fields_scope.where(campaign_id: campaign_ids) unless current_company_user.is_admin? and campaign_ids.empty?
            Hash[fields_scope.map{|field| [field.id, field]}]
          else
            {}
          end
        end
        @kpis_to_export
      end

      def campaign_from_cache(id)
        @_campaign_cache ||= []
        @_campaign_cache[id] ||= Campaign.find(id)
        @_campaign_cache[id]
      end
  end
end