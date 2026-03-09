# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'
require 'json'
require 'digest'
require_relative '../../domain/ports/payment_gateway'
require_relative '../../domain/errors'

module Adapters
  module Http
    class WompiClient
      include Domain::Ports::PaymentGateway

      def initialize(api_url: nil, private_key: nil, public_key: nil, integrity_secret: nil)
        @api_url          = api_url          || ENV.fetch('WOMPI_API_URL', 'https://api-sandbox.co.uat.wompi.dev/v1')
        @private_key      = private_key      || ENV.fetch('WOMPI_PRIVATE_KEY')
        @public_key       = public_key       || ENV.fetch('WOMPI_PUBLIC_KEY')
        @integrity_secret = integrity_secret || ENV.fetch('WOMPI_INTEGRITY_SECRET')
      end

      def transaction_status(wompi_id)
        response = connection.get("/v1/transactions/#{wompi_id}")
        handle_response(response)
      rescue Faraday::Error => e
        raise Domain::Errors::PaymentError, "Payment gateway error: #{e.message}"
      end

      def charge(amount:, card_token:, customer_email:, installments:, reference:)
        amount_in_cents  = amount.to_i
        acceptance_token = fetch_acceptance_token
        integrity_sig    = build_integrity_signature(reference, amount_in_cents, 'COP')

        payload = build_payload(
          amount_in_cents:  amount_in_cents,
          card_token:       card_token,
          customer_email:   customer_email,
          installments:     installments,
          reference:        reference,
          acceptance_token: acceptance_token,
          integrity:        integrity_sig
        )

        response = connection.post('/v1/transactions') do |req|
          req.body = payload.to_json
        end

        handle_response(response)
      rescue Faraday::Error => e
        raise Domain::Errors::PaymentError, "Payment gateway error: #{e.message}"
      end

      private

      def connection
        @connection ||= Faraday.new(url: @api_url) do |f|
          f.request  :json
          f.response :json
          f.request  :retry, max: 2, interval: 0.5, exceptions: [Faraday::TimeoutError]
          f.adapter  Faraday.default_adapter
          f.headers['Authorization'] = "Bearer #{@private_key}"
          f.headers['Content-Type']  = 'application/json'
        end
      end

      def public_connection
        @public_connection ||= Faraday.new(url: @api_url) do |f|
          f.response :json
          f.adapter  Faraday.default_adapter
        end
      end

      # Wompi requires an acceptance_token from the merchant endpoint
      def fetch_acceptance_token
        response = public_connection.get("/v1/merchants/#{@public_key}")
        data     = response.body.is_a?(Hash) ? response.body : JSON.parse(response.body)
        data.dig('data', 'presigned_acceptance', 'acceptance_token')
      rescue StandardError
        nil
      end

      # SHA256(reference + amount_in_cents + currency + integrity_secret)
      def build_integrity_signature(reference, amount_in_cents, currency)
        raw = "#{reference}#{amount_in_cents}#{currency}#{@integrity_secret}"
        Digest::SHA256.hexdigest(raw)
      end

      def build_payload(amount_in_cents:, card_token:, customer_email:, installments:,
                        reference:, acceptance_token:, integrity:)
        {
          amount_in_cents:  amount_in_cents,
          currency:         'COP',
          customer_email:   customer_email,
          reference:        reference,
          acceptance_token: acceptance_token,
          signature:        integrity,
          payment_method: {
            type:         'CARD',
            token:        card_token,
            installments: installments
          }
        }
      end

      def handle_response(response)
        unless response.success?
          raise Domain::Errors::PaymentError, "Wompi error #{response.status}: #{response.body}"
        end

        data             = response.body.is_a?(Hash) ? response.body : JSON.parse(response.body)
        transaction_data = data['data'] || data

        {
          id:     transaction_data['id'],
          status: transaction_data['status']
        }
      end
    end
  end
end
