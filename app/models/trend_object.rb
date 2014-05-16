require 'sunspot/trend_object_adapter'

class TrendObject

  include ActiveModel::Validations
  include ActiveModel::Conversion
  include Sunspot::TrendObjectAdapter
  extend ActiveModel::Naming

  searchable do
    string :id

    integer :company_id
    integer :campaign_id

    time :start_at, stored: true, trie: true
    time :end_at, stored: true, trie: true

    string :description, as: :terms_suggestions

    string :source
  end

  def initialize(resource)
    @id = TrendObject.object_to_id(resource)
    @resource = resource
  end

  def id
    @id
  end

  def resource
    @resource
  end

  def description
    if @resource.is_a?(Comment)
      @resource.content
    else
      @resource.all_values_for_trending.join(" ")
    end
  end

  def source
    if @resource.is_a?(Activity)
      "ActivityType:#{@resource.activity_type_id}"
    else
      @resource.class.name
    end
  end

  def company_id
    @resource.company_id
  end

  def campaign_id
    @resource.campaign_id
  end

  def start_at
    if @resource.is_a?(Comment)
      @resource.commentable.start_at
    else
      @resource.activity_date.beginning_of_day
    end
  end

  def end_at
    if @resource.is_a?(Comment)
      @resource.commentable.end_at
    else
      @resource.activity_date.end_of_day
    end
  end

  def persisted?
    false
  end

  def self.inspect
    "#<#{self.to_s} id: #{ @id }, object: #{ @resource.inspect }>"
  end

  def self.logger
    Rails.logger
  end

  def self.load_objects(ids)
    ids_by_class = {}
    clasess = {}
    ids.each do|id|
      clazz_name, object_id = id.split(':')
      ids_by_class[clazz_name] ||= []
      ids_by_class[clazz_name].push object_id
    end

    ids_by_class.map do |clazz_name, ids|
      clazz_name.camelize.constantize.where(id: ids)
    end.flatten.map{|o| TrendObject.new(o) }
  end

  def self.object_to_id(resource)
    resource.class.name.underscore + ':' + resource.id.to_s
  end

  def self.do_search(params, include_facets=false, &block)
    ss = solr_search do
      with :company_id, params[:company_id]

      with :source, params[:source] unless params[:source].nil?

      if params[:start_date].present? and params[:end_date].present?
        d1 = Timeliness.parse(params[:start_date], zone: :current).beginning_of_day
        d2 = Timeliness.parse(params[:end_date], zone: :current).end_of_day
        any_of do
          with :start_at, d1..d2
          with :end_at, d1..d2
        end
      elsif params[:start_date].present?
        d = Timeliness.parse(params[:start_date], zone: :current)
        all_of do
          with(:start_at).less_than(d.end_of_day)
          with(:end_at).greater_than(d.beginning_of_day)
        end
      end

      facet :description, sort: :count, limit: 30
    end
  end

  def self.solr_index(opts={})
    options = {
      :batch_size => Sunspot.config.indexing.default_batch_size,
      :batch_commit => true,
      :start => opts.delete(:first_id)
    }.merge(opts)

    if options[:batch_size].to_i > 0

      # Index events comments
      batch_counter = 0
      Comment.for_trends.find_in_batches(options.slice(:batch_size, :start)) do |records|
        solr_benchmark(options[:batch_size], batch_counter += 1) do
          Sunspot.index(records.map{|comment| TrendObject.new(comment) }.select { |model| model.indexable? })
          Sunspot.commit if options[:batch_commit]
        end
        options[:progress_bar].increment!(records.length) if options[:progress_bar]
      end

      # Index activities with text answers
      batch_counter = 0
      activity_types = ActivityType.active.with_trending_fields.each do |activity_type|
        Activity.active.where(activity_type_id: activity_type.id).with_results_for(activity_type.trending_fields).find_in_batches(options.slice(:batch_size, :start)) do |records|
          solr_benchmark(options[:batch_size], batch_counter += 1) do
            Sunspot.index(records.map{|activity| TrendObject.new(activity) }.select { |model| model.indexable? })
            Sunspot.commit if options[:batch_commit]
          end
          options[:progress_bar].increment!(records.length) if options[:progress_bar]
        end
      end
    else
      Sunspot.index! Comment.for_trends.select(&:indexable?)
    end

    # perform a final commit if not committing in batches
    Sunspot.commit unless options[:batch_commit]
  end

  def self.count
    Comment.for_trends.count +
    Activity.active.with_results_for(FormField.where(type: ActivityType::TRENDING_FIELDS_TYPES).joins('INNER JOIN activity_types ON activity_types.id=fieldable_id and fieldable_type=\'ActivityType\'').group('form_fields.id').pluck('form_fields.id')).count
  end
end