# frozen_string_literal: true

require 'jwt'

module Infrastructure
  module Jwt
    class JwtService
      ALGORITHM = 'HS256'

      def initialize(secret: ENV.fetch('JWT_SECRET', 'default_secret'), expiration_hours: nil)
        @secret           = secret
        @expiration_hours = expiration_hours || ENV.fetch('JWT_EXPIRATION_HOURS', 24).to_i
      end

      def encode(payload)
        claims = payload.merge(
          exp: Time.now.to_i + (@expiration_hours * 3600),
          iat: Time.now.to_i
        )
        JWT.encode(claims, @secret, ALGORITHM)
      end

      def decode(token)
        payload, = JWT.decode(token, @secret, true, { algorithm: ALGORITHM })
        payload
      rescue JWT::DecodeError, JWT::ExpiredSignature
        nil
      end
    end
  end
end
