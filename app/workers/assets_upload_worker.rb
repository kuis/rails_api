class AssetsUploadWorker
  include Resque::Plugins::UniqueJob
  @queue = :upload

  extend HerokuResqueAutoScale

  def self.perform(asset_id, asset_class = 'AttachedAsset')
    NewRelic::Agent.ignore_apdex
    NewRelic::Agent.ignore_enduser
    klass ||= asset_class.constantize
    tries ||= 3
    asset = klass.find(asset_id)
    asset.transfer_and_cleanup
    asset = nil
    GC.start

  rescue Resque::TermException, Resque::DirtyExit
    # if the worker gets killed, (when deploying for example)
    # re-enqueue the job so it will be processed when worker is restarted
    self.queued!

  # AWS connections sometimes fail, so let's retry it a few times before raising the error
  rescue Errno::ECONNRESET, Net::ReadTimeout, Net::OpenTimeout => e
    tries -= 1
    if tries > 0
      sleep(3)
      retry
    else
      asset.failed! if asset
      raise e
    end
  end
end
