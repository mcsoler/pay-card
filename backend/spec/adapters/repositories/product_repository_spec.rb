# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/adapters/repositories/product_repository'
require_relative '../../../app/infrastructure/database/connection'

RSpec.describe Adapters::Repositories::ProductRepository do
  subject(:repo) { described_class.new(db: DB) }

  let(:product_attrs) do
    {
      name:         'MacBook Pro',
      description:  'Laptop Apple',
      price:        8_999_000,
      stock:        10,
      base_fee:     269_970,
      delivery_fee: 50_000
    }
  end

  describe '#all' do
    before do
      DB[:products].insert(product_attrs.merge(created_at: Time.now, updated_at: Time.now))
    end

    it 'returns an array of Product entities' do
      result = repo.all
      expect(result).to be_an(Array)
      expect(result.first).to be_a(Domain::Entities::Product)
    end

    it 'includes the seeded product' do
      result = repo.all
      expect(result.map(&:name)).to include('MacBook Pro')
    end
  end

  describe '#find_by_id' do
    let!(:id) { DB[:products].insert(product_attrs.merge(created_at: Time.now, updated_at: Time.now)) }

    it 'returns a Product entity for a valid id' do
      product = repo.find_by_id(id)
      expect(product).to be_a(Domain::Entities::Product)
      expect(product.id).to eq(id)
      expect(product.name).to eq('MacBook Pro')
    end

    it 'returns nil for non-existent id' do
      expect(repo.find_by_id(999_999)).to be_nil
    end
  end

  describe '#update_stock' do
    let!(:id) { DB[:products].insert(product_attrs.merge(created_at: Time.now, updated_at: Time.now)) }

    it 'updates the stock for the given product' do
      repo.update_stock(id, 5)
      product = repo.find_by_id(id)
      expect(product.stock).to eq(5)
    end
  end
end
