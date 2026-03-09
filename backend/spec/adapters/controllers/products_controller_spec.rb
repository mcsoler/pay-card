# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require_relative '../../../app/adapters/controllers/products_controller'

RSpec.describe ProductsController do
  include Rack::Test::Methods

  def app = ProductsController

  let(:products_data) do
    [
      Domain::Entities::Product.new(id: 1, name: 'MacBook', description: 'Laptop', price: 8_999_000, stock: 5, base_fee: 269_970, delivery_fee: 50_000),
      Domain::Entities::Product.new(id: 2, name: 'iPhone', description: 'Phone', price: 4_599_000, stock: 0, base_fee: 137_970, delivery_fee: 30_000)
    ]
  end

  let(:get_products_use_case)  { instance_double(Domain::UseCases::GetProducts) }
  let(:get_product_use_case)   { instance_double(Domain::UseCases::GetProduct) }

  before do
    allow(ProductsController).to receive(:get_products_use_case).and_return(get_products_use_case)
    allow(ProductsController).to receive(:get_product_use_case).and_return(get_product_use_case)
  end

  describe 'GET /' do
    context 'when products exist' do
      before do
        allow(get_products_use_case).to receive(:call).and_return(Dry::Monads::Success(products_data))
      end

      it 'returns 200 with products array' do
        get '/'
        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)
        expect(body['data']).to be_an(Array)
        expect(body['data'].size).to eq(2)
      end

      it 'includes total_amount in each product' do
        get '/'
        body = JSON.parse(last_response.body)
        expect(body['data'].first).to have_key('total_amount')
      end
    end

    context 'when use case fails' do
      before { allow(get_products_use_case).to receive(:call).and_return(Dry::Monads::Failure('DB error')) }

      it 'returns 500' do
        get '/'
        expect(last_response.status).to eq(500)
      end
    end
  end

  describe 'GET /:id' do
    context 'when product exists' do
      before do
        allow(get_product_use_case).to receive(:call).with(id: 1).and_return(Dry::Monads::Success(products_data.first))
      end

      it 'returns 200 with product data' do
        get '/1'
        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)
        expect(body['data']['name']).to eq('MacBook')
      end
    end

    context 'when product not found' do
      before do
        allow(get_product_use_case).to receive(:call).with(id: 99).and_return(Dry::Monads::Failure('Product not found'))
      end

      it 'returns 404' do
        get '/99'
        expect(last_response.status).to eq(404)
      end
    end
  end
end
