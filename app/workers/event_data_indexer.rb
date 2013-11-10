class EventDataIndexer
  include Resque::Plugins::UniqueJob
  @queue = :indexing

  def self.perform(event_data_id)
    EventData.find(event_data_id).update_data.save
  end
end