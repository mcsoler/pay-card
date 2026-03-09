# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require_relative '../../../app/adapters/controllers/customers_controller'

RSpec.describe CustomersController do
  include Rack::Test::Methods

  def app = CustomersController

  let(:customer) { Domain::Entities::Customer.new(id: 1, name: 'Juan', email: 'juan@x.com', address: 'Calle 1', phone: '') }
  let(:create_customer_use_case) { instance_double(Domain::UseCases::CreateCustomer) }

  before do
    allow(CustomersController).to receive(:create_customer_use_case).and_return(create_customer_use_case)
  end

  describe 'POST /' do
    let(:valid_body) do
      { name: 'Juan', email: 'juan@x.com', address: 'Calle 1', phone: '+57300' }.to_json
    end

    context 'with valid params' do
      before do
        allow(create_customer_use_case).to receive(:call)
          .and_return(Dry::Monads::Success({ customer: customer, token: 'jwt.tok' }))
      end

      it 'returns 201 with customer and token' do
        post '/', valid_body, 'CONTENT_TYPE' => 'application/json'
        expect(last_response.status).to eq(201)
        body = JSON.parse(last_response.body)
        expect(body['data']['token']).to eq('jwt.tok')
        expect(body['data']['customer']['email']).to eq('juan@x.com')
      end
    end

    context 'with invalid params' do
      before do
        allow(create_customer_use_case).to receive(:call)
          .and_return(Dry::Monads::Failure(['Name is required', 'Email is invalid']))
      end

      it 'returns 422 with error messages' do
        post '/', { name: '', email: 'bad' }.to_json, 'CONTENT_TYPE' => 'application/json'
        expect(last_response.status).to eq(422)
        body = JSON.parse(last_response.body)
        expect(body['errors']).to include('Name is required')
      end
    end
  end
end
