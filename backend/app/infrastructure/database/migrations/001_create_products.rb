# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:products) do
      primary_key :id
      String  :name,         null: false, size: 255
      Text    :description
      Numeric :price,        null: false, size: [12, 2]
      Integer :stock,        null: false, default: 0
      Numeric :base_fee,     null: false, size: [12, 2], default: 0
      Numeric :delivery_fee, null: false, size: [12, 2], default: 0
      DateTime :created_at,  null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at,  null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table(:products)
  end
end
