# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/domain/use_cases/get_product'
require_relative '../../../app/domain/entities/product'

RSpec.describe Domain::UseCases::GetProduct do
  let(:product_repository) { instance_double('Domain::Ports::ProductRepository') }
  subject(:use_case) { described_class.new(product_repository: product_repository) }

  let(:product) do
    Domain::Entities::Product.new(id: 1, name: 'MacBook', description: 'Laptop', price: 8_999_000, stock: 5, base_fee: 269_970, delivery_fee: 50_000)
  end

  describe '#call' do
    context 'when product exists' do
      before { allow(product_repository).to receive(:find_by_id).with(1).and_return(product) }

      it 'returns Success with the product' do
        result = use_case.call(id: 1)
        expect(result).to be_success
        expect(result.value!).to eq(product)
      end
    end

    context 'when product does not exist' do
      before { allow(product_repository).to receive(:find_by_id).with(99).and_return(nil) }

      it 'returns Failure with not found message' do
        result = use_case.call(id: 99)
        expect(result).to be_failure
        expect(result.failure).to include('not found')
      end
    end
  end
end
