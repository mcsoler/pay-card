# frozen_string_literal: true

require 'sequel'
require 'logger'

DB = Sequel.connect(
  adapter:  'postgres',
  host:     ENV.fetch('DB_HOST', 'localhost'),
  port:     ENV.fetch('DB_PORT', 5432).to_i,
  database: ENV.fetch('DB_NAME', 'pay_development'),
  user:     ENV.fetch('DB_USER', 'postgres'),
  password: ENV.fetch('DB_PASSWORD', 'postgres'),
  logger:   ENV['RACK_ENV'] == 'development' ? Logger.new($stdout) : nil
)
