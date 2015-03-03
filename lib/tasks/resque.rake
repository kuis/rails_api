require 'resque/tasks'

# this task will get called before resque:pool:setup
# and preload the rails environment in the pool manager
task 'resque:setup' => :environment do
  require 'sunspot/queue/resque'
  Resque.before_fork = proc { ActiveRecord::Base.connection.disconnect! }
  Resque.after_fork do
    config = ActiveRecord::Base.configurations[Rails.env] ||
      Rails.application.config.database_configuration[Rails.env]
    config['adapter'] = 'postgis'
    ActiveRecord::Base.establish_connection(config)
  end
end
