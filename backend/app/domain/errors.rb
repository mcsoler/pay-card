# frozen_string_literal: true

module Domain
  module Errors
    class BaseError < StandardError; end
    class NotFoundError < BaseError; end
    class InsufficientStockError < BaseError; end
    class ValidationError < BaseError
      attr_reader :messages

      def initialize(messages)
        @messages = Array(messages)
        super(@messages.join(', '))
      end
    end
    class PaymentError < BaseError; end
    class UnauthorizedError < BaseError; end
  end
end
