# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/domain/use_cases/create_customer'
require_relative '../../../app/domain/entities/customer'

RSpec.describe Domain::UseCases::CreateCustomer do
  let(:customer_repository) { instance_double('Domain::Ports::CustomerRepository') }
  let(:jwt_service)         { instance_double('Infrastructure::Jwt::JwtService') }
  subject(:use_case) { described_class.new(customer_repository: customer_repository, jwt_service: jwt_service) }

  let(:valid_params) do
    { name: 'Juan Pérez', email: 'juan@example.com', address: 'Calle 123, Bogotá', phone: '+573001234567' }
  end

  let(:saved_customer) do
    Domain::Entities::Customer.new(id: 1, **valid_params)
  end

  describe '#call' do
    context 'with valid params' do
      before do
        allow(customer_repository).to receive(:find_by_email).with('juan@example.com').and_return(nil)
        allow(customer_repository).to receive(:create).and_return(saved_customer)
        allow(jwt_service).to receive(:encode).with({ customer_id: 1 }).and_return('jwt.token.here')
      end

      it 'returns Success with customer and token' do
        result = use_case.call(params: valid_params)
        expect(result).to be_success
        expect(result.value![:customer]).to eq(saved_customer)
        expect(result.value![:token]).to eq('jwt.token.here')
      end
    end

    context 'when customer already exists with same email' do
      before do
        allow(customer_repository).to receive(:find_by_email).with('juan@example.com').and_return(saved_customer)
        allow(jwt_service).to receive(:encode).with({ customer_id: 1 }).and_return('jwt.token.here')
      end

      it 'returns existing customer with new token (upsert behavior)' do
        result = use_case.call(params: valid_params)
        expect(result).to be_success
        expect(result.value![:customer]).to eq(saved_customer)
      end
    end

    context 'with invalid params' do
      let(:invalid_params) { { name: '', email: 'bad-email', address: '', phone: '' } }

      it 'returns Failure with validation errors' do
        result = use_case.call(params: invalid_params)
        expect(result).to be_failure
        expect(result.failure).to be_an(Array)
        expect(result.failure).not_to be_empty
      end
    end
  end
end
