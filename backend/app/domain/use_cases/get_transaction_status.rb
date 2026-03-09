# frozen_string_literal: true

require 'dry/monads'

module Domain
  module UseCases
    # ROP: queries the payment gateway for the current status of a transaction
    class GetTransactionStatus
      include Dry::Monads[:result]

      def initialize(payment_gateway:)
        @payment_gateway = payment_gateway
      end

      def call(wompi_id:)
        result = @payment_gateway.transaction_status(wompi_id)
        Success(result)
      rescue StandardError => e
        Failure(e.message)
      end
    end
  end
end
