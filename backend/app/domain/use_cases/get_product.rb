# frozen_string_literal: true

require 'dry/monads'

module Domain
  module UseCases
    class GetProduct
      include Dry::Monads[:result]

      def initialize(product_repository:)
        @product_repository = product_repository
      end

      def call(id:)
        product = @product_repository.find_by_id(id)
        return Failure("Product not found") if product.nil?

        Success(product)
      rescue StandardError => e
        Failure(e.message)
      end
    end
  end
end
