# frozen_string_literal: true

require 'dry/monads'
require_relative '../entities/customer'

module Domain
  module UseCases
    class CreateCustomer
      include Dry::Monads[:result]

      def initialize(customer_repository:, jwt_service:)
        @customer_repository = customer_repository
        @jwt_service         = jwt_service
      end

      def call(params:)
        customer = build_customer(params)
        return Failure(customer.errors) unless customer.valid?

        saved = find_or_create(customer, params[:email])
        token = @jwt_service.encode({ customer_id: saved.id })

        Success({ customer: saved, token: token })
      rescue StandardError => e
        Failure([e.message])
      end

      private

      def build_customer(params)
        Entities::Customer.new(
          id:      nil,
          name:    params[:name].to_s.strip,
          email:   params[:email].to_s.strip.downcase,
          address: params[:address].to_s.strip,
          phone:   params[:phone].to_s.strip
        )
      end

      def find_or_create(customer, email)
        existing = @customer_repository.find_by_email(email.to_s.downcase)
        return existing if existing

        @customer_repository.create(customer.to_h.except(:id))
      end
    end
  end
end
