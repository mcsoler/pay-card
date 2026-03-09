# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/domain/use_cases/create_transaction'
require_relative '../../../app/domain/entities/product'
require_relative '../../../app/domain/entities/customer'
require_relative '../../../app/domain/entities/transaction'

RSpec.describe Domain::UseCases::CreateTransaction do
  let(:product_repository)     { instance_double('Domain::Ports::ProductRepository') }
  let(:transaction_repository) { instance_double('Domain::Ports::TransactionRepository') }

  subject(:use_case) do
    described_class.new(
      product_repository:     product_repository,
      transaction_repository: transaction_repository
    )
  end

  let(:product) do
    Domain::Entities::Product.new(id: 1, name: 'MacBook', description: 'Laptop', price: 8_999_000, stock: 5, base_fee: 269_970, delivery_fee: 50_000)
  end

  let(:transaction) do
    Domain::Entities::Transaction.new(
      id: 1, product_id: 1, customer_id: 2,
      amount: 9_318_970, status: 'PENDING',
      wompi_transaction_id: nil, created_at: Time.now, updated_at: Time.now
    )
  end

  let(:valid_params) { { product_id: 1, customer_id: 2 } }

  describe '#call' do
    context 'when product is available' do
      before do
        allow(product_repository).to receive(:find_by_id).with(1).and_return(product)
        allow(transaction_repository).to receive(:create).and_return(transaction)
      end

      it 'returns Success with the PENDING transaction' do
        result = use_case.call(params: valid_params)
        expect(result).to be_success
        expect(result.value!.status).to eq('PENDING')
        expect(result.value!.amount).to eq(9_318_970)
      end

      it 'creates transaction with total_amount (price + fees)' do
        expect(transaction_repository).to receive(:create).with(
          hash_including(amount: product.total_amount, status: 'PENDING')
        ).and_return(transaction)
        use_case.call(params: valid_params)
      end
    end

    context 'when product does not exist' do
      before { allow(product_repository).to receive(:find_by_id).with(1).and_return(nil) }

      it 'returns Failure' do
        result = use_case.call(params: valid_params)
        expect(result).to be_failure
        expect(result.failure).to include('not found')
      end
    end

    context 'when product is out of stock' do
      let(:out_of_stock_product) do
        Domain::Entities::Product.new(id: 1, name: 'MacBook', description: 'Laptop', price: 8_999_000, stock: 0, base_fee: 269_970, delivery_fee: 50_000)
      end

      before { allow(product_repository).to receive(:find_by_id).with(1).and_return(out_of_stock_product) }

      it 'returns Failure with out of stock message' do
        result = use_case.call(params: valid_params)
        expect(result).to be_failure
        expect(result.failure).to include('stock')
      end
    end
  end
end
