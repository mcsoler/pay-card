# frozen_string_literal: true

require 'digest'
require_relative 'application_controller'
require_relative '../../domain/use_cases/update_transaction'
require_relative '../repositories/transaction_repository'
require_relative '../repositories/product_repository'

class WebhooksController < ApplicationController
  # POST /api/webhooks/wompi
  post '/wompi' do
    payload = parsed_body

    halt 400, json(error: 'Invalid payload') unless valid_wompi_signature?(payload)

    event_data = payload[:data] || payload['data'] || {}
    tx_data    = event_data[:transaction] || event_data['transaction'] || {}

    wompi_id = tx_data[:id]        || tx_data['id']
    status   = tx_data[:status]    || tx_data['status']
    ref      = tx_data[:reference] || tx_data['reference']

    halt 200, json(received: true) unless wompi_id && status

    transaction_id = ref.to_s.split('-')[1]&.to_i
    halt 200, json(received: true) unless transaction_id

    use_case = Domain::UseCases::UpdateTransaction.new(
      transaction_repository: Adapters::Repositories::TransactionRepository.new(db: DB),
      product_repository:     Adapters::Repositories::ProductRepository.new(db: DB)
    )

    use_case.call(id: transaction_id, params: { status: status, wompi_transaction_id: wompi_id })

    status 200
    json(received: true)
  end

  private

  def valid_wompi_signature?(payload)
    events_secret = ENV.fetch('WOMPI_EVENTS_SECRET', '')
    return true if events_secret.empty?

    checksum  = payload[:checksum] || payload['checksum'] || ''
    event_key = payload[:event]    || payload['event']    || ''
    timestamp  = payload[:timestamp] || payload['timestamp'] || ''

    properties = "#{timestamp}#{event_key}#{events_secret}"
    expected   = Digest::SHA256.hexdigest(properties)
    Rack::Utils.secure_compare(expected, checksum.to_s)
  end
end
