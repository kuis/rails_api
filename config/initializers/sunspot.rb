unless defined?($rails_rake_task) && $rails_rake_task && !Rake.application.top_level_tasks.include?('jobs:work')
  require "sunspot/queue/delayed_job"
  backend = Sunspot::Queue::DelayedJob::Backend.new
  Sunspot.session = Sunspot::Queue::SessionProxy.new(Sunspot.session, backend)
end