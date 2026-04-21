# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:jobs) do
      primary_key :id
      foreign_key :company_id, :companies, null: false, on_delete: :cascade
      String   :title,            null: false
      String   :description,      text: true
      String   :type,             null: false
      String   :location,         null: false
      DateTime :created_at,       null: false
      DateTime :updated_at,       null: false
      index :company_id
    end
  end
end
