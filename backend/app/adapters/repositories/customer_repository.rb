# frozen_string_literal: true

require_relative '../../domain/ports/customer_repository'
require_relative '../../domain/entities/customer'

module Adapters
  module Repositories
    class CustomerRepository
      include Domain::Ports::CustomerRepository

      def initialize(db:)
        @db = db
      end

      def find_by_id(id)
        row = @db[:customers].where(id: id).first
        row ? to_entity(row) : nil
      end

      def find_by_email(email)
        row = @db[:customers].where(email: email.to_s.downcase).first
        row ? to_entity(row) : nil
      end

      def create(attributes)
        now = Time.now
        id  = @db[:customers].insert(
          name:       attributes[:name],
          email:      attributes[:email].to_s.downcase,
          address:    attributes[:address],
          phone:      attributes[:phone],
          created_at: now,
          updated_at: now
        )
        find_by_id(id)
      end

      private

      def to_entity(row)
        Domain::Entities::Customer.new(
          id:      row[:id],
          name:    row[:name],
          email:   row[:email],
          address: row[:address],
          phone:   row[:phone]
        )
      end
    end
  end
end
