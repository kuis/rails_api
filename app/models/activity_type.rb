# == Schema Information
#
# Table name: activity_types
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  active      :boolean          default(TRUE)
#  company_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class ActivityType < ActiveRecord::Base
  belongs_to :company
  scoped_to_company
  has_many :form_fields, :as => :fieldable, order: 'form_fields.ordering ASC'
  has_many :companies, through: :activity_type_campaigns

  validates :name, presence: true
  validates :company_id, presence: true, numericality: true

  # Campaign relationships
  has_many :activity_type_campaigns
  has_many :campaigns, through: :activity_type_campaigns

  # Goals relationships
  has_one :goal, conditions: { parent_id: nil }, dependent: :destroy

  accepts_nested_attributes_for :goal
  scope :accessible_by_user, lambda {|company_user| company_user.is_admin? ? scoped() : where(id: company_user.accessible_campaign_ids) }
  scope :active, lambda{ where(active: true) }
  attr_accessor :partial_path
  
  searchable do
    integer :id

    text :name, stored: true

    string :name
    string :status

    boolean :active

    integer :company_id
  end


  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def status
    self.active? ? 'Active' : 'Inactive'
  end
  
    
  def to_partial_path
    partial_path
  end
  
  def partial_path
    @partial_path || 'activity_types/activity_type'
  end
  
  def autocomplete
    buckets = autocomplete_buckets({
        activity_types: [ActivityType]
      })
    render :json => buckets.flatten
  end
    
    
  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      ss = solr_search do
        with(:company_id, params[:company_id])
        with(:status, params[:status]) if params.has_key?(:status) and params[:status].present?
        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'activity_type'
            with :id, value
          end
        end

        if include_facets
          facet :status
        end

        order_by(params[:sorting] || :name, params[:sorting_dir] || :desc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
      end
    end
  end
end
