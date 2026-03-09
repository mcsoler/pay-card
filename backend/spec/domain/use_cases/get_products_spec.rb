# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/domain/use_cases/get_products'
require_relative '../../../app/domain/entities/product'

RSpec.describe Domain::UseCases::GetProducts do
  let(:product_repository) { instance_double('Domain::Ports::ProductRepository') }
  subject(:use_case) { described_class.new(product_repository: product_repository) }

  let(:products) do
    [
      Domain::Entities::Product.new(id: 1, name: 'MacBook', description: 'Laptop', price: 8_999_000, stock: 5, base_fee: 269_970, delivery_fee: 50_000),
      Domain::Entities::Product.new(id: 2, name: 'iPhone', description: 'Phone', price: 4_599_000, stock: 0, base_fee: 137_970, delivery_fee: 30_000)
    ]
  end

  describe '#call' do
    before { allow(product_repository).to receive(:all).and_return(products) }

    it 'returns a Success result with all products' do
      result = use_case.call
      expect(result).to be_success
      expect(result.value!).to eq(products)
    end

    it 'returns both available and unavailable products' do
      result = use_case.call
      expect(result.value!.size).to eq(2)
    end

    context 'when the repository raises an error' do
      before { allow(product_repository).to receive(:all).and_raise(StandardError, 'DB error') }

      it 'returns a Failure result' do
        result = use_case.call
        expect(result).to be_failure
        expect(result.failure).to include('DB error')
      end
    end
  end
end
