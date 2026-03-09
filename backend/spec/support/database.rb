# frozen_string_literal: true

require 'sequel'

DB = Sequel.connect(
  adapter:  'postgres',
  host:     ENV.fetch('DB_HOST', 'localhost'),
  port:     ENV.fetch('DB_PORT', 5432).to_i,
  database: ENV.fetch('DB_NAME', 'pay_test'),
  user:     ENV.fetch('DB_USER', 'postgres'),
  password: ENV.fetch('DB_PASSWORD', 'postgres')
)

DatabaseCleaner[:sequel, { db: DB }]
