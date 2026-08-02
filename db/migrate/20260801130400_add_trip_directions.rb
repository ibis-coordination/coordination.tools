class AddTripDirections < ActiveRecord::Migration[8.1]
  def change
    add_column :carpools, :return_starts_at, :datetime
    add_column :rides, :direction, :string, null: false, default: "outbound"
    add_column :ride_claims, :direction, :string, null: false, default: "outbound"

    remove_index :rides, %i[carpool_id user_id]
    remove_index :ride_claims, %i[carpool_id user_id]
    add_index :rides, %i[carpool_id user_id direction], unique: true
    add_index :ride_claims, %i[carpool_id user_id direction], unique: true
  end
end
