# frozen_string_literal: true

require_relative 'application_controller'
require_relative '../../domain/use_cases/create_customer'
require_relative '../repositories/customer_repository'

class CustomersController < ApplicationController
  class << self
    def create_customer_use_case
      @create_customer_use_case ||= Domain::UseCases::CreateCustomer.new(
        customer_repository: Adapters::Repositories::CustomerRepository.new(db: DB),
        jwt_service:         jwt_service
      )
    end
  end

  post '/' do
    result = self.class.create_customer_use_case.call(params: parsed_body)

    if result.success?
      data = result.value!
      success(
        {
          customer: serialize_customer(data[:customer]),
          token:    data[:token]
        },
        status: 201
      )
    else
      validation_error(result.failure)
    end
  end

  private

  def serialize_customer(c)
    { id: c.id, name: c.name, email: c.email, address: c.address, phone: c.phone }
  end
end
