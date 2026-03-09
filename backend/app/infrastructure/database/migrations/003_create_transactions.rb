# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:transactions) do
      primary_key :id
      foreign_key :product_id,  :products,  null: false
      foreign_key :customer_id, :customers, null: false
      Numeric :amount,                 null: false, size: [12, 2]
      String  :status,                 null: false, default: 'PENDING', size: 50
      String  :wompi_transaction_id,   size: 255
      DateTime :created_at,            null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at,            null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table(:transactions)
  end
end
