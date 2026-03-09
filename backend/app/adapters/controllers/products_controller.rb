# frozen_string_literal: true

require_relative 'application_controller'
require_relative '../../domain/use_cases/get_products'
require_relative '../../domain/use_cases/get_product'
require_relative '../repositories/product_repository'

class ProductsController < ApplicationController
  class << self
    def get_products_use_case
      @get_products_use_case ||= Domain::UseCases::GetProducts.new(
        product_repository: Adapters::Repositories::ProductRepository.new(db: DB)
      )
    end

    def get_product_use_case
      @get_product_use_case ||= Domain::UseCases::GetProduct.new(
        product_repository: Adapters::Repositories::ProductRepository.new(db: DB)
      )
    end
  end

  get '/' do
    result = self.class.get_products_use_case.call

    if result.success?
      success(result.value!.map { |p| serialize_product(p) })
    else
      halt 500, json(error: result.failure)
    end
  end

  get '/:id' do
    result = self.class.get_product_use_case.call(id: params[:id].to_i)

    if result.success?
      success(serialize_product(result.value!))
    else
      halt 404, json(error: result.failure)
    end
  end

  put '/:id/stock' do
    authenticate!
    product_repo = Adapters::Repositories::ProductRepository.new(db: DB)
    product_repo.update_stock(params[:id].to_i, parsed_body[:stock].to_i)
    success({ updated: true })
  end

  private

  def serialize_product(p)
    {
      id:           p.id,
      name:         p.name,
      description:  p.description,
      price:        p.price,
      stock:        p.stock,
      base_fee:     p.base_fee,
      delivery_fee: p.delivery_fee,
      total_amount: p.total_amount,
      available:    p.available?
    }
  end
end
