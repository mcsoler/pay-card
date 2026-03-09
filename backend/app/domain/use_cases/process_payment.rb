# frozen_string_literal: true

require 'dry/monads'

module Domain
  module UseCases
    # ROP: each step returns Success/Failure, chain stops on first Failure
    class ProcessPayment
      include Dry::Monads[:result, :do]

      def initialize(transaction_repository:, product_repository:, payment_gateway:)
        @transaction_repository = transaction_repository
        @product_repository     = product_repository
        @payment_gateway        = payment_gateway
      end

      def call(params:)
        transaction = yield find_transaction(params[:transaction_id])
        product     = yield find_product(transaction.product_id)
        gateway_res = yield charge_gateway(params, transaction)
        yield persist_result(transaction, product, gateway_res)

        Success({ status: gateway_res[:status], wompi_id: gateway_res[:id], transaction_id: transaction.id })
      rescue StandardError => e
        Failure(e.message)
      end

      private

      def find_transaction(id)
        t = @transaction_repository.find_by_id(id)
        t ? Success(t) : Failure("Transaction not found")
      end

      def find_product(id)
        p = @product_repository.find_by_id(id)
        p ? Success(p) : Failure("Product not found")
      end

      def charge_gateway(params, transaction)
        result = @payment_gateway.charge(
          amount:         transaction.amount,
          card_token:     params[:card_token],
          customer_email: params[:customer_email],
          installments:   params[:installments] || 1,
          reference:      "pay-#{transaction.id}-#{Time.now.to_i}"
        )
        Success(result)
      rescue StandardError => e
        Failure(e.message)
      end

      def persist_result(transaction, product, gateway_res)
        status   = gateway_res[:status]
        wompi_id = gateway_res[:id]

        @transaction_repository.update(transaction.id, status: status, wompi_transaction_id: wompi_id)

        if status == 'APPROVED'
          new_stock = product.stock.to_i - 1
          @product_repository.update_stock(product.id, new_stock)
        end

        Success(true)
      end
    end
  end
end
