# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:deliveries) do
      primary_key :id
      foreign_key :transaction_id, :transactions, null: false
      String   :status,         null: false, default: 'PENDING', size: 50
      String   :address,        null: false, size: 500
      Date     :estimated_date
      DateTime :created_at,     null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at,     null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table(:deliveries)
  end
end
