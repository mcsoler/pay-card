# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require_relative '../../../app/adapters/controllers/transactions_controller'

RSpec.describe TransactionsController do
  include Rack::Test::Methods

  def app = TransactionsController

  let(:transaction) do
    Domain::Entities::Transaction.new(
      id: 1, product_id: 1, customer_id: 1,
      amount: 9_318_970, status: 'PENDING',
      wompi_transaction_id: nil, created_at: Time.now, updated_at: Time.now
    )
  end

  let(:create_transaction_use_case) { instance_double(Domain::UseCases::CreateTransaction) }
  let(:process_payment_use_case)    { instance_double(Domain::UseCases::ProcessPayment) }
  let(:update_transaction_use_case) { instance_double(Domain::UseCases::UpdateTransaction) }
  let(:jwt_service)                 { instance_double(Infrastructure::Jwt::JwtService) }

  before do
    allow(TransactionsController).to receive(:create_transaction_use_case).and_return(create_transaction_use_case)
    allow(TransactionsController).to receive(:process_payment_use_case).and_return(process_payment_use_case)
    allow(TransactionsController).to receive(:update_transaction_use_case).and_return(update_transaction_use_case)
    allow(TransactionsController).to receive(:jwt_service).and_return(jwt_service)
    allow(jwt_service).to receive(:decode).with('valid.jwt.token').and_return({ 'customer_id' => 1 })
  end

  describe 'POST /' do
    let(:valid_body) { { product_id: 1 }.to_json }
    let(:auth_header) { { 'HTTP_AUTHORIZATION' => 'Bearer valid.jwt.token', 'CONTENT_TYPE' => 'application/json' } }

    context 'with valid params and JWT' do
      before do
        allow(create_transaction_use_case).to receive(:call)
          .and_return(Dry::Monads::Success(transaction))
        allow(process_payment_use_case).to receive(:call)
          .and_return(Dry::Monads::Success({ status: 'APPROVED', wompi_id: 'w-abc', transaction_id: 1 }))
      end

      it 'returns 201' do
        post '/', { product_id: 1, card_token: 'tok', installments: 1 }.to_json, auth_header
        expect(last_response.status).to eq(201)
      end
    end

    context 'without JWT' do
      it 'returns 401' do
        post '/', valid_body, 'CONTENT_TYPE' => 'application/json'
        expect(last_response.status).to eq(401)
      end
    end
  end

  describe 'PUT /:id' do
    let(:auth_header) { { 'HTTP_AUTHORIZATION' => 'Bearer valid.jwt.token', 'CONTENT_TYPE' => 'application/json' } }

    context 'when update succeeds' do
      before do
        allow(update_transaction_use_case).to receive(:call)
          .and_return(Dry::Monads::Success(transaction))
      end

      it 'returns 200' do
        put '/1', { status: 'APPROVED', wompi_transaction_id: 'w-123' }.to_json, auth_header
        expect(last_response.status).to eq(200)
      end
    end

    context 'when transaction not found' do
      before do
        allow(update_transaction_use_case).to receive(:call)
          .and_return(Dry::Monads::Failure('Transaction not found'))
      end

      it 'returns 404' do
        put '/99', { status: 'APPROVED' }.to_json, auth_header
        expect(last_response.status).to eq(404)
      end
    end
  end
end
