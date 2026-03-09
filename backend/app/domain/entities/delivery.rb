# frozen_string_literal: true

module Domain
  module Entities
    class Delivery
      attr_reader :id, :transaction_id, :created_at
      attr_accessor :status, :address, :estimated_date, :errors

      def initialize(id:, transaction_id:, status:, address:, estimated_date:)
        @id             = id
        @transaction_id = transaction_id
        @status         = status
        @address        = address
        @estimated_date = estimated_date
        @errors         = []
      end

      def valid?
        @errors = []
        @errors << 'transaction_id is required' if transaction_id.nil?
        @errors << 'Address is required'        if address.to_s.strip.empty?
        @errors.empty?
      end

      def to_h
        {
          id:             id,
          transaction_id: transaction_id,
          status:         status,
          address:        address,
          estimated_date: estimated_date
        }
      end
    end
  end
end
