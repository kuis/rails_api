require 'sunspot/queue/helpers'

class IndexWorker
  extend ::Sunspot::Queue::Helpers
  include Resque::Plugins::UniqueJob
  @queue = :indexing

  def self.perform(klass, id)
    tries ||= 3
    without_proxy do
      constantize(klass).find(id).solr_index
    end

  rescue Resque::TermException, Resque::DirtyExit
    # if the worker gets killed, (when deploying for example)
    # re-enqueue the job so it will be processed when worker is restarted
    Resque.enqueue(IndexWorker, klass, id)

  # Try it again a few times in case of a connection issue before raising the error
  # We are also retrying ActiveRecord::RecordNotFound errors for cases where
  # the job starts before the transaction commits the changes
  rescue Errno::ECONNRESET, Net::ReadTimeout, Net::ReadTimeout,
         Net::OpenTimeout, ActiveRecord::RecordNotFound => e
    tries -= 1
    if tries > 0
      sleep(3)
      retry
    else
      # Do not raise errors when the record is not found since
      # it happens that some records are inmediately removed after created,
      # specially comments
      if e.class == ActiveRecord::RecordNotFound
        Rails.logger.info "#{klass} record with id #{id} not found!"
      else
        raise e
      end
    end
  end
end
