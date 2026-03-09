# frozen_string_literal: true

require_relative 'application_controller'
require_relative '../../domain/use_cases/create_transaction'
require_relative '../../domain/use_cases/process_payment'
require_relative '../../domain/use_cases/update_transaction'
require_relative '../repositories/transaction_repository'
require_relative '../repositories/product_repository'
require_relative '../http/wompi_client'

class TransactionsController < ApplicationController
  class << self
    def create_transaction_use_case
      @create_transaction_use_case ||= Domain::UseCases::CreateTransaction.new(
        product_repository:     Adapters::Repositories::ProductRepository.new(db: DB),
        transaction_repository: Adapters::Repositories::TransactionRepository.new(db: DB)
      )
    end

    def process_payment_use_case
      @process_payment_use_case ||= Domain::UseCases::ProcessPayment.new(
        transaction_repository: Adapters::Repositories::TransactionRepository.new(db: DB),
        product_repository:     Adapters::Repositories::ProductRepository.new(db: DB),
        payment_gateway:        Adapters::Http::WompiClient.new(
          public_key:       ENV.fetch('WOMPI_PUBLIC_KEY'),
          integrity_secret: ENV.fetch('WOMPI_INTEGRITY_SECRET')
        )
      )
    end

    def update_transaction_use_case
      @update_transaction_use_case ||= Domain::UseCases::UpdateTransaction.new(
        transaction_repository: Adapters::Repositories::TransactionRepository.new(db: DB),
        product_repository:     Adapters::Repositories::ProductRepository.new(db: DB)
      )
    end
  end

  # POST /api/transactions — create transaction + process payment with Wompi
  post '/' do
    authenticate!

    body_params = parsed_body.merge(customer_id: current_customer_id)

    # Step 1: Create PENDING transaction
    tx_result = self.class.create_transaction_use_case.call(params: body_params)
    unless tx_result.success?
      error_msg = tx_result.failure
      status_code = error_msg.to_s.include?('stock') ? 422 : 400
      halt status_code, json(error: error_msg)
    end

    transaction = tx_result.value!

    # Step 2: Charge via Wompi
    pay_result = self.class.process_payment_use_case.call(
      params: {
        transaction_id: transaction.id,
        card_token:     body_params[:card_token],
        installments:   body_params[:installments] || 1,
        customer_email: body_params[:customer_email]
      }
    )

    if pay_result.success?
      success(pay_result.value!, status: 201)
    else
      halt 422, json(error: pay_result.failure)
    end
  end

  # PUT /api/transactions/:id — update transaction (from frontend or webhook)
  put '/:id' do
    authenticate!

    result = self.class.update_transaction_use_case.call(
      id:     params[:id].to_i,
      params: parsed_body
    )

    if result.success?
      success(serialize_transaction(result.value!))
    else
      error_msg = result.failure
      status_code = error_msg.to_s.include?('not found') ? 404 : 400
      halt status_code, json(error: error_msg)
    end
  end

  private

  def serialize_transaction(t)
    {
      id:                   t.id,
      product_id:           t.product_id,
      customer_id:          t.customer_id,
      amount:               t.amount,
      status:               t.status,
      wompi_transaction_id: t.wompi_transaction_id,
      created_at:           t.created_at,
      updated_at:           t.updated_at
    }
  end
end
