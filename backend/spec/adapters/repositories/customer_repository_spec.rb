# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/adapters/repositories/customer_repository'

RSpec.describe Adapters::Repositories::CustomerRepository do
  subject(:repo) { described_class.new(db: DB) }

  let(:customer_attrs) do
    { name: 'Juan Pérez', email: 'juan@example.com', address: 'Calle 123', phone: '+573001234567' }
  end

  describe '#create' do
    it 'persists a customer and returns a Customer entity' do
      customer = repo.create(customer_attrs)
      expect(customer).to be_a(Domain::Entities::Customer)
      expect(customer.id).not_to be_nil
      expect(customer.email).to eq('juan@example.com')
    end
  end

  describe '#find_by_id' do
    let!(:customer) { repo.create(customer_attrs) }

    it 'returns a Customer entity for a valid id' do
      found = repo.find_by_id(customer.id)
      expect(found).to be_a(Domain::Entities::Customer)
      expect(found.name).to eq('Juan Pérez')
    end

    it 'returns nil for non-existent id' do
      expect(repo.find_by_id(999_999)).to be_nil
    end
  end

  describe '#find_by_email' do
    let!(:customer) { repo.create(customer_attrs) }

    it 'returns the customer with the matching email' do
      found = repo.find_by_email('juan@example.com')
      expect(found).to be_a(Domain::Entities::Customer)
      expect(found.id).to eq(customer.id)
    end

    it 'returns nil when email not found' do
      expect(repo.find_by_email('unknown@x.com')).to be_nil
    end
  end
end
