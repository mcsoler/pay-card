# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/domain/use_cases/update_transaction'
require_relative '../../../app/domain/entities/transaction'

RSpec.describe Domain::UseCases::UpdateTransaction do
  let(:transaction_repository) { instance_double('Domain::Ports::TransactionRepository') }
  let(:product_repository)     { instance_double('Domain::Ports::ProductRepository') }

  subject(:use_case) do
    described_class.new(
      transaction_repository: transaction_repository,
      product_repository:     product_repository
    )
  end

  let(:pending_transaction) do
    Domain::Entities::Transaction.new(
      id: 1, product_id: 1, customer_id: 2,
      amount: 9_318_970, status: 'PENDING',
      wompi_transaction_id: nil, created_at: Time.now, updated_at: Time.now
    )
  end

  describe '#call' do
    context 'when updating PENDING to APPROVED' do
      before do
        allow(transaction_repository).to receive(:find_by_id).with(1).and_return(pending_transaction)
        allow(transaction_repository).to receive(:update).and_return(true)
        allow(product_repository).to receive(:find_by_id).with(1).and_return(
          Domain::Entities::Product.new(id: 1, name: 'M', description: '', price: 100, stock: 5, base_fee: 0, delivery_fee: 0)
        )
        allow(product_repository).to receive(:update_stock).and_return(true)
      end

      it 'returns Success with updated transaction' do
        result = use_case.call(id: 1, params: { status: 'APPROVED', wompi_transaction_id: 'w-123' })
        expect(result).to be_success
      end
    end

    context 'when transaction is already APPROVED (idempotent)' do
      let(:approved_transaction) do
        Domain::Entities::Transaction.new(
          id: 1, product_id: 1, customer_id: 2,
          amount: 9_318_970, status: 'APPROVED',
          wompi_transaction_id: 'w-existing', created_at: Time.now, updated_at: Time.now
        )
      end

      before { allow(transaction_repository).to receive(:find_by_id).with(1).and_return(approved_transaction) }

      it 'returns Success without double-processing' do
        result = use_case.call(id: 1, params: { status: 'APPROVED', wompi_transaction_id: 'w-123' })
        expect(result).to be_success
        expect(product_repository).not_to receive(:update_stock)
      end
    end

    context 'when transaction does not exist' do
      before { allow(transaction_repository).to receive(:find_by_id).with(99).and_return(nil) }

      it 'returns Failure' do
        result = use_case.call(id: 99, params: { status: 'APPROVED' })
        expect(result).to be_failure
      end
    end
  end
end
