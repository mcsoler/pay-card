# frozen_string_literal: true

port        ENV.fetch('PORT', 4567)
environment ENV.fetch('RACK_ENV', 'development')
workers     ENV.fetch('WEB_CONCURRENCY', 2).to_i
threads     ENV.fetch('RAILS_MAX_THREADS', 5).to_i, ENV.fetch('RAILS_MAX_THREADS', 5).to_i

preload_app!

on_worker_boot do
  require_relative '../app/infrastructure/database/connection'
end
