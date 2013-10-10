class Legacy::DataMigration < ActiveRecord::Base
  belongs_to :company

  belongs_to :local, polymorphic: true, autosave: true
  belongs_to :remote, polymorphic: true, autosave: true

  accepts_nested_attributes_for :local

  attr_accessible :local, :company_id

  validates :company_id, presence: true, numericality: true

  validates :remote_id, presence: true, numericality: true
  validates :remote_type, presence: true

  #validates :local_id, presence: true, numericality: true
  validates :local_type, presence: true

  scope :for_metric, lambda{|metric| where(remote_type: 'Metric', remote_id: metric.id)}
end