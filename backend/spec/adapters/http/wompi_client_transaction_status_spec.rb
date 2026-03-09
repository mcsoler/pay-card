# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/adapters/http/wompi_client'

RSpec.describe Adapters::Http::WompiClient do
  subject(:client) do
    described_class.new(
      api_url:     'https://api-sandbox.co.uat.wompi.dev/v1',
      private_key: 'prv_stagtest_test',
      public_key:  'pub_stagtest_test',
      integrity_secret: 'integrity_test'
    )
  end

  describe '#transaction_status' do
    let(:wompi_id) { '15113-1773033068-12060' }

    context 'when Wompi returns APPROVED' do
      before do
        stub_request(:get, "https://api-sandbox.co.uat.wompi.dev/v1/transactions/#{wompi_id}")
          .to_return(
            status: 200,
            body:   { 'data' => { 'id' => wompi_id, 'status' => 'APPROVED' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns a hash with id and APPROVED status' do
        result = client.transaction_status(wompi_id)
        expect(result[:id]).to eq(wompi_id)
        expect(result[:status]).to eq('APPROVED')
      end
    end

    context 'when Wompi returns DECLINED' do
      before do
        stub_request(:get, "https://api-sandbox.co.uat.wompi.dev/v1/transactions/#{wompi_id}")
          .to_return(
            status: 200,
            body:   { 'data' => { 'id' => wompi_id, 'status' => 'DECLINED' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns a hash with DECLINED status' do
        result = client.transaction_status(wompi_id)
        expect(result[:status]).to eq('DECLINED')
      end
    end

    context 'when Wompi returns PENDING' do
      before do
        stub_request(:get, "https://api-sandbox.co.uat.wompi.dev/v1/transactions/#{wompi_id}")
          .to_return(
            status: 200,
            body:   { 'data' => { 'id' => wompi_id, 'status' => 'PENDING' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns a hash with PENDING status' do
        result = client.transaction_status(wompi_id)
        expect(result[:status]).to eq('PENDING')
      end
    end

    context 'when Wompi returns 404' do
      before do
        stub_request(:get, "https://api-sandbox.co.uat.wompi.dev/v1/transactions/#{wompi_id}")
          .to_return(status: 404, body: '{"error":"not found"}',
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises a Domain::Errors::PaymentError' do
        expect { client.transaction_status(wompi_id) }
          .to raise_error(Domain::Errors::PaymentError)
      end
    end

    context 'when the network fails' do
      before do
        stub_request(:get, "https://api-sandbox.co.uat.wompi.dev/v1/transactions/#{wompi_id}")
          .to_raise(Faraday::TimeoutError)
      end

      it 'raises a Domain::Errors::PaymentError' do
        expect { client.transaction_status(wompi_id) }
          .to raise_error(Domain::Errors::PaymentError)
      end
    end
  end
end
