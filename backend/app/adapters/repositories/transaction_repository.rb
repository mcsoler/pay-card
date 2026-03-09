# frozen_string_literal: true

require_relative '../../domain/ports/transaction_repository'
require_relative '../../domain/entities/transaction'

module Adapters
  module Repositories
    class TransactionRepository
      include Domain::Ports::TransactionRepository

      def initialize(db:)
        @db = db
      end

      def find_by_id(id)
        row = @db[:transactions].where(id: id).first
        row ? to_entity(row) : nil
      end

      def create(attributes)
        now = Time.now
        id  = @db[:transactions].insert(
          product_id:  attributes[:product_id],
          customer_id: attributes[:customer_id],
          amount:      attributes[:amount],
          status:      attributes[:status] || 'PENDING',
          created_at:  now,
          updated_at:  now
        )
        find_by_id(id)
      end

      def update(id, attributes)
        updates = {}
        updates[:status]               = attributes[:status]               if attributes.key?(:status)
        updates[:wompi_transaction_id] = attributes[:wompi_transaction_id] if attributes.key?(:wompi_transaction_id)
        updates[:updated_at]           = Time.now

        @db[:transactions].where(id: id).update(updates)
      end

      private

      def to_entity(row)
        Domain::Entities::Transaction.new(
          id:                   row[:id],
          product_id:           row[:product_id],
          customer_id:          row[:customer_id],
          amount:               row[:amount].to_f,
          status:               row[:status],
          wompi_transaction_id: row[:wompi_transaction_id],
          created_at:           row[:created_at],
          updated_at:           row[:updated_at]
        )
      end
    end
  end
end
