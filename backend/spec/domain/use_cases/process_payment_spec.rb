# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/domain/use_cases/process_payment'
require_relative '../../../app/domain/entities/transaction'
require_relative '../../../app/domain/entities/product'

RSpec.describe Domain::UseCases::ProcessPayment do
  let(:transaction_repository) { instance_double('Domain::Ports::TransactionRepository') }
  let(:product_repository)     { instance_double('Domain::Ports::ProductRepository') }
  let(:payment_gateway)        { instance_double('Domain::Ports::PaymentGateway') }

  subject(:use_case) do
    described_class.new(
      transaction_repository: transaction_repository,
      product_repository:     product_repository,
      payment_gateway:        payment_gateway
    )
  end

  let(:product) do
    Domain::Entities::Product.new(id: 1, name: 'MacBook', description: 'Laptop', price: 8_999_000, stock: 5, base_fee: 269_970, delivery_fee: 50_000)
  end

  let(:pending_transaction) do
    Domain::Entities::Transaction.new(
      id: 1, product_id: 1, customer_id: 2,
      amount: 9_318_970, status: 'PENDING',
      wompi_transaction_id: nil, created_at: Time.now, updated_at: Time.now
    )
  end

  let(:valid_params) do
    {
      transaction_id: 1,
      card_token:     'tok_stagtest_xxxx',
      installments:   1,
      customer_email: 'juan@example.com'
    }
  end

  describe '#call' do
    context 'when payment is approved' do
      let(:gateway_response) { { id: 'wompi-abc-123', status: 'APPROVED' } }

      before do
        allow(transaction_repository).to receive(:find_by_id).with(1).and_return(pending_transaction)
        allow(product_repository).to receive(:find_by_id).with(1).and_return(product)
        allow(payment_gateway).to receive(:charge).and_return(gateway_response)
        allow(transaction_repository).to receive(:update).and_return(true)
        allow(product_repository).to receive(:update_stock).and_return(true)
      end

      it 'returns Success with APPROVED status' do
        result = use_case.call(params: valid_params)
        expect(result).to be_success
        expect(result.value![:status]).to eq('APPROVED')
      end

      it 'decrements product stock' do
        expect(product_repository).to receive(:update_stock).with(1, 4)
        use_case.call(params: valid_params)
      end

      it 'updates transaction status to APPROVED' do
        expect(transaction_repository).to receive(:update).with(
          1, hash_including(status: 'APPROVED', wompi_transaction_id: 'wompi-abc-123')
        )
        use_case.call(params: valid_params)
      end
    end

    context 'when payment is declined' do
      let(:gateway_response) { { id: 'wompi-def-456', status: 'DECLINED' } }

      before do
        allow(transaction_repository).to receive(:find_by_id).with(1).and_return(pending_transaction)
        allow(product_repository).to receive(:find_by_id).with(1).and_return(product)
        allow(payment_gateway).to receive(:charge).and_return(gateway_response)
        allow(transaction_repository).to receive(:update).and_return(true)
      end

      it 'returns Success result with DECLINED status' do
        result = use_case.call(params: valid_params)
        expect(result).to be_success
        expect(result.value![:status]).to eq('DECLINED')
      end

      it 'does NOT decrement stock' do
        expect(product_repository).not_to receive(:update_stock)
        use_case.call(params: valid_params)
      end
    end

    context 'when transaction does not exist' do
      before { allow(transaction_repository).to receive(:find_by_id).with(1).and_return(nil) }

      it 'returns Failure' do
        result = use_case.call(params: valid_params)
        expect(result).to be_failure
      end
    end

    context 'when payment gateway raises an error' do
      before do
        allow(transaction_repository).to receive(:find_by_id).with(1).and_return(pending_transaction)
        allow(product_repository).to receive(:find_by_id).with(1).and_return(product)
        allow(payment_gateway).to receive(:charge).and_raise(StandardError, 'Gateway timeout')
        allow(transaction_repository).to receive(:update).and_return(true)
      end

      it 'returns Failure' do
        result = use_case.call(params: valid_params)
        expect(result).to be_failure
        expect(result.failure).to include('Gateway timeout')
      end
    end
  end
end
