# frozen_string_literal: true

require_relative 'application_controller'
require_relative '../../domain/use_cases/create_delivery'
require_relative '../repositories/delivery_repository'
require_relative '../repositories/transaction_repository'

class DeliveriesController < ApplicationController
  class << self
    def create_delivery_use_case
      @create_delivery_use_case ||= Domain::UseCases::CreateDelivery.new(
        delivery_repository:    Adapters::Repositories::DeliveryRepository.new(db: DB),
        transaction_repository: Adapters::Repositories::TransactionRepository.new(db: DB)
      )
    end
  end

  post '/' do
    authenticate!

    result = self.class.create_delivery_use_case.call(params: parsed_body)

    if result.success?
      delivery = result.value!
      success(
        {
          id:             delivery.id,
          transaction_id: delivery.transaction_id,
          status:         delivery.status,
          address:        delivery.address,
          estimated_date: delivery.estimated_date
        },
        status: 201
      )
    else
      errors = result.failure
      halt 422, json(errors: Array(errors))
    end
  end
end
