# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/domain/entities/transaction'

RSpec.describe Domain::Entities::Transaction do
  subject(:transaction) do
    described_class.new(
      id:                   1,
      product_id:           1,
      customer_id:          1,
      amount:               9_318_970,
      status:               'PENDING',
      wompi_transaction_id: nil,
      created_at:           Time.now,
      updated_at:           Time.now
    )
  end

  describe '#pending?' do
    it 'returns true when status is PENDING' do
      expect(transaction.pending?).to be true
    end

    it 'returns false when status is APPROVED' do
      t = described_class.new(**transaction.to_h.merge(status: 'APPROVED'))
      expect(t.pending?).to be false
    end
  end

  describe '#approved?' do
    it 'returns false for PENDING' do
      expect(transaction.approved?).to be false
    end

    it 'returns true for APPROVED' do
      t = described_class.new(**transaction.to_h.merge(status: 'APPROVED'))
      expect(t.approved?).to be true
    end
  end

  describe '#declined?' do
    it 'returns true for DECLINED' do
      t = described_class.new(**transaction.to_h.merge(status: 'DECLINED'))
      expect(t.declined?).to be true
    end
  end

  describe '#approve!' do
    it 'changes status to APPROVED and sets wompi_transaction_id' do
      transaction.approve!(wompi_id: 'wompi-123')
      expect(transaction.status).to eq('APPROVED')
      expect(transaction.wompi_transaction_id).to eq('wompi-123')
    end
  end

  describe '#decline!' do
    it 'changes status to DECLINED' do
      transaction.decline!(wompi_id: 'wompi-456')
      expect(transaction.status).to eq('DECLINED')
    end
  end

  describe '#valid?' do
    it 'is valid with all required attributes' do
      expect(transaction.valid?).to be true
    end

    it 'is invalid without product_id' do
      t = described_class.new(**transaction.to_h.merge(product_id: nil))
      expect(t.valid?).to be false
    end

    it 'is invalid without customer_id' do
      t = described_class.new(**transaction.to_h.merge(customer_id: nil))
      expect(t.valid?).to be false
    end

    it 'is invalid with non-positive amount' do
      t = described_class.new(**transaction.to_h.merge(amount: 0))
      expect(t.valid?).to be false
    end

    it 'is invalid with unknown status' do
      t = described_class.new(**transaction.to_h.merge(status: 'UNKNOWN'))
      expect(t.valid?).to be false
    end
  end
end
