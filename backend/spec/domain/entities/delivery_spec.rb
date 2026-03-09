# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/domain/entities/delivery'

RSpec.describe Domain::Entities::Delivery do
  subject(:delivery) do
    described_class.new(
      id:             1,
      transaction_id: 1,
      status:         'PENDING',
      address:        'Calle 123, Bogotá',
      estimated_date: Date.today + 5
    )
  end

  describe '#initialize' do
    it 'creates delivery with all attributes' do
      expect(delivery.status).to eq('PENDING')
      expect(delivery.address).to eq('Calle 123, Bogotá')
    end
  end

  describe '#valid?' do
    it 'is valid with correct data' do
      expect(delivery.valid?).to be true
    end

    it 'is invalid without address' do
      d = described_class.new(id: nil, transaction_id: 1, status: 'PENDING', address: '', estimated_date: nil)
      expect(d.valid?).to be false
    end

    it 'is invalid without transaction_id' do
      d = described_class.new(id: nil, transaction_id: nil, status: 'PENDING', address: 'Addr', estimated_date: nil)
      expect(d.valid?).to be false
    end
  end
end
