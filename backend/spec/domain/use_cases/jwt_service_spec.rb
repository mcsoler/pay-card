# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/infrastructure/jwt/jwt_service'

RSpec.describe Infrastructure::Jwt::JwtService do
  subject(:service) { described_class.new(secret: 'test_secret', expiration_hours: 1) }

  describe '#encode' do
    it 'returns a non-empty JWT string' do
      token = service.encode({ customer_id: 42 })
      expect(token).to be_a(String)
      expect(token.split('.').size).to eq(3)
    end
  end

  describe '#decode' do
    it 'decodes a valid token and returns the payload' do
      token = service.encode({ customer_id: 42 })
      payload = service.decode(token)
      expect(payload['customer_id']).to eq(42)
    end

    it 'returns nil for an expired token' do
      expired_service = described_class.new(secret: 'test_secret', expiration_hours: -1)
      token = expired_service.encode({ customer_id: 1 })
      expect(service.decode(token)).to be_nil
    end

    it 'returns nil for a tampered token' do
      expect(service.decode('invalid.token.here')).to be_nil
    end
  end
end
