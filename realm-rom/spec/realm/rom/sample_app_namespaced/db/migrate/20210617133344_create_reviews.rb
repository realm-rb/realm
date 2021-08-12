# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :reviews do
      primary_key :id
      String :text
    end
  end
end
