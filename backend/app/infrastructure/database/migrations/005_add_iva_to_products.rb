# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:products) do
      add_column :iva, Numeric, null: false, size: [12, 2], default: 0
    end
  end

  down do
    alter_table(:products) do
      drop_column :iva
    end
  end
end
