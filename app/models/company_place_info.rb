# This is a dummy class used only to index places data per company
class CompanyPlaceInfo < ActiveRecord::Base
  def self.columns() @columns ||= []; end

  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  PLACE_TYPES_SYMS = {
    'bar' => ['bar', 'bars'],
    'night_club' => ['night club', 'night clubs'],
    'restaurant' => ['restaurant', 'restaurants', 'rests'],
    'food' => ['food'],
  }

  attr_accessible :id
  attr_accessor :events, :promo_hours, :impressions, :interactions, :samples, :spent

  delegate :name, :types, :formatted_address, :reference, :latitude, :longitude, to: :place

  column :id, :string
  column :place_id, :integer
  column :company_id, :integer

  belongs_to :place
  belongs_to :company

  searchable do
    integer :place_id
    integer :company_id

    text :name
    text :types do
      begin
        types = place.types
        types.map do |type|
          if PLACE_TYPES_SYMS.has_key?(type)
            PLACE_TYPES_SYMS[type]
          else
            [type]
          end
        end.flatten.join ' '
      rescue
        ''
      end
    end

    string :types, multiple: true

    latlon(:location) { Sunspot::Util::Coordinates.new(latitude, longitude) }

    integer :events, :stored => true  do
      Event.where(company_id: company_id, place_id: place_id).count
    end
    double :promo_hours, :stored => true do
      Event.total_promo_hours_for_places(place_id)
    end
    double :impressions, :stored => true do
      EventResult.impressions_for_places(place_id)
    end
    double :interactions, :stored => true do
      EventResult.consumers_interactions_for_places(place_id)
    end
    double :samples, :stored => true do
      EventResult.consumers_sampled_for_places(place_id)
    end
    double :spent, :stored => true do
      EventResult.spent_for_places(place_id)
    end
  end

  after_initialize :split_id
  def split_id
    (self.place_id, self.company_id) = self.id.split('-')
  end

  def self.load(id)
    self.new(id: id)
  end

  def self.count
    Place.select('count(DISTINCT(places.id, company_id)) as places_count').joins(:events).first.places_count.to_i
  end

  def self.load_all()
    place_scope.map{|p| self.new(id: "#{p.id}-#{p.company_id}")}
  end


  def self.all(options)
    places_ids = Hash[options[:conditions]['id'].map{|id| id.split('-') }]
    Place.all(conditions: {id: places_ids.keys}).map{|p|
      pi = self.new({id: "#{p.id}-#{places_ids[p.id.to_s]}"})
      pi.place = p
      pi.company_id = places_ids[p.id.to_s]
      pi.place_id = p.id
      pi
    }
  end

  def self.find_in_batches(options = {})
    place_scope.find_in_batches(options) do |group|
      yield group.map{|p| self.new(id: "#{p.id}-#{p.company_id}")}
    end
  end

  def self.do_search(params, include_facets=false)
    ss = solr_search do

      with(:company_id, params[:company_id]) if params.has_key?(:company_id) and params[:company_id].present?

      if params[:location].present?
        (lat, lng) = params[:location].split(',')
        with(:location).in_radius(lat, lng, 50)
      end

      if params[:q].present?
        fulltext params[:q] do
          fields(:name)
          fields(:types)
        end
      end

      [:events, :promo_hours, :impressions, :interactions, :samples, :spent].each do |param|
        if params[param].present? && params[param][:min].present? && params[param][:max].present?
          with(param.to_sym, params[param][:min].to_i..params[param][:max].to_i)
        end
      end

      stat(:events, :type => "max")
      stat(:promo_hours, :type => "max")
      stat(:impressions, :type => "max")
      stat(:interactions, :type => "max")
      stat(:samples, :type => "max")
      stat(:spent, :type => "max")

      paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
    end
  end

  private
    def self.place_scope
      Place.select('DISTINCT events.company_id, places.id').joins(:events)
    end

end