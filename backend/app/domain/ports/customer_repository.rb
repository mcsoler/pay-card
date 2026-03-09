# frozen_string_literal: true

module Domain
  module Ports
    module CustomerRepository
      def find_by_id(id)       = raise NotImplementedError
      def find_by_email(email) = raise NotImplementedError
      def create(attributes)   = raise NotImplementedError
    end
  end
end
