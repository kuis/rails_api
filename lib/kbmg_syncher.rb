class KbmgSyncher
  attr_reader :campaign

  class << self
    # Search for events on all campaigns that have the attendance
    # module enabled and fetch try to match each event from KBMG
    # with a event in our application, if a event is found then
    # the RSVPs are synched.
    def synch
      Campaign.with_module('attendance').each do |campaign|
        new(campaign).process
      end
    end
  end

  def initialize(campaign)
    @campaign = campaign
    @api_key = campaign.module_setting('attendance', 'api_key')
  end

  def client
    return unless @api_key
    @client ||= KBMG.new(@api_key)
  end

  def process
    unless valid_campaign_api_key?
      logger.info "Campaign #{campaign.name} has an invalid KBMG API KEY"
      return
    end
    page = total_pages = 0
    logger.debug "synching #{campaign.name}"
    begin
      logger.debug "fetching results for page #{page}"
      response = client.events(page: page, limit: 1000)
      if response['Success']
        total_pages = (response['Total'] / 1000).to_i + 1
        logger.debug "obtained #{response['Total']} for #{total_pages} pages"
        response['Data']['Events'].each do |kbmg_event|
          kbmg_place = client.place(kbmg_event['RelatedPlace']['PlaceId'])
          unless kbmg_place
            logger.info "Couldn't fetch place #{kbmg_event['RelatedPlace']['PlaceId']}"
            next
          end
          events = search_events_in_campaign(campaign, kbmg_event, kbmg_place)
          next unless events.count == 1
          event = events.first
          event.update_column(:kbmg_event_id, kbmg_event['EventId'])
          synch_event_individuals event, kbmg_event, kbmg_place
        end
        page += 1
      else
        log_api_error response
      end
    end while page < total_pages && response['Success']
  end

  # Synch the RSVPs for a single event. As a requirement, the event's
  # kbmg_event_id attribute should be set to a valid KBMG's Event ID
  def synch_event_individuals(event, kbmg_event, kbmg_place)
    registrations = client.event_registrations(event.kbmg_event_id)
    logger.info 'Failed to fetch event registrations' unless registrations && registrations['Success']
    return unless registrations && registrations['Success']

    store_event_registrations event, kbmg_place, registrations['Data']['Registrations']
  end

  def store_event_registrations(event, kbmg_event_place, registrations)
    registrations.each do |registration|
      person = client.person(registration['PersonId'])
      next unless person
      place = find_place_by_zip_code(person['AccountName'], kbmg_event_place['PostalCode'])
      place ||= find_place_by_city(person['AccountName'], kbmg_event_place['City'])
      place ||= find_place_by_state(person['AccountName'], kbmg_event_place['ProvinceName'])
      invite =
        if place.present?
          venue = ::Venue.find_or_create_by(place: place, company: campaign.company)
          event.invites.find_or_initialize_by(venue: venue)
        else
          event.invites.new
        end
      next unless invite.save(validate: false)
      individual = invite.individuals.find_or_initialize_by(email: person['Email'])
      update_individual_attributes individual, registration, person
    end
  end

  def update_individual_attributes(individual, registration, person)
    return if individual.updated_by_id.present? # Do not update if it was modified by a user
    individual.assign_attributes(
      first_name: person['FirstName'],
      last_name: person['LastName'],
      email: person['Email'],
      age: person['Age'],
      address_line_1: person['AddressLine1'],
      address_line_2: person['AddressLine2'],
      province_code: person['ProvinceCode'],
      country_code: person['CountryCode'],
      zip_code: person['PostalCode'],
      date_of_birth: person['DateOfBirth'],
      date_added: person['CreatedDate'],
      attended: registration['Attended'],
      rsvpd: registration['Rsvp'],
      mobile_phone: registration['MobilePhone'],
      phone_number: registration['PhoneNumber'],
      opt_in_to_future_communication: person['IsOptedOut']
    )
    individual.save(validate: false)
  end

  def place_match(kbmg_place)
    matches = Place.kbmg_matches(kbmg_place)
    if matches.any? && matches.first[0].to_i >= 5 # Use only matches with confidence of 5 or better
      Place.find(matches.first[2])
    else
      create_place(kbmg_place)
    end
  end

  # Creates a new place with the data returned from KBMG API
  def create_place(kbmg_place)
    street_parts = kbmg_place['AddressLine1'].match(/\A(?:([0-9]+)\s)?(.*)/)
    Place.create name: kbmg_place['Name'],
                 zipcode: kbmg_place['PostalCode'],
                 street_number: street_parts[1],
                 route: street_parts[2],
                 country: kbmg_place['CountryCode'],
                 state: kbmg_place['ProvinceName'],
                 city: kbmg_place['City'],
                 types: %w(establishment),
                 is_custom_place: true,
                 formatted_address: [kbmg_place['AddressLine1'],
                                     kbmg_place['City'],
                                     kbmg_place['ProvinceCode'],
                                     kbmg_place['CountryName']].compact.join(', ')
  end

  def find_place_by_zip_code(name, zip_code)
    return if zip_code.blank?
    Place.where('similarity(normalize_place_name(places.name), normalize_place_name(?)) >= 0.6', name)
      .where(zipcode: zip_code).take
  end

  def find_place_by_city(name, city)
    return if city.blank?
    Place.where('similarity(normalize_place_name(places.name), normalize_place_name(?)) >= 0.6', name)
      .where('lower(places.city) = ?', city.downcase).take
  end

  def find_place_by_state(name, state)
    return if state.blank?
    Place.where('similarity(normalize_place_name(places.name), normalize_place_name(?)) >= 0.6', name)
      .where('lower(places.state) = ?', state.downcase).take
  end

  # Search for a campaign event by looking for the start date. Returns
  # an Active Record collection with all events found
  def search_events_in_campaign(campaign, kbmg_event, kbmg_place)
    date = Timeliness.parse(kbmg_event['StartDate'], format: 'yyyy-mm-ddThh:nn:ss', zone: :utc)
    campaign.events.joins(:place).where(local_start_at: date.beginning_of_day..date.end_of_day, places: { city: kbmg_place['City']})
  end

  def valid_campaign_api_key?
    client && test_api_call
  end

  # Tests the API key by performing a test call and checking for the error code
  def test_api_call
    return false unless client
    result = client.events(limit: 1)
    result['Success'] != false || result['Error']['ErrorCode'] != 'API01'
  end

  def logger
    Rails.logger
  end

  def log_api_error(response)
    logger.info "Failed to fetch the results with error: #{response['Error']['ErrorCode']} #{response['Error']['ErrorMessage']}. #{response['Error']['ExceptionMessage']}"
  end

end
