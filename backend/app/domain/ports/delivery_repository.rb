# frozen_string_literal: true

module Domain
  module Ports
    module DeliveryRepository
      def find_by_transaction_id(transaction_id) = raise NotImplementedError
      def create(attributes)                     = raise NotImplementedError
    end
  end
end
