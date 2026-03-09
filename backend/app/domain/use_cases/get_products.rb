# frozen_string_literal: true

require 'dry/monads'

module Domain
  module UseCases
    class GetProducts
      include Dry::Monads[:result]

      def initialize(product_repository:)
        @product_repository = product_repository
      end

      def call
        products = @product_repository.all
        Success(products)
      rescue StandardError => e
        Failure(e.message)
      end
    end
  end
end
