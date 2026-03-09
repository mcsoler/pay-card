# frozen_string_literal: true

require_relative '../../domain/ports/product_repository'
require_relative '../../domain/entities/product'

module Adapters
  module Repositories
    class ProductRepository
      include Domain::Ports::ProductRepository

      def initialize(db:)
        @db = db
      end

      def all
        @db[:products].order(:name).map { |row| to_entity(row) }
      end

      def find_by_id(id)
        row = @db[:products].where(id: id).first
        row ? to_entity(row) : nil
      end

      def update_stock(id, stock)
        @db[:products].where(id: id).update(stock: stock, updated_at: Time.now)
      end

      private

      def to_entity(row)
        Domain::Entities::Product.new(
          id:           row[:id],
          name:         row[:name],
          description:  row[:description],
          price:        row[:price].to_f,
          stock:        row[:stock].to_i,
          base_fee:     row[:base_fee].to_f,
          delivery_fee: row[:delivery_fee].to_f
        )
      end
    end
  end
end
