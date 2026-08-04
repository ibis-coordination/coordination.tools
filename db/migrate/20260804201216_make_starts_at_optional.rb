class MakeStartsAtOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :carpools, :starts_at, true
  end
end
