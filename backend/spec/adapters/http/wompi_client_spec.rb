# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/adapters/http/wompi_client'

RSpec.describe Adapters::Http::WompiClient do
  subject(:client) do
    described_class.new(
      api_url:     'https://api-sandbox.co.uat.wompi.dev/v1',
      private_key: 'prv_stagtest_test'
    )
  end

  describe '#charge' do
    context 'when Wompi returns APPROVED' do
      let(:wompi_response) do
        {
          'data' => {
            'id'     => 'wompi-abc-123',
            'status' => 'APPROVED'
          }
        }
      end

      before do
        stub_request(:post, 'https://api-sandbox.co.uat.wompi.dev/v1/transactions')
          .to_return(
            status: 201,
            body:   wompi_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns hash with id and APPROVED status' do
        result = client.charge(
          amount:         9_318_970,
          card_token:     'tok_test_xxx',
          customer_email: 'juan@example.com',
          installments:   1,
          reference:      'pay-1-1234567890'
        )
        expect(result[:id]).to eq('wompi-abc-123')
        expect(result[:status]).to eq('APPROVED')
      end
    end

    context 'when Wompi returns DECLINED' do
      let(:wompi_response) do
        {
          'data' => {
            'id'     => 'wompi-def-456',
            'status' => 'DECLINED'
          }
        }
      end

      before do
        stub_request(:post, 'https://api-sandbox.co.uat.wompi.dev/v1/transactions')
          .to_return(
            status: 201,
            body:   wompi_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns hash with DECLINED status' do
        result = client.charge(
          amount: 100_000, card_token: 'tok', customer_email: 'a@b.com',
          installments: 1, reference: 'ref-1'
        )
        expect(result[:status]).to eq('DECLINED')
      end
    end

    context 'when the network fails' do
      before do
        stub_request(:post, 'https://api-sandbox.co.uat.wompi.dev/v1/transactions')
          .to_raise(Faraday::TimeoutError)
      end

      it 'raises a Domain::Errors::PaymentError' do
        expect do
          client.charge(
            amount: 100_000, card_token: 'tok', customer_email: 'a@b.com',
            installments: 1, reference: 'ref-2'
          )
        end.to raise_error(Domain::Errors::PaymentError)
      end
    end

    context 'when Wompi returns an HTTP error' do
      before do
        stub_request(:post, 'https://api-sandbox.co.uat.wompi.dev/v1/transactions')
          .to_return(status: 422, body: '{"error":"invalid"}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises a Domain::Errors::PaymentError' do
        expect do
          client.charge(
            amount: 100_000, card_token: 'tok', customer_email: 'a@b.com',
            installments: 1, reference: 'ref-3'
          )
        end.to raise_error(Domain::Errors::PaymentError)
      end
    end
  end
end
