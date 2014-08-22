require "resque/tasks"


# this task will get called before resque:pool:setup
# and preload the rails environment in the pool manager
task "resque:setup" => :environment do
  require "sunspot/queue/resque"
  Resque.before_fork = Proc.new { ActiveRecord::Base.connection.disconnect! }
  Resque.after_fork = Proc.new { ActiveRecord::Base.establish_connection }
end