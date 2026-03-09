# frozen_string_literal: true

require 'dry/monads'
require_relative '../entities/delivery'

module Domain
  module UseCases
    class CreateDelivery
      include Dry::Monads[:result, :do]

      def initialize(delivery_repository:, transaction_repository:)
        @delivery_repository    = delivery_repository
        @transaction_repository = transaction_repository
      end

      def call(params:)
        transaction = yield find_approved_transaction(params[:transaction_id])

        delivery = build_delivery(params, transaction)
        return Failure(delivery.errors) unless delivery.valid?

        saved = @delivery_repository.create(delivery.to_h.except(:id))
        Success(saved)
      rescue StandardError => e
        Failure(e.message)
      end

      private

      def find_approved_transaction(id)
        t = @transaction_repository.find_by_id(id)
        return Failure("Transaction not found") if t.nil?
        return Failure("Delivery only allowed for approved transactions") unless t.approved?

        Success(t)
      end

      def build_delivery(params, transaction)
        Entities::Delivery.new(
          id:             nil,
          transaction_id: transaction.id,
          status:         'PENDING',
          address:        params[:address].to_s.strip,
          estimated_date: params[:estimated_date]
        )
      end
    end
  end
end
