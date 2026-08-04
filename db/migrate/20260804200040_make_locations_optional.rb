class MakeLocationsOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :rides, :origin, true
    change_column_null :ride_claims, :pickup_location, true
  end
end
