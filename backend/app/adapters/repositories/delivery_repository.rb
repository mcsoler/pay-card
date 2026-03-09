# frozen_string_literal: true

require_relative '../../domain/ports/delivery_repository'
require_relative '../../domain/entities/delivery'

module Adapters
  module Repositories
    class DeliveryRepository
      include Domain::Ports::DeliveryRepository

      def initialize(db:)
        @db = db
      end

      def find_by_transaction_id(transaction_id)
        row = @db[:deliveries].where(transaction_id: transaction_id).first
        row ? to_entity(row) : nil
      end

      def create(attributes)
        now = Time.now
        id  = @db[:deliveries].insert(
          transaction_id: attributes[:transaction_id],
          status:         attributes[:status] || 'PENDING',
          address:        attributes[:address],
          estimated_date: attributes[:estimated_date],
          created_at:     now,
          updated_at:     now
        )
        row = @db[:deliveries].where(id: id).first
        to_entity(row)
      end

      private

      def to_entity(row)
        Domain::Entities::Delivery.new(
          id:             row[:id],
          transaction_id: row[:transaction_id],
          status:         row[:status],
          address:        row[:address],
          estimated_date: row[:estimated_date]
        )
      end
    end
  end
end
