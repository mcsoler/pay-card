# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require_relative '../../../app/adapters/controllers/transactions_controller'

RSpec.describe TransactionsController, 'GET /:wompi_id/status' do
  include Rack::Test::Methods

  def app = TransactionsController

  let(:wompi_id)   { '15113-1773033068-12060' }
  let(:jwt_service) { instance_double(Infrastructure::Jwt::JwtService) }
  let(:get_transaction_status_use_case) { instance_double(Domain::UseCases::GetTransactionStatus) }
  let(:auth_header) { { 'HTTP_AUTHORIZATION' => 'Bearer valid.jwt.token', 'CONTENT_TYPE' => 'application/json' } }

  before do
    allow(TransactionsController).to receive(:jwt_service).and_return(jwt_service)
    allow(TransactionsController).to receive(:get_transaction_status_use_case)
      .and_return(get_transaction_status_use_case)
    allow(jwt_service).to receive(:decode).with('valid.jwt.token').and_return({ 'customer_id' => 1 })
    allow(jwt_service).to receive(:decode).with(nil).and_return(nil)
  end

  context 'when the transaction is APPROVED' do
    before do
      allow(get_transaction_status_use_case).to receive(:call)
        .with(wompi_id: wompi_id)
        .and_return(Dry::Monads::Success({ id: wompi_id, status: 'APPROVED' }))
    end

    it 'returns 200 with the status' do
      get "/#{wompi_id}/status", {}, auth_header
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body.dig('data', 'status')).to eq('APPROVED')
    end
  end

  context 'when the transaction is PENDING' do
    before do
      allow(get_transaction_status_use_case).to receive(:call)
        .with(wompi_id: wompi_id)
        .and_return(Dry::Monads::Success({ id: wompi_id, status: 'PENDING' }))
    end

    it 'returns 200 with PENDING status' do
      get "/#{wompi_id}/status", {}, auth_header
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body.dig('data', 'status')).to eq('PENDING')
    end
  end

  context 'when the gateway fails' do
    before do
      allow(get_transaction_status_use_case).to receive(:call)
        .with(wompi_id: wompi_id)
        .and_return(Dry::Monads::Failure('Wompi unreachable'))
    end

    it 'returns 422' do
      get "/#{wompi_id}/status", {}, auth_header
      expect(last_response.status).to eq(422)
    end
  end

  context 'without JWT' do
    it 'returns 401' do
      get "/#{wompi_id}/status"
      expect(last_response.status).to eq(401)
    end
  end
end
