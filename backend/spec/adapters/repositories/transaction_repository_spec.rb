# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/adapters/repositories/transaction_repository'
require_relative '../../../app/adapters/repositories/product_repository'
require_relative '../../../app/adapters/repositories/customer_repository'

RSpec.describe Adapters::Repositories::TransactionRepository do
  subject(:repo) { described_class.new(db: DB) }

  let(:product_id) do
    DB[:products].insert(
      name: 'Test', description: 'D', price: 100_000,
      stock: 5, base_fee: 3_000, delivery_fee: 5_000,
      created_at: Time.now, updated_at: Time.now
    )
  end

  let(:customer_id) do
    DB[:customers].insert(
      name: 'Test User', email: "test#{rand(9999)}@x.com",
      address: 'Addr', phone: '', created_at: Time.now, updated_at: Time.now
    )
  end

  let(:transaction_attrs) do
    { product_id: product_id, customer_id: customer_id, amount: 108_000, status: 'PENDING' }
  end

  describe '#create' do
    it 'returns a Transaction entity with PENDING status' do
      t = repo.create(transaction_attrs)
      expect(t).to be_a(Domain::Entities::Transaction)
      expect(t.status).to eq('PENDING')
      expect(t.id).not_to be_nil
    end
  end

  describe '#find_by_id' do
    let!(:transaction) { repo.create(transaction_attrs) }

    it 'returns a Transaction entity' do
      found = repo.find_by_id(transaction.id)
      expect(found).to be_a(Domain::Entities::Transaction)
      expect(found.amount.to_f).to eq(108_000.0)
    end

    it 'returns nil for unknown id' do
      expect(repo.find_by_id(999_999)).to be_nil
    end
  end

  describe '#update' do
    let!(:transaction) { repo.create(transaction_attrs) }

    it 'updates status and wompi_transaction_id' do
      repo.update(transaction.id, status: 'APPROVED', wompi_transaction_id: 'w-abc')
      updated = repo.find_by_id(transaction.id)
      expect(updated.status).to eq('APPROVED')
      expect(updated.wompi_transaction_id).to eq('w-abc')
    end
  end
end
