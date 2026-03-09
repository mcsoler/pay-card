# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:default)

require_relative 'app/infrastructure/database/connection'
require_relative 'app/adapters/controllers/application_controller'
require_relative 'app/adapters/controllers/products_controller'
require_relative 'app/adapters/controllers/customers_controller'
require_relative 'app/adapters/controllers/transactions_controller'
require_relative 'app/adapters/controllers/deliveries_controller'
require_relative 'app/adapters/controllers/webhooks_controller'

use Rack::Cors do
  allow do
    origins ENV.fetch('ALLOWED_ORIGINS', '*')
    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head]
  end
end

map '/api' do
  run Rack::URLMap.new(
    '/products'     => ProductsController,
    '/customers'    => CustomersController,
    '/transactions' => TransactionsController,
    '/deliveries'   => DeliveriesController,
    '/webhooks'     => WebhooksController
  )
end
