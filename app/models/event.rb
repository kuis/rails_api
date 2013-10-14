# == Schema Information
#
# Table name: events
#
#  id            :integer          not null, primary key
#  campaign_id   :integer
#  company_id    :integer
#  start_at      :datetime
#  end_at        :datetime
#  aasm_state    :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  active        :boolean          default(TRUE)
#  place_id      :integer
#  promo_hours   :decimal(6, 2)    default(0.0)
#  reject_reason :text
#  summary       :text
#

class Event < ActiveRecord::Base
  include AASM

  belongs_to :campaign
  belongs_to :place, autosave: true

  has_many :tasks, :order => 'due_at ASC', dependent: :destroy, inverse_of: :event
  has_many :photos, conditions: {asset_type: 'photo'}, class_name: 'AttachedAsset', :as => :attachable, inverse_of: :attachable, order: "created_at DESC"
  has_many :documents, conditions: {asset_type: 'document'}, class_name: 'AttachedAsset', :as => :attachable, inverse_of: :attachable, order: "created_at DESC"
  has_many :teamings, :as => :teamable
  has_many :teams, :through => :teamings, :after_remove => :after_remove_member
  has_many :results, class_name: 'EventResult'
  has_many :event_expenses, inverse_of: :event, autosave: true
  has_one :event_data, autosave: true

  has_many :comments, :as => :commentable, order: 'comments.created_at ASC'

  has_many :surveys,  inverse_of: :event


  # Events-Users relationship
  has_many :memberships, :as => :memberable
  has_many :users, :class_name => 'CompanyUser', source: :company_user, :through => :memberships, :after_remove => :after_remove_member

  # attr_accessible :end_date, :end_time, :start_date, :start_time, :campaign_id, :event_ids, :user_ids, :file, :summary, :place_reference, :results_attributes, :comments_attributes, :surveys_comments, :photos_attributes

  accepts_nested_attributes_for :surveys
  accepts_nested_attributes_for :results
  accepts_nested_attributes_for :photos
  accepts_nested_attributes_for :comments, reject_if: proc {|attributes| attributes['content'].blank? }

  scoped_to_company

  attr_accessor :place_reference

  scope :upcomming, lambda{ where('start_at >= ?', Time.zone.now) }
  scope :active, lambda{ where(active: true) }
  scope :by_period, lambda{|start_date, end_date| where("start_at >= ? AND start_at <= ?", Timeliness.parse(start_date), Timeliness.parse(end_date.empty? ? start_date : end_date).end_of_day) unless start_date.nil? or start_date.empty? }
  scope :by_campaigns, lambda{|campaigns| where(campaign_id: campaigns) }
  scope :with_user_in_team, lambda{|user|
    joins('LEFT JOIN "teamings" t ON "t"."teamable_id" = "events"."id" AND "t"."teamable_type" = \'Event\' LEFT JOIN "memberships" m ON "m"."memberable_id" = "events"."id" AND "m"."memberable_type" = \'Event\'').
    where('t.team_id in (?) OR m.company_user_id IN (?)', user.teams, user) }
  scope :in_past, lambda{ where('events.end_at < ?', Time.now) }
  scope :with_team, lambda{|team|
    joins(:teamings).
    where(teamings: {team_id: team} ) }

  track_who_does_it

  #validates_attachment_content_type :file, :content_type => ['image/jpeg', 'image/png']
  validates :campaign_id, presence: true, numericality: true
  validates :company_id, presence: true, numericality: true
  validates :start_at, presence: true
  validates :end_at, presence: true

  validates_datetime :start_at
  validates_datetime :end_at, :on_or_after => :start_at, on_or_after_message: 'must be after'

  attr_accessor :start_date, :start_time, :end_date, :end_time

  after_initialize :set_start_end_dates
  before_validation :parse_start_end
  after_validation :delegate_errors

  before_save :set_promo_hours, :check_results_changed
  after_save :reindex_associated

  #after_create :add_team_members

  delegate :name, to: :campaign, prefix: true, allow_nil: true
  delegate :name,:latitude,:city,:state_name,:zipcode,:longitude,:formatted_address,:name_with_location, to: :place, prefix: true, allow_nil: true
  delegate :impressions, :interactions, :samples, :spent, :gender_female, :gender_male, :ethnicity_asian, :ethnicity_black, :ethnicity_hispanic, :ethnicity_native_american, :ethnicity_white, to: :event_data, allow_nil: true

  aasm do
    state :unsent, :initial => true
    state :submitted
    state :approved
    state :rejected

    event :submit do
      transitions :from => [:unsent, :rejected], :to => :submitted, :guard => :valid_results?
    end

    event :approve do
      transitions :from => :submitted, :to => :approved
    end

    event :reject do
      transitions :from => :submitted, :to => :rejected
    end
  end

  searchable do
    boolean :active
    time :start_at, stored: true, trie: true
    time :end_at, stored: true, trie: true
    string :status, multiple: true do
      [status, event_status]
    end
    string :start_time

    integer :id, stored: true
    integer :company_id
    integer :campaign_id, stored: true
    integer :place_id
    integer :user_ids, multiple: true
    integer :team_ids, multiple: true

    string :place do
      Place.location_for_index(place) if place_id
    end

    string :location, multiple: true do
      locations_for_index
    end

    boolean :has_event_data do
      has_event_data?
    end

    boolean :has_comments do
      comments.count > 0
    end

    boolean :has_surveys do
      surveys.count > 0
    end

    double :promo_hours, stored: true
    double :impressions, stored: true
    double :interactions, stored: true
    double :samples, stored: true
    double :spent, stored: true
    double :gender_female, stored: true
    double :gender_male, stored: true
    double :ethnicity_asian, stored: true
    double :ethnicity_black, stored: true
    double :ethnicity_hispanic, stored: true
    double :ethnicity_native_american, stored: true
    double :ethnicity_white, stored: true
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def place_reference=(value)
    @place_reference = value
    if value and value.present?
      reference, place_id = value.split('||')
      self.place = Place.find_or_initialize_by_place_id(place_id, {reference: reference}) if value
    end
  end

  def status
    self.active? ? 'Active' : 'Inactive'
  end

  def event_status
    self.aasm_state.capitalize
  end

  def in_past?
    end_at < Time.now
  end

  def in_future?
    start_at > Time.now
  end

  def is_late?
    end_at.to_date <= (2.days.ago).to_date
  end

  def happens_today?
    start_at.to_date <= Date.today && end_at.to_date >= Date.today
  end

  def was_yesterday?
    end_at.to_date == Date.yesterday
  end

  def has_event_data?
    results.count > 0
  end

  def venue
    @venue ||= Venue.find_or_create_by_company_id_and_place_id(company_id, place_id)
  end

  def user_in_team?(user)
    Event.with_user_in_team(user).where(id: self.id).count > 0
  end

  def all_users
    users = []
    users += self.users if self.users.present?
    teams.each do |team|
      users += team.users if team.users.present?
    end
    users.uniq
  end

  def results_for(fields)
    # The results are mapped by field or kpi_id to make it find them in case the form field was deleted and readded to the form
    fields.map do |field|
      result = results.select{|r| (r.form_field_id == field.id || (field.kpi_id.present? && r.kpi_id == field.kpi_id)) && r.kpis_segment_id.nil? }.first || results.build({form_field_id: field.id, kpi_id: field.kpi_id})
      result.form_field = field
      result
    end
  end

  def segments_results_for(field)
    # The results are mapped by field or kpi_id to make it find them in case the form field was deleted and readded to the form
    if field.kpi.present?
      fs = field.kpi.kpis_segments.map do |segment|
        result = results.select{|r| (r.form_field_id == field.id || (field.kpi_id.present? && r.kpi_id == field.kpi_id)) && r.kpis_segment_id == segment.id }.first || results.build({form_field_id: field.id, kpis_segment_id: segment.id, kpi_id: field.kpi_id})
        result.form_field = field
        result.kpis_segment = segment
        result
      end
      fs
    end
  end

  def result_for_kpi(kpi)
    field = campaign.form_fields.detect{|f| f.kpi_id == kpi.id }
    if field.present?
      if field.is_segmented?
        segments_results_for(field)
      else
        results_for([field]).first
      end
    end
  end

  def results_for_kpis(kpis)
    kpis.map{|kpi| result_for_kpi(kpi) }.flatten.compact
  end

  def locations_for_index
    Place.locations_for_index(place)
  end

  def kpi_goals
    unless @goals
      @goals = {}
      total_campaign_events = campaign.events.count
      if total_campaign_events > 0
        campaign.goals.base.each do |goal|
          if goal.kpis_segment_id.present?
            @goals[goal.kpi_id] ||= {}
            @goals[goal.kpi_id][goal.kpis_segment_id] = goal.value / total_campaign_events unless goal.value.nil?
          else
            @goals[goal.kpi_id] = goal.value / total_campaign_events unless goal.value.nil?
          end
        end
      end
    end
    @goals
  end


  def demographics_graph_data
    unless @demographics_graph_data
      @demographics_graph_data = {}
      [:age, :gender, :ethnicity].each do |kpi|
        scoped_results = results.send(kpi).select('event_results.kpis_segment_id, sum(event_results.scalar_value) AS segment_sum, avg(event_results.scalar_value) AS segment_avg').group('event_results.kpis_segment_id')
        segments = Kpi.send(kpi).kpis_segments
        @demographics_graph_data[kpi] = Hash[segments.map{|s| [s.text, scoped_results.detect{|r| r.kpis_segment_id == s.id}.try(:segment_avg).try(:to_f) || 0]}]
      end
    end
    @demographics_graph_data
  end

  def survey_statistics
    @survey_statistics ||= Hash.new.tap do |stats|
      stats[:total] = 0
      brands_map = Hash[campaign.survey_brands.map{|b| [b.id, b.name] }]
      surveys.each do|survey|
        stats[:total] += 1
        survey.surveys_answers.each do |answer|
          if  answer.brand_id.present? && brands_map.has_key?(answer.brand_id)
            type = "question_#{answer.question_id}"
            stats[type] ||= {}
            if answer.question_id == 2
              if answer.answer.present? && answer.answer =~ /^[0-9]+(\.[0-9])?$/
                stats[type][brands_map[answer.brand_id]] ||= {count: 0, total: 0, avg: 0}
                stats[type][brands_map[answer.brand_id]][:count] += 1
                stats[type][brands_map[answer.brand_id]][:total] += answer.answer.to_f
                stats[type][brands_map[answer.brand_id]][:avg] = stats[type][brands_map[answer.brand_id]][:total] / stats[type][brands_map[answer.brand_id]][:count]
              end
            else
              stats[type][answer.answer] ||= {}
              stats[type][answer.answer][brands_map[answer.brand_id]] ||= {count: 0, avg: 0.0}
              stats[type][answer.answer][brands_map[answer.brand_id]][:count] += 1
              stats[type].each{|a, brands| brands.each{|b, s| s[:avg] = s[:count]*100.0/stats[:total]} }
            end
          elsif answer.kpi_id.present?
            type = "kpi_#{answer.kpi_id}"
            stats[type] ||= {}
            stats[type][answer.answer] ||= {count: 0, avg: 0}
            stats[type][answer.answer][:count] += 1
            stats[type].each{|a, s| s[:avg] = s[:count]*100/stats[:total] }
          end
        end
      end
    end
  end

  def valid_results?
    # Ensure all the results have been assigned/initialized
    results_for(campaign.form_fields) if campaign.present?
    results.all?{|r| r.valid? }
  end


  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false, &block)
      # TODO: probably this options should be passed by params?
      options = {include: [:campaign, :place]}
      ss = solr_search(options) do

        company_user = params[:current_company_user]
        if company_user.present?
          unless company_user.role.is_admin?
            with(:campaign_id, company_user.accessible_campaign_ids + [0])
            any_of do
              locations = company_user.accessible_locations
              places_ids = company_user.accessible_places
              with(:place_id, places_ids + [0])
              with(:location, locations + [0])
            end
          end
        end

        if (params.has_key?(:user) && params[:user].present?) || (params.has_key?(:team) && params[:team].present?)
          team_ids = []
          team_ids += params[:team] if params.has_key?(:team) && params[:team].any?
          team_ids += Team.with_user(params[:user]).map(&:id) if params.has_key?(:user) && params[:user].any?

          any_of do
            with(:user_ids, params[:user]) if params.has_key?(:user) && params[:user].present?
            with(:team_ids, team_ids) if team_ids.any?
          end
        end
        if params.has_key?(:place) and params[:place].present?
          place_paths = []
          params[:place].each do |place|
            # The location comes BASE64 encoded as a pair "id||name"
            # The ID is a md5 encoded string that is indexed on Solr
            (id, name) = Base64.decode64(place).split('||')
            place_paths.push id
          end
          if place_paths.size > 0
            with(:location, place_paths)
          end
        end
        with(:campaign_id, params[:campaign]) if params.has_key?(:campaign) and params[:campaign].present?

        # We are using two options to allow searching by active/inactive in combination with approved/late/rejected/submitted
        with(:status, params[:status]) if params.has_key?(:status) and params[:status].present? # For the active state
        if params.has_key?(:event_status) and params[:event_status].present? # For the event status
          late = params[:event_status].delete('Late')
          due = params[:event_status].delete('Due')

          any_of do
            with(:status, params[:event_status]) unless params[:event_status].empty?
            unless late.nil?
              all_of do
                with(:status, 'Unsent')
                with(:end_at).less_than(2.days.ago)
              end
            end

            unless due.nil?
              all_of do
                with(:status, 'Unsent')
                with(:end_at, Date.yesterday.beginning_of_day..Time.zone.now)
              end
            end
          end
        end
        with(:company_id, params[:company_id])
        with(:has_event_data, true) if params[:with_event_data_only].present?
        with(:has_surveys, true) if params[:with_surveys_only].present?
        with(:has_comments, true) if params[:with_comments_only].present?

        if params.has_key?(:brand) and params[:brand].present?
          with "campaign_id", Campaign.select('DISTINCT(campaigns.id)').joins(:brands).where(brands: {id: params[:brand]}).map(&:id)
        end

        with(:location, Area.where(id: params[:area]).map{|a| Place.encode_location(a.common_denominators) } ) if params[:area].present?

        if params[:start_date].present? and params[:end_date].present?
          d1 = Timeliness.parse(params[:start_date], zone: :current).beginning_of_day
          d2 = Timeliness.parse(params[:end_date], zone: :current).end_of_day
          with :start_at, d1..d2
        elsif params[:start_date].present?
          d = Timeliness.parse(params[:start_date], zone: :current)
          with :start_at, d.beginning_of_day..d.end_of_day
        end
        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'brand'
            campaigns = Campaign.select('campaigns.id').joins(:brands).where(brands: {id: value}).map(&:id)
            campaigns = '-1' if campaigns.empty?
            with "campaign_id", campaigns
          when 'campaign', 'place'
            with "#{attribute}_id", value
          when 'company_user'
            with :user_ids, value
          else
            with "#{attribute}_ids", value
          end
        end

        if params.has_key?(:event_data_stats) && params[:event_data_stats]
          stat(:promo_hours, :type => "sum")
          stat(:impressions, :type => "sum")
          stat(:interactions, :type => "sum")
          stat(:samples, :type => "sum")
          stat(:spent, :type => "sum")
          stat(:gender_female, :type => "mean")
          stat(:gender_male, :type => "mean")
          stat(:gender_male, :type => "mean")
          stat(:ethnicity_asian, :type => "mean")
          stat(:ethnicity_black, :type => "mean")
          stat(:ethnicity_hispanic, :type => "mean")
          stat(:ethnicity_native_american, :type => "mean")
          stat(:ethnicity_white, :type => "mean")
        end

        if include_facets
          facet :campaign_id
          facet :place
          facet :place_id
          facet :user_ids
          facet :team_ids
          facet :status
        end

        order_by(params[:sorting] || :start_at , params[:sorting_dir] || :desc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)

        yield self if block_given?
      end
    end

    def total_promo_hours_for_places(places)
      where(place_id: places).sum(:promo_hours)
    end
  end

  private

    # Copy some errors to the attributes used on the forms so the user
    # can see them
    def delegate_errors
      errors[:start_at].each{|e| errors.add(:start_date, e) }
      errors[:end_at].each{|e| errors.add(:end_date, e) }
      place.errors.full_messages.each{|e| errors.add(:place_reference, e) } if place
    end

    def parse_start_end
      unless self.start_date.nil? or self.start_date.empty?
        parts = self.start_date.split("/")
        self.start_at = Time.zone.parse([[parts[1],parts[0],parts[2]].join('/'), self.start_time].join(' '))
      end
      unless self.end_date.nil? or self.end_date.empty?
        parts = self.end_date.split("/")
        self.end_at = Time.zone.parse([[parts[1],parts[0],parts[2]].join('/'), self.end_time].join(' '))
      end
    end

    # Sets the values for start_date, start_time, end_date and end_time when from start_at and end_at
    def set_start_end_dates
      if new_record?
        self.start_time ||= '12:00 PM'
        self.end_time ||= '01:00 PM'
      else
        if has_attribute?(:start_at) # this if is to allow custom selects on the Event module
          self.start_date = self.start_at.to_s(:slashes)   unless self.start_at.blank?
          self.start_time = self.start_at.to_s(:time_only) unless self.start_at.blank?
          self.end_date   = self.end_at.to_s(:slashes)     unless self.end_at.blank?
          self.end_time   = self.end_at.to_s(:time_only)   unless self.end_at.blank?
        end
      end
    end

    def after_remove_member(member)
      if member.is_a? Team
        users = member.user_ids - self.user_ids
      else
        users = [member]
      end

      self.tasks.scoped_by_company_user_id(users).update_all(company_user_id: nil)
      Sunspot.index(self.tasks)
    end

    def check_results_changed
      @refresh_event_data = false
      if results.any?{|r| r.changed?}
        @refresh_event_data = true
      end
      true
    end

    def reindex_associated
      if campaign.present?
        campaign.first_event = self if campaign.first_event_at.nil? || campaign.first_event_at > self.start_at
        campaign.last_event  = self if campaign.last_event_at.nil?  || campaign.last_event_at  < self.start_at
        campaign.save if campaign.changed?
      end

      if @refresh_event_data
        build_event_data unless event_data.present?
        event_data.update_data
        event_data.save
      end

      if (@refresh_event_data || place_id_changed?) && place_id.present?
        Resque.enqueue(VenueIndexer, venue.id)
      end

      if place_id_changed?
        Resque.enqueue(EventPhotosIndexer, self.id)
        Sunspot.index(place)
        if place_id_was.present?
          previous_venue = Venue.find_by_company_id_and_place_id(company_id, place_id_was)
          Resque.enqueue(VenueIndexer, previous_venue.id) unless previous_venue.nil?
        end
      end

      if active_changed?
        Sunspot.index self.tasks
      end
    end

    def set_promo_hours
      self.promo_hours = (end_at - start_at) / 3600
      true
    end

    # def add_team_members
    #   if campaign.present?
    #     campaign_team = campaign.staff.uniq
    #     if campaign_team.present?
    #       campaign_team.each do |member|
    #         if member.is_a?(CompanyUser)
    #           if member.accessible_places.include?(self.place_id)
    #             self.users << member
    #           end
    #         end
    #       end
    #       Sunspot.index self.users
    #     end
    #   end
    # end
end
