# frozen_string_literal: true

require_relative 'connection'
require 'sequel/extensions/migration'

migrations_path = File.join(__dir__, 'migrations')

Sequel::Migrator.run(DB, migrations_path)
puts 'Migrations complete.'
