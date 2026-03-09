# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'
require 'json'
require_relative '../../domain/ports/payment_gateway'
require_relative '../../domain/errors'

module Adapters
  module Http
    class WompiClient
      include Domain::Ports::PaymentGateway

      def initialize(api_url: nil, private_key: nil)
        @api_url     = api_url     || ENV.fetch('WOMPI_API_URL', 'https://api-sandbox.co.uat.wompi.dev/v1')
        @private_key = private_key || ENV.fetch('WOMPI_PRIVATE_KEY')
      end

      def charge(amount:, card_token:, customer_email:, installments:, reference:)
        response = connection.post('/v1/transactions') do |req|
          req.body = build_payload(
            amount:         amount,
            card_token:     card_token,
            customer_email: customer_email,
            installments:   installments,
            reference:      reference
          ).to_json
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

      def build_payload(amount:, card_token:, customer_email:, installments:, reference:)
        {
          amount_in_cents:  (amount.to_f * 100).to_i,
          currency:         'COP',
          customer_email:   customer_email,
          reference:        reference,
          payment_method: {
            type:               'CARD',
            token:              card_token,
            installments:       installments
          }
        }
      end

      def handle_response(response)
        unless response.success?
          raise Domain::Errors::PaymentError, "Wompi error #{response.status}: #{response.body}"
        end

        data = response.body.is_a?(Hash) ? response.body : JSON.parse(response.body)
        transaction_data = data['data'] || data

        {
          id:     transaction_data['id'],
          status: transaction_data['status']
        }
      end
    end
  end
end
