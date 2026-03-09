# frozen_string_literal: true

require 'dry/monads'

module Domain
  module UseCases
    class CreateTransaction
      include Dry::Monads[:result]

      def initialize(product_repository:, transaction_repository:)
        @product_repository     = product_repository
        @transaction_repository = transaction_repository
      end

      def call(params:)
        product = @product_repository.find_by_id(params[:product_id])
        return Failure("Product not found") if product.nil?
        return Failure("Product out of stock") unless product.available?

        transaction = @transaction_repository.create(
          product_id:  params[:product_id],
          customer_id: params[:customer_id],
          amount:      product.total_amount,
          status:      'PENDING'
        )

        Success(transaction)
      rescue StandardError => e
        Failure(e.message)
      end
    end
  end
end
