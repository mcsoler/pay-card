# frozen_string_literal: true

module Domain
  module Ports
    # Interface that any payment gateway adapter must implement
    module PaymentGateway
      def charge(amount:, card_token:, customer_email:, installments:, reference:) = raise NotImplementedError
      def transaction_status(wompi_id) = raise NotImplementedError
    end
  end
end
