workers 1
threads 1, 3

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 8080
environment ENV['RAILS_ENV'] || 'production'

daemonize true
pidfile 'tmp/puma.pid'
state_path 'tmp/puma.state'
stdout_redirect 'log/puma.stdout', 'log/puma.stderr', true
quiet

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end
