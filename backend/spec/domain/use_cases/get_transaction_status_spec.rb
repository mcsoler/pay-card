# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/domain/use_cases/get_transaction_status'

RSpec.describe Domain::UseCases::GetTransactionStatus do
  subject(:use_case) do
    described_class.new(payment_gateway: gateway_double)
  end

  let(:gateway_double) { instance_double('PaymentGateway') }
  let(:wompi_id)       { '15113-1773033068-12060' }

  describe '#call' do
    context 'when the gateway returns a final status (APPROVED)' do
      before do
        allow(gateway_double).to receive(:transaction_status)
          .with(wompi_id)
          .and_return({ id: wompi_id, status: 'APPROVED' })
      end

      it 'returns Success with the status hash' do
        result = use_case.call(wompi_id: wompi_id)
        expect(result).to be_success
        expect(result.value![:status]).to eq('APPROVED')
      end
    end

    context 'when the gateway returns DECLINED' do
      before do
        allow(gateway_double).to receive(:transaction_status)
          .with(wompi_id)
          .and_return({ id: wompi_id, status: 'DECLINED' })
      end

      it 'returns Success with DECLINED status' do
        result = use_case.call(wompi_id: wompi_id)
        expect(result).to be_success
        expect(result.value![:status]).to eq('DECLINED')
      end
    end

    context 'when the gateway returns PENDING' do
      before do
        allow(gateway_double).to receive(:transaction_status)
          .with(wompi_id)
          .and_return({ id: wompi_id, status: 'PENDING' })
      end

      it 'returns Success with PENDING status' do
        result = use_case.call(wompi_id: wompi_id)
        expect(result).to be_success
        expect(result.value![:status]).to eq('PENDING')
      end
    end

    context 'when the gateway raises an error' do
      before do
        allow(gateway_double).to receive(:transaction_status)
          .and_raise(Domain::Errors::PaymentError, 'Timeout')
      end

      it 'returns Failure with the error message' do
        result = use_case.call(wompi_id: wompi_id)
        expect(result).to be_failure
        expect(result.failure).to include('Timeout')
      end
    end
  end
end
