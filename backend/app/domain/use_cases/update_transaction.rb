# frozen_string_literal: true

require 'dry/monads'

module Domain
  module UseCases
    class UpdateTransaction
      include Dry::Monads[:result, :do]

      def initialize(transaction_repository:, product_repository:)
        @transaction_repository = transaction_repository
        @product_repository     = product_repository
      end

      def call(id:, params:)
        transaction = yield find_transaction(id)

        # Idempotent: if already in final state, return as-is
        return Success(transaction) if transaction.approved? || transaction.declined?

        yield apply_update(transaction, params)

        Success(transaction)
      rescue StandardError => e
        Failure(e.message)
      end

      private

      def find_transaction(id)
        t = @transaction_repository.find_by_id(id)
        t ? Success(t) : Failure("Transaction not found")
      end

      def apply_update(transaction, params)
        status   = params[:status].to_s.upcase
        wompi_id = params[:wompi_transaction_id]

        @transaction_repository.update(transaction.id, status: status, wompi_transaction_id: wompi_id)

        if status == 'APPROVED'
          product = @product_repository.find_by_id(transaction.product_id)
          if product
            new_stock = [product.stock.to_i - 1, 0].max
            @product_repository.update_stock(product.id, new_stock)
          end
        end

        transaction.status               = status
        transaction.wompi_transaction_id = wompi_id

        Success(true)
      end
    end
  end
end
