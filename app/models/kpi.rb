# == Schema Information
#
# Table name: kpis
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  description       :text
#  kpi_type          :string(255)
#  capture_mechanism :string(255)
#  company_id        :integer
#  created_by_id     :integer
#  updated_by_id     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  module            :string(255)      default("custom"), not null
#  ordering          :integer
#

class Kpi < ActiveRecord::Base
  track_who_does_it

  scoped_to_company

  CUSTOM_TYPE_OPTIONS = {"number"     => ["integer", "decimal", "currency"],
                         "count"      => ["radio", "dropdown", "checkbox"],
                         "percentage" => ["integer", "decimal"]}

  OUT_BOX_TYPE_OPTIONS = ['promo_hours', 'events_count', 'photos', 'videos', 'surveys', 'expenses', 'comments']

  GOAL_ONLY_TYPE_OPTIONS = OUT_BOX_TYPE_OPTIONS + ['number']

  COMPLETE_TYPE_OPTIONS = CUSTOM_TYPE_OPTIONS.keys + OUT_BOX_TYPE_OPTIONS

  attr_accessible :name, :description, :kpi_type, :capture_mechanism, :kpis_segments_attributes, :goals_attributes

  validates :name, presence: true, uniqueness: {scope: :company_id}
  validates :company_id, numericality: true, allow_nil: true
  validates :kpi_type, :inclusion => {:in => COMPLETE_TYPE_OPTIONS, :message => "%{value} is not valid"}

  validates_associated :kpis_segments

  validate :segments_can_be_deleted?

  # KPIs-Segments relationship
  has_many :kpis_segments, dependent: :destroy, order: 'ordering ASC, id ASC'

  # KPIs-Goals relationship
  has_many :goals

  accepts_nested_attributes_for :kpis_segments, reject_if: lambda { |x| x[:text].blank? && x[:id].blank? }, allow_destroy: true
  accepts_nested_attributes_for :goals

  scope :global, lambda{ where('company_id is null').order('ordering ASC') }
  scope :custom, lambda{|company| scoped_by_company_id(company).order('name ASC') }
  scope :global_and_custom, lambda{|company| where('company_id is null or company_id=?', company).order('company_id DESC, id ASC') }
  scope :in_module, lambda{ where('module is not null and module != \'\'') }
  scope :not_segmented, lambda{ where(['kpi_type not in (?) ', ['percentage', 'count'] ]) }

  after_save :sync_segments_and_goals

  searchable do
    text :name, stored: true
    string :name
    integer :company_id
  end

  def out_of_the_box?
    self.module != 'custom'
  end

  def is_segmented?
    ['percentage'].include? kpi_type
  end

  def currency?
    capture_mechanism == 'currency'
  end

  def sync_segments_and_goals
    unless self.out_of_the_box?
      if GOAL_ONLY_TYPE_OPTIONS.include?(self.kpi_type)
        self.kpis_segments.destroy_all
      else
        self.goals.where(kpis_segment_id: nil).delete_all
      end
    end
  end

  class << self
    def events
      @events ||= where(company_id: nil).find_by_name_and_kpi_type('Events', 'events_count')
    end

    def promo_hours
      @promo_hours ||= where(company_id: nil).find_by_name_and_kpi_type('Promo Hours', 'promo_hours')
    end

    def impressions
      @impressions ||= where(company_id: nil).find_by_name_and_module('Impressions', 'consumer_reach')
    end

    def interactions
      @interactions ||= where(company_id: nil).find_by_name_and_module('Interactions', 'consumer_reach')
    end

    def samples
      @samples ||= where(company_id: nil).find_by_name_and_module('Samples', 'consumer_reach')
    end

    def expenses
      @expenses ||= where(company_id: nil).find_by_name_and_module('Expenses', 'expenses')
    end

    def gender
      @gender ||= where(company_id: nil).find_by_name_and_module('Gender', 'demographics')
    end

    def age
      @age ||= where(company_id: nil).find_by_name_and_module('Age', 'demographics')
    end

    def ethnicity
      @ethnicity ||= where(company_id: nil).find_by_name_and_module('Ethnicity/Race', 'demographics')
    end

    def photos
      @photos ||= where(company_id: nil).find_by_name_and_module('Photos', 'photos')
    end

    def videos
      @videos ||= where(company_id: nil).find_by_name_and_module('Videos', 'videos')
    end

    def surveys
      @surveys ||= where(company_id: nil).find_by_name_and_module('Surveys', 'surveys')
    end

    def comments
      @comments ||= where(company_id: nil).find_by_name_and_module('Comments', 'comments')
    end

    # This method is only used during the DB seed and tests
    def create_global_kpis
      Kpi.global.destroy_all
      without_company_scoped do
        @events = Kpi.create({name: 'Events', kpi_type: 'events_count', description: 'Number of events executed', capture_mechanism: '', company_id: nil, 'module' => '', ordering: 1}, without_protection: true)
        @promo_hours = Kpi.create({name: 'Promo Hours', kpi_type: 'promo_hours', description: 'Total duration of events', capture_mechanism: '', company_id: nil, 'module' => '', ordering: 2}, without_protection: true)
        @impressions = Kpi.create({name: 'Impressions', kpi_type: 'number', description: 'Total number of consumers who come in contact with an event', capture_mechanism: 'integer', company_id: nil, 'module' => 'consumer_reach', ordering: 3}, without_protection: true)
        @interactions = Kpi.create({name: 'Interactions', kpi_type: 'number', description: 'Total number of consumers who directly interact with an event', capture_mechanism: 'integer', company_id: nil, 'module' => 'consumer_reach', ordering: 4}, without_protection: true)
        @samples = Kpi.create({name: 'Samples', kpi_type: 'number', description: 'Number of consumers who try a product sample', capture_mechanism: 'integer', company_id: nil, 'module' => 'consumer_reach', ordering: 5}, without_protection: true)
        @gender  = Kpi.create({name: 'Gender', kpi_type: 'percentage', description: 'Number of consumers who try a product sample', capture_mechanism: 'integer', company_id: nil, 'module' => 'demographics', ordering: 6}, without_protection: true)
        @age     = Kpi.create({name: 'Age', kpi_type: 'percentage', description: 'Percentage of attendees who are within a certain age range', capture_mechanism: 'integer', company_id: nil, 'module' => 'demographics', ordering: 7}, without_protection: true)
        @ethnicity = Kpi.create({name: 'Ethnicity/Race', kpi_type: 'percentage', description: 'Percentage of attendees who are of a certain ethnicity or race', capture_mechanism: 'integer', company_id: nil, 'module' => 'demographics', ordering: 8}, without_protection: true)
        @photos = Kpi.create({name: 'Photos', kpi_type: 'photos', description: 'Total number of photos uploaded to an event', capture_mechanism: '', company_id: nil, 'module' => 'photos', ordering: 9}, without_protection: true)
        @expenses = Kpi.create({name: 'Expenses', kpi_type: 'expenses', description: 'Total expenses of an event', capture_mechanism: 'currency', company_id: nil, 'module' => 'expenses', ordering: 10}, without_protection: true)
        @videos = Kpi.create({name: 'Videos', kpi_type: 'videos', description: 'Total number of photos uploaded to an event', capture_mechanism: '', company_id: nil, 'module' => 'videos', ordering: 11}, without_protection: true)
        @surveys = Kpi.create({name: 'Surveys', kpi_type: 'surveys', description: 'Total number of surveys completed for a campaign', capture_mechanism: 'integer', company_id: nil, 'module' => 'surveys', ordering: 12}, without_protection: true)
        @comments = Kpi.create({name: 'Comments', kpi_type: 'comments', description: 'Total number of comments from event audience', capture_mechanism: 'integer', company_id: nil, 'module' => 'comments', ordering: 13}, without_protection: true)
        Kpi.create({name: 'Competitive Analysis', kpi_type: 'number', description: 'Total number of competitive analyses created for a campaign', capture_mechanism: 'integer', company_id: nil, 'module' => 'competitive_analysis', ordering: 14}, without_protection: true)
      end

      ['< 12', '12 – 17', '18 – 24', '25 – 34', '35 – 44', '45 – 54', '55 – 64', '65+'].each do |segment|
        @age.kpis_segments.create(text: segment)
      end

      ['Female', 'Male'].each do |segment|
        @gender.kpis_segments.create(text: segment)
      end

      ['Asian', 'Black / African American', 'Hispanic / Latino', 'Native American', 'White'].each do |segment|
        @ethnicity.kpis_segments.create(text: segment)
      end
    end

    def merge_fields(options)
      kpis = all
      campaings = CampaignFormField.includes(:campaign).where(kpi_id: kpis).map(&:campaign)
      Kpi.transaction do
        campaings.each do |campaign|
          kpis_to_remove = campaign.active_kpis.select{|k| kpis.include?(k) }
          kpi_keep = kpis.detect{|k| k.id == options[:master_kpi][campaign.id.to_s].to_i }
          kpis_to_remove.reject!{|k| k.id == kpi_keep.id }

          if kpi_keep


            # If this campaing has at leas more than one
            if kpis_to_remove.count > 0
              campaign.events.find_in_batches do |group|
                group.each do |event|
                  event.campaign = campaign # To avoid each event to reload the campaign
                  if kpi_keep.kpi_type == 'percentage'
                    results = event.result_for_kpi(kpi_keep)
                    if results.map(&:value).map(&:to_i).sum == 0
                      values_to_copy = kpis_to_remove.each do|k|
                        values_to_copy = event.result_for_kpi(k)
                        if values_to_copy.map(&:value).map(&:to_i) != 0
                          values_to_copy.each do |result_copy|
                            if result = results.detect{|r| r.kpis_segment.text.downcase.strip == result_copy.kpis_segment.text.downcase.strip}
                              result.value = result_copy.value
                              result.save
                            end
                          end
                        end
                      end
                    end
                  else
                    result = event.result_for_kpi(kpi_keep)
                    value = result.value

                    # If the event doesn't have a value for that field, then try looking for a value on another KPI
                    if value.nil? || !value.present?
                      value ||= kpis_to_remove.map{|k| r = event.result_for_kpi(k); r.value }.compact.first
                      if kpi_keep.kpi_type == 'count'
                        option_text = KpisSegment.find(value).text.downcase.strip rescue nil
                        value = kpi_keep.kpis_segments.detect{|s| s.text.downcase.strip == option_text}.try(:id) if option_text
                      end
                    end

                    result.value = value

                    result.save
                  end
                end
              end
            end
            CampaignFormField.where(kpi_id: kpis_to_remove).destroy_all
            EventResult.where(kpi_id: kpis_to_remove).destroy_all
            kpis_to_remove.each{|k| k.destroy }
          end
        end
      end

      remaining_kpis = all
      if remaining_kpis.count > 0
        kpi_keep = remaining_kpis.shift
        kpi_keep.name = options[:name]
        kpi_keep.description = options[:description]
        kpi_keep.save

        CampaignFormField.where(kpi_id: kpi_keep).update_all(name: options[:name])
        CampaignFormField.where(kpi_id: remaining_kpis).update_all(kpi_id: kpi_keep)
        EventResult.where(kpi_id: remaining_kpis).update_all(kpi_id: kpi_keep)
        remaining_kpis.each{|k| k.destroy }
      end
    end
  end


  def segments_can_be_deleted?
    kpis_segments.select{|s| s.marked_for_destruction? }.each do |segment|
      errors.add :base, 'cannot delete segments with results' if segment.has_results?
    end
  end

end
