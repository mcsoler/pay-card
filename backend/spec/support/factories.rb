# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    name        { Faker::Commerce.product_name }
    description { Faker::Lorem.sentence }
    price       { Faker::Commerce.price(range: 10_000..500_000) }
    stock       { Faker::Number.between(from: 1, to: 100) }
    base_fee    { 5_000 }
    delivery_fee { 10_000 }
  end

  factory :customer do
    name    { Faker::Name.full_name }
    email   { Faker::Internet.unique.email }
    address { Faker::Address.full_address }
    phone   { Faker::PhoneNumber.cell_phone_in_e164 }
  end

  factory :transaction do
    association :product
    association :customer
    amount      { Faker::Commerce.price(range: 10_000..500_000) }
    status      { 'PENDING' }
    wompi_transaction_id { nil }
  end

  factory :delivery do
    association :transaction
    status         { 'PENDING' }
    address        { Faker::Address.full_address }
    estimated_date { Faker::Date.forward(days: 5) }
  end
end
