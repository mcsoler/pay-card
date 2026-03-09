# frozen_string_literal: true

require_relative '../errors'

module Domain
  module Entities
    class Transaction
      VALID_STATUSES = %w[PENDING APPROVED DECLINED ERROR].freeze

      attr_reader :id, :product_id, :customer_id, :created_at
      attr_accessor :amount, :status, :wompi_transaction_id, :updated_at, :errors

      def initialize(id:, product_id:, customer_id:, amount:, status:, wompi_transaction_id:, created_at:, updated_at:)
        @id                   = id
        @product_id           = product_id
        @customer_id          = customer_id
        @amount               = amount
        @status               = status
        @wompi_transaction_id = wompi_transaction_id
        @created_at           = created_at
        @updated_at           = updated_at
        @errors               = []
      end

      def pending?  = status == 'PENDING'
      def approved? = status == 'APPROVED'
      def declined? = status == 'DECLINED'

      def approve!(wompi_id:)
        @status               = 'APPROVED'
        @wompi_transaction_id = wompi_id
        @updated_at           = Time.now
      end

      def decline!(wompi_id:)
        @status               = 'DECLINED'
        @wompi_transaction_id = wompi_id
        @updated_at           = Time.now
      end

      def valid?
        @errors = []
        @errors << 'product_id is required'      if product_id.nil?
        @errors << 'customer_id is required'     if customer_id.nil?
        @errors << 'Amount must be positive'     if amount.to_f <= 0
        @errors << "Status '#{status}' is invalid" unless VALID_STATUSES.include?(status)
        @errors.empty?
      end

      def to_h
        {
          id:                   id,
          product_id:           product_id,
          customer_id:          customer_id,
          amount:               amount,
          status:               status,
          wompi_transaction_id: wompi_transaction_id,
          created_at:           created_at,
          updated_at:           updated_at
        }
      end
    end
  end
end
