class InvitesController < InheritedResources::Base
  belongs_to :event, :venue, :area, optional: true

  respond_to :js, only: [:new, :create, :edit, :update]

  actions :new, :create, :edit, :update

  helper_method :parent_activities

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableController

  include ExportableController

  def create
    invite = build_resource
    existing_invite =
      if parent.is_a?(Event)
        if resource.venue.present?
          parent.invites.active.find_by(venue_id: invite.venue_id)
        elsif resource.area.present?
          parent.invites.active.find_by(area_id: invite.area_id)
        end
      else
        parent.invites.active.find_by(event_id: invite.event_id)
      end

    result =
      if existing_invite.present?
        existing_invite.invitees = invite.invitees.to_i + existing_invite.invitees.to_i
        existing_invite.save
      else
        invite.save
      end
  end

  protected

  def collection_to_csv
    for_event = parent.is_a?(Event)
    for_market = parent.is_a?(Event) &&
                 parent.campaign.enabled_modules.include?('attendance') &&
                 Invite::ATTENDANCE_DISPLAY_BY_TYPES.try(:[], parent.campaign.module_setting('attendance', 'attendance_display')) == 'market'
    CSV.generate do |csv|
      name_col = for_market ? ['MARKET'] : ['ACCOUNT', 'JAMESON LOCALS', 'TOP 100']
      cols = for_event ? name_col : ['EVENT DATE', 'CAMPAIGN']
      if export_individual?
        cols.concat ['REGISTRANT ID', 'DATE ADDED', 'EMAIL',
                   'MOBILE PHONE', 'MOBILE SIGN UP', 'FIRST NAME', 'LAST NAME',
                   'ATTENDED PREVIOUS BARTENDER BALL', 'OPT IN TO FUTURE COMMUNICATION',
                   'PRIMARY REGISTRANT ID', 'BARTENDER HOW LONG', 'BARTENDER ROLE',
                   'DATE OF BIRTH', 'ZIP CODE']
      else
        cols.concat ['INVITES', 'RSVPs', 'ATTENDEES']
      end
      csv << cols
      each_collection_item do |item|
        name_val = for_market ? [item.area.try(:name)] : [item.place_name, item.jameson_locals, item.top_venue]
        cols = (for_event ? name_val : [item.event_date, item.campaign_name])
        if export_individual?
          cols.concat individual_data(item)
        else
          cols.concat [item.invitees, item.rsvps_count, item.attendees]
        end
        csv << cols
      end
    end
  end

  def individual_data(rsvp)
    [rsvp.registrant_id, rsvp.date_added, rsvp.email, rsvp.mobile_phone, rsvp.mobile_signup,
     rsvp.first_name, rsvp.last_name, rsvp.attended_previous_bartender_ball,
     rsvp.opt_in_to_future_communication, rsvp.primary_registrant_id, rsvp.bartender_how_long,
     rsvp.bartender_role, rsvp.date_of_birth, rsvp.zip_code]
  end

  def collection
    if export_individual?
      InviteRsvp.where(invite_id: end_of_association_chain.active)
    else
      end_of_association_chain.active
    end
  end

  def export_individual?
     params[:format] == 'csv' && params[:export_mode] == 'individual'
  end

  def invite_params
    params.require(:invite).permit(:place_reference, :venue_id, :event_id, :area_id, :invitees, :attendees, :rsvps_count)
  end
end
