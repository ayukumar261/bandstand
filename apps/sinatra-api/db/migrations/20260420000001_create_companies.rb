# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:companies) do
      primary_key :id
      String   :name,       null: false
      String   :website
      String   :industry
      String   :location
      String   :size
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
