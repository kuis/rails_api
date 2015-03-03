require 'sunspot'

module Sunspot
  module Rails
    module Searchable
      module ClassMethods
        def build_solr_search(params)
          clazz = self
          Sunspot.new_search(self) do
            with :company_id, params[:company_id]
            with_campaign params[:campaign] if params[:campaign]
            with_area params[:area], params[:campaign] if params[:area]
            with_place params[:place] if params[:place]
            with_location params[:location] if params[:location]
            with_status params[:status] if params[:status]
            with_id params[:id] if params[:id]
            with_brand params[:brand] if params[:brand]
            with_venue params[:venue] if params[:venue]
            with_event_status params[:event_status] if params[:event_status]

            between_date_range clazz, params[:start_date], params[:end_date]

            with_user_teams params

            if params[:current_company_user]
              restrict_search_to_user_permissions (params[:search_permission_class] || clazz),
                                                  params[:search_permission],
                                                  params[:current_company_user]
            end

            order_by(params[:sorting], params[:sorting_dir] || :asc) if params[:sorting]
            paginate page: (params[:page] || 1), per_page: (params[:per_page] || 30)
          end
        end

        def do_search(params, include_facets = false, &block)
          search = build_solr_search(params)
          search.build(&block) if block
          search.build(&search_facets) if include_facets
          solr_execute_search(include: [:campaign, :place]) do
            search
          end
        end
      end
    end
  end
end

