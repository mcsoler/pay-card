# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/domain/entities/customer'

RSpec.describe Domain::Entities::Customer do
  subject(:customer) do
    described_class.new(
      id:      1,
      name:    'Juan Pérez',
      email:   'juan@example.com',
      address: 'Calle 123, Bogotá',
      phone:   '+573001234567'
    )
  end

  describe '#initialize' do
    it 'creates customer with all attributes' do
      expect(customer.name).to eq('Juan Pérez')
      expect(customer.email).to eq('juan@example.com')
      expect(customer.address).to eq('Calle 123, Bogotá')
    end
  end

  describe '#valid?' do
    it 'is valid with correct data' do
      expect(customer.valid?).to be true
    end

    it 'is invalid with blank name' do
      c = described_class.new(id: nil, name: '', email: 'a@b.com', address: 'Addr', phone: '')
      expect(c.valid?).to be false
    end

    it 'is invalid with malformed email' do
      c = described_class.new(id: nil, name: 'Test', email: 'not-an-email', address: 'Addr', phone: '')
      expect(c.valid?).to be false
    end

    it 'is invalid with blank address' do
      c = described_class.new(id: nil, name: 'Test', email: 'a@b.com', address: '', phone: '')
      expect(c.valid?).to be false
    end
  end

  describe '#errors' do
    it 'returns an array of error messages' do
      c = described_class.new(id: nil, name: '', email: 'bad', address: '', phone: '')
      c.valid?
      expect(c.errors).to include('Name is required', 'Email is invalid', 'Address is required')
    end
  end
end
