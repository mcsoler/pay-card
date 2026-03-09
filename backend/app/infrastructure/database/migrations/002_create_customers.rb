# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:customers) do
      primary_key :id
      String   :name,    null: false, size: 255
      String   :email,   null: false, size: 255, unique: true
      String   :address, size: 500
      String   :phone,   size: 50
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table(:customers)
  end
end