module Sunspot
  module DSL
    class Scope
      def with_campaign(campaigns)
        if field?(:campaign_id)
          with :campaign_id, campaigns
        elsif field?(:campaing_ids)
          with :campaing_ids, campaigns
        end
      end

      def with_area(areas, campaigns=nil)
        if field?(:area_id)
          with :area_id, areas
        elsif field?(:area_ids)
          with :area_ids, areas
        elsif field?(:place_id) && field?(:location)
          if field?(:campaign_id)
            all_of do
              any_of do
                with :place_id, Area.where(id: areas).joins(:places).where(places: { is_location: false }).pluck('places.id').uniq + [0]
                with :location, Area.where(id: areas).map { |a| a.locations.map(&:id) }.flatten + [0]

                # Customized areas with INCLUDED places
                area_campaigns = AreasCampaign.where(area_id: areas).where('array_length(areas_campaigns.inclusions, 1) >= 1')
                area_campaigns = area_campaigns.where(campaign_id: campaigns) if campaigns
                area_campaigns.each do |ac|
                  all_of do
                    with :campaign_id, ac.campaign_id
                    any_of do
                      with :place_id, ac.inclusions
                      with :location, ac.location_ids
                    end
                  end
                end
              end

              # Customized areas with EXCLUDED places
              area_campaigns = AreasCampaign.where(area_id: areas).where('array_length(areas_campaigns.exclusions, 1) >= 1')
              area_campaigns = area_campaigns.where(campaign_id: campaigns) if campaigns
              area_campaigns.each do |ac|
                any_of do
                  without :campaign_id, ac.campaign_id
                  without :location, Place.where(id: ac.exclusions, is_location: true).pluck('DISTINCT places.location_id') + [-1]
                end
              end
            end
          else
            any_of do
              with :place_id, Area.where(id: areas).joins(:places).where(places: { is_location: false }).pluck('places.id').uniq + [0]
              with :location, Area.where(id: areas).map { |a| a.locations.map(&:id) }.flatten + [0]
            end
          end
        end
      end

      def with_brand(brands)
        if field?(:brand_id)
          with :brand_id, brands
        elsif field?(:brand_ids)
          with :brand_ids, brands
        elsif field?(:campaign_ids) || field?(:campaign_id)
          campaigns = Campaign.with_brands(brands).pluck('campaigns.id')
          campaigns = '-1' if campaigns.empty?
          with_campaign campaigns
        else
          fail 'could not find a field for filtering by brand'
        end
      end

      def with_place(places)
        any_of do
          if field?(:place_id)
            with :place_id, places
          elsif field?(:place_ids)
            with :place_ids, places
          end
          if field?(:location)
            locations = Place.where(is_location: true, id: places).pluck('DISTINCT location_id')
            with :location, locations if locations.any?
          end
        end
      end

      def with_venue(venues)
        if field?(:venue_id)
          with :venue_id, venues
        elsif field?(:venue_ids)
          with :venue_ids, venues
        else
          with_place Venue.where(id: venues).pluck(:place_id)
        end
      end

      def with_location(locations)
        with :location, locations if field?(:location)
      end

      def with_status(statuses)
        with :status, statuses if field?(:status)
      end

      def with_id(ids)
        with :id, ids if field?(:id)
      end

      def with_user(ids)
        with :user_ids, ids if field?(:user_ids)
      end

      def with_user_teams(params)
        return unless (params.key?(:user) && params[:user].present?) ||
                      (params.key?(:team) && params[:team].present?)
        team_ids = []
        team_ids += params[:team] if params.key?(:team) && params[:team].any?
        team_ids += Team.with_user(params[:user]).map(&:id) if params.key?(:user) && params[:user].any?

        any_of do
          with(:user_ids, params[:user]) if params.key?(:user) && params[:user].present?
          with(:team_ids, team_ids) if team_ids.any?
        end
      end

      def between_date_range(clazz, start_date, end_date)
        start_at_field =
          if clazz.respond_to?(:search_start_date_field)
            clazz.search_start_date_field
          elsif field?(:start_at)
            :start_at
          else
            :start_date
          end
        end_at_field =
          if clazz.respond_to?(:search_end_date_field)
            clazz.search_end_date_field
          elsif field?(:start_at)
            :end_at
          else
            :end_date
          end

        if start_date.present? && end_date.present?
          d1 = Timeliness.parse(start_date, zone: :current).beginning_of_day
          d2 = Timeliness.parse(end_date, zone: :current).end_of_day
          any_of do
            with start_at_field, d1..d2
            with end_at_field, d1..d2
          end
        elsif start_date.present?
          d = Timeliness.parse(start_date, zone: :current)
          all_of do
            with(start_at_field).less_than(d.end_of_day)
            with(end_at_field).greater_than(d.beginning_of_day)
          end
        end
      end

      # Used for searching events by status
      def with_event_status(statuses)
        event_status = statuses.dup
        late = event_status.delete('Late')
        due = event_status.delete('Due')
        executed = event_status.delete('Executed')
        scheduled = event_status.delete('Scheduled')

        current_company = Company.current || Company.new
        end_at_field = current_company.timezone_support? ? :local_end_at : :end_at

        any_of do
          with :status, event_status unless event_status.empty?
          unless late.nil?
            all_of do
              with(:status, 'Unsent')
              with(end_at_field).less_than(current_company.late_event_end_date)
            end
          end

          unless due.nil?
            all_of do
              with(:status, 'Unsent')
              with(end_at_field, current_company.due_event_start_date..current_company.due_event_end_date)
            end
          end

          with(end_at_field).less_than(Time.zone.now) unless executed.nil?

          with(end_at_field).greater_than(Time.zone.now.beginning_of_day) unless scheduled.nil?
        end
      end

      def restrict_search_to_user_permissions(permission_class, permission, company_user)
        return if company_user.role.is_admin?
        if company_user.role.permission_for(permission, permission_class).mode == 'campaigns'
          with_campaign company_user.accessible_campaign_ids + [0]
        elsif company_user.role.permission_for(permission, permission_class).mode == 'none'
          with_campaign [0]
        end
        within_user_locations(company_user)
      end

      def within_user_locations(company_user)
        any_of do
          with(:place_id, company_user.accessible_places + [0])
          with(:location, company_user.accessible_locations + [0])
        end
      end

      protected

      def field?(name)
        @field_names ||= @setup.fields.map(&:name)
        @field_names.include?(name)
      end
    end
  end
end