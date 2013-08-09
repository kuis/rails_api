module PlacesHelper
  def place_website(url)
    link_to url.gsub(/https?:\/\//,'').gsub(/\/$/,''), url
  end

  def venue_score_narrative(venue)
    unless venue.score.nil?
      types = venue.types_without_establishment.map{|t| t("venue_types.#{t}").downcase.pluralize }
      "#{venue.name} has earned a Venue Score of #{venue.score} and has performed #{score_calification_for(venue.score)} other #{types.join('/')} in the area.  Specifically, #{venue.name} yields a(n) #{avg_impressions_hour_performance_for(venue)} number of impressions per promo hour.  In addition, the cost per impression is #{avg_impressions_cost_performance_for(venue)} other #{types.join('/')} in the area.

      <p>Attendess at previous events have predominantly been #{predominant(:age, venue)} year old #{predominant(:ethnicity, venue)} #{predominant(:gender, venue)}.".html_safe
    end
  end

  private
    def score_calification_for(score)
      if score > 66
        'well relative to'
      elsif score > 33
        'on par with'
      else
        'poorly relative to'
      end
    end

    def predominant(kpi, venue)
      venue.overall_graphs_data[kpi].max_by{|k,v| v}[0]
    end

    def avg_impressions_cost_performance_for(venue)
      if stats = avg_stats_for_venue(venue)
        if venue.avg_impressions_hour > stats[:avg_impressions_cost]
          'higher than'
        elsif  venue.avg_impressions == stats[:avg_impressions_cost]
          'on par with'
        else
          'lower than'
        end
      end
    end


    def avg_impressions_hour_performance_for(venue)
      if stats = avg_stats_for_venue(venue)
        if venue.avg_impressions_hour > stats[:avg_impressions_hour]
          'above average'
        elsif  venue.avg_impressions == stats[:avg_impressions_hour]
          'average'
        else
          'below average'
        end
      end
    end


    def avg_stats_for_venue(venue)
      @stats ||= {}
      @stats[venue.id] ||= begin
        search = Venue.solr_search do
          with(:company_id, venue.company_id)
          with(:location).in_radius(venue.latitude, venue.longitude, 5)
          with(:types, venue.types_without_establishment )
          with(:avg_impressions).greater_than(0)

          stat(:avg_impressions, :type => "mean")
          stat(:avg_impressions_hour, :type => "mean")
          stat(:avg_impressions_cost, :type => "mean")
        end
        unless search.stat_response['stats_fields']["avg_impressions_es"].nil?
          {
            avg_impressions: search.stat_response['stats_fields']["avg_impressions_es"]['mean'],
            avg_impressions_hour: search.stat_response['stats_fields']["avg_impressions_hour_es"]['mean'],
            avg_impressions_cost: search.stat_response['stats_fields']["avg_impressions_cost_es"]['mean']
          }
        end
      end
    end


end