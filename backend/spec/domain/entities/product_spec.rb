# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/domain/entities/product'

RSpec.describe Domain::Entities::Product do
  subject(:product) do
    described_class.new(
      id:           1,
      name:         'MacBook Pro M3',
      description:  'Laptop Apple',
      price:        8_999_000,
      stock:        10,
      base_fee:     269_970,
      delivery_fee: 50_000
    )
  end

  describe '#initialize' do
    it 'creates a valid product with all attributes' do
      expect(product.id).to eq(1)
      expect(product.name).to eq('MacBook Pro M3')
      expect(product.price).to eq(8_999_000)
      expect(product.stock).to eq(10)
      expect(product.base_fee).to eq(269_970)
      expect(product.delivery_fee).to eq(50_000)
    end
  end

  describe '#available?' do
    context 'when stock is greater than zero' do
      it { is_expected.to be_available }
    end

    context 'when stock is zero' do
      subject(:product) { described_class.new(id: 1, name: 'Test', description: '', price: 100, stock: 0, base_fee: 0, delivery_fee: 0) }

      it { is_expected.not_to be_available }
    end
  end

  describe '#total_amount' do
    it 'returns price + base_fee + delivery_fee' do
      expect(product.total_amount).to eq(9_318_970)
    end
  end

  describe '#decrease_stock!' do
    it 'decrements stock by 1' do
      expect { product.decrease_stock! }.to change(product, :stock).from(10).to(9)
    end

    context 'when stock is zero' do
      subject(:product) { described_class.new(id: 1, name: 'Test', description: '', price: 100, stock: 0, base_fee: 0, delivery_fee: 0) }

      it 'raises Domain::Errors::InsufficientStockError' do
        expect { product.decrease_stock! }.to raise_error(Domain::Errors::InsufficientStockError)
      end
    end
  end

  describe '#valid?' do
    it 'is valid with all required attributes' do
      expect(product.valid?).to be true
    end

    it 'is invalid when name is blank' do
      p = described_class.new(id: 1, name: '', description: '', price: 100, stock: 1, base_fee: 0, delivery_fee: 0)
      expect(p.valid?).to be false
    end

    it 'is invalid when price is zero or negative' do
      p = described_class.new(id: 1, name: 'Test', description: '', price: 0, stock: 1, base_fee: 0, delivery_fee: 0)
      expect(p.valid?).to be false
    end

    it 'is invalid when stock is negative' do
      p = described_class.new(id: 1, name: 'Test', description: '', price: 100, stock: -1, base_fee: 0, delivery_fee: 0)
      expect(p.valid?).to be false
    end
  end
end
