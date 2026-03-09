# frozen_string_literal: true

module Domain
  module Ports
    # Interface that any product persistence adapter must implement
    module ProductRepository
      def all                      = raise NotImplementedError
      def find_by_id(id)           = raise NotImplementedError
      def update_stock(id, stock)  = raise NotImplementedError
    end
  end
end
