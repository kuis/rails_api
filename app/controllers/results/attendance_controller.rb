class Results::AttendanceController < ApplicationController
  helper_method :return_path, :neighborhood_coordinates, :default_color

  before_action :load_neighborhoods, only: [:map]

  def index
    @states = Country.new('US').states.map { |code, data| ["#{code} (#{data['name']})", code] }
  end

  def map
  end

  protected

  def return_path
    results_reports_path
  end

  def default_color
    color = current_company.campaigns.find(params[:campaign]).color unless params[:campaign].blank?
    color ||= params[:color] unless params[:color].blank?
    color ||= '#347B9B'
  end

  def load_neighborhoods
    @neighborhoods =
      Neighborhood.where(state: params[:state], city: params[:city])
      .joins('LEFT JOIN places ON ST_Intersects(places.lonlat, neighborhoods.geog)')
      .joins('LEFT JOIN venues ON venues.place_id=places.id')
      .joins('LEFT JOIN (SELECT * FROM invites INNER JOIN events ON invites.event_id=events.id AND events.campaign_id=' + params[:campaign].to_i.to_s + ') invites ON invites.venue_id=venues.id')
      .joins('LEFT JOIN events ON invites.event_id=events.id AND events.campaign_id=' + params[:campaign].to_i.to_s)
      .group('neighborhoods.gid')
      .select('neighborhoods.*, COALESCE(sum(invitees), 0) invitations, COALESCE(sum(attendees), 0) attendees,'\
              '0 attended, sum(rsvps_count) rsvps').to_a
  end

  def neighborhood_coordinates(neighborhood)
    return '' if neighborhood.nil? || neighborhood.geog.nil?
    neighborhood.geog[0].exterior_ring.points.map do |point|
      "new google.maps.LatLng(#{point.lat}, #{point.lon})"
    end.join(',')
  end
end
