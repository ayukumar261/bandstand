# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:applications) do
      primary_key :id
      foreign_key :job_id, :jobs, null: false, on_delete: :cascade
      String   :name,       null: false
      String   :phone
      String   :email,      null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index :job_id
    end
  end
end
