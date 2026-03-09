# frozen_string_literal: true

require_relative 'connection'

puts 'Seeding products...'

products = [
  {
    name:         'MacBook Pro M3 14"',
    description:  'Laptop profesional Apple con chip M3, 16GB RAM, 512GB SSD. ' \
                  'Pantalla Liquid Retina XDR de 14.2". Batería de hasta 18 horas.',
    price:        8_999_000,
    stock:        10,
    base_fee:     269_970,
    delivery_fee: 50_000
  },
  {
    name:         'iPhone 15 Pro 256GB',
    description:  'Smartphone Apple con chip A17 Pro, cámara de 48MP con zoom óptico 5x. ' \
                  'Titanio grado aeroespacial. iOS 17.',
    price:        4_599_000,
    stock:        25,
    base_fee:     137_970,
    delivery_fee: 30_000
  },
  {
    name:         'Sony WH-1000XM5',
    description:  'Auriculares inalámbricos con cancelación de ruido líder en la industria. ' \
                  'Autonomía de 30 horas. Micrófono con IA para llamadas cristalinas.',
    price:        1_199_000,
    stock:        50,
    base_fee:     35_970,
    delivery_fee: 20_000
  },
  {
    name:         'Samsung Galaxy Tab S9 Ultra',
    description:  'Tablet premium con pantalla AMOLED 14.6", S Pen incluido, ' \
                  '12GB RAM, 256GB almacenamiento. IP68 resistente al agua.',
    price:        3_499_000,
    stock:        15,
    base_fee:     104_970,
    delivery_fee: 40_000
  },
  {
    name:         'LG UltraWide 34" QHD',
    description:  'Monitor ultrawide curvo 34" con resolución QHD 3440x1440, ' \
                  '144Hz, HDR10, compatible con AMD FreeSync Premium.',
    price:        2_299_000,
    stock:        8,
    base_fee:     68_970,
    delivery_fee: 35_000
  }
]

now = Time.now

products.each do |product|
  exists = DB[:products].where(name: product[:name]).first
  if exists
    puts "  - Skipping (already exists): #{product[:name]}"
  else
    DB[:products].insert(product.merge(created_at: now, updated_at: now))
    puts "  + Seeded: #{product[:name]}"
  end
end

puts "Done. #{DB[:products].count} products in database."
