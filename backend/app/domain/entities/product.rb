# frozen_string_literal: true

require_relative '../errors'

module Domain
  module Entities
    class Product
      attr_reader :id, :name, :description, :price, :base_fee, :delivery_fee
      attr_accessor :stock, :errors

      VALID_STATUSES = %w[].freeze

      def initialize(id:, name:, description:, price:, stock:, base_fee:, delivery_fee:)
        @id           = id
        @name         = name
        @description  = description
        @price        = price
        @stock        = stock
        @base_fee     = base_fee
        @delivery_fee = delivery_fee
        @errors       = []
      end

      def available?
        stock.to_i > 0
      end

      def total_amount
        price.to_f + base_fee.to_f + delivery_fee.to_f
      end

      def decrease_stock!
        raise Domain::Errors::InsufficientStockError, 'Product out of stock' unless available?

        @stock -= 1
      end

      def valid?
        @errors = []
        @errors << 'Name is required'           if name.to_s.strip.empty?
        @errors << 'Price must be greater than 0' if price.to_f <= 0
        @errors << 'Stock cannot be negative'   if stock.to_i < 0
        @errors.empty?
      end

      def to_h
        {
          id:           id,
          name:         name,
          description:  description,
          price:        price,
          stock:        stock,
          base_fee:     base_fee,
          delivery_fee: delivery_fee
        }
      end
    end
  end
end
