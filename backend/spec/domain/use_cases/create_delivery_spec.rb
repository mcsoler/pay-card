# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/domain/use_cases/create_delivery'
require_relative '../../../app/domain/entities/delivery'
require_relative '../../../app/domain/entities/transaction'

RSpec.describe Domain::UseCases::CreateDelivery do
  let(:delivery_repository)    { instance_double('Domain::Ports::DeliveryRepository') }
  let(:transaction_repository) { instance_double('Domain::Ports::TransactionRepository') }

  subject(:use_case) do
    described_class.new(
      delivery_repository:    delivery_repository,
      transaction_repository: transaction_repository
    )
  end

  let(:approved_transaction) do
    Domain::Entities::Transaction.new(
      id: 1, product_id: 1, customer_id: 2,
      amount: 9_318_970, status: 'APPROVED',
      wompi_transaction_id: 'wompi-123', created_at: Time.now, updated_at: Time.now
    )
  end

  let(:valid_params) do
    { transaction_id: 1, address: 'Calle 123, Bogotá', estimated_date: Date.today + 5 }
  end

  let(:delivery) do
    Domain::Entities::Delivery.new(
      id: 1, transaction_id: 1, status: 'PENDING',
      address: 'Calle 123, Bogotá', estimated_date: Date.today + 5
    )
  end

  describe '#call' do
    context 'when transaction is approved' do
      before do
        allow(transaction_repository).to receive(:find_by_id).with(1).and_return(approved_transaction)
        allow(delivery_repository).to receive(:create).and_return(delivery)
      end

      it 'returns Success with the created delivery' do
        result = use_case.call(params: valid_params)
        expect(result).to be_success
        expect(result.value!.status).to eq('PENDING')
        expect(result.value!.address).to eq('Calle 123, Bogotá')
      end
    end

    context 'when transaction is not approved' do
      let(:pending_transaction) do
        Domain::Entities::Transaction.new(
          id: 1, product_id: 1, customer_id: 2,
          amount: 9_318_970, status: 'PENDING',
          wompi_transaction_id: nil, created_at: Time.now, updated_at: Time.now
        )
      end

      before { allow(transaction_repository).to receive(:find_by_id).with(1).and_return(pending_transaction) }

      it 'returns Failure' do
        result = use_case.call(params: valid_params)
        expect(result).to be_failure
        expect(result.failure).to include('approved')
      end
    end

    context 'with invalid delivery params' do
      before { allow(transaction_repository).to receive(:find_by_id).with(1).and_return(approved_transaction) }

      let(:invalid_params) { { transaction_id: 1, address: '', estimated_date: nil } }

      it 'returns Failure with validation errors' do
        result = use_case.call(params: invalid_params)
        expect(result).to be_failure
      end
    end
  end
end
