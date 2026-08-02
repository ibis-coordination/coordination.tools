class AddEmailIdentity < ActiveRecord::Migration[8.1]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class MigrationCarpool < ActiveRecord::Base
    self.table_name = "carpools"
  end

  class MigrationRide < ActiveRecord::Base
    self.table_name = "rides"
  end

  class MigrationClaim < ActiveRecord::Base
    self.table_name = "ride_claims"
  end

  def up
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true

    add_reference :carpools, :user, foreign_key: true
    add_reference :rides, :user, foreign_key: true
    add_reference :ride_claims, :user, foreign_key: true
    add_reference :ride_claims, :carpool, foreign_key: true
    add_column :ride_claims, :pickup_location, :string
    add_column :ride_claims, :seats, :integer, null: false, default: 1

    MigrationCarpool.find_each do |carpool|
      user = MigrationUser.create!(name: "Previous organizer", email: "carpool-#{carpool.id}@previous.invalid")
      carpool.update_columns(user_id: user.id)
    end
    MigrationRide.find_each do |ride|
      user = MigrationUser.create!(name: ride.name, email: "ride-#{ride.id}@previous.invalid")
      ride.update_columns(user_id: user.id)
    end
    MigrationClaim.find_each do |claim|
      ride = MigrationRide.find(claim.ride_id)
      user = MigrationUser.create!(name: claim.name, email: "claim-#{claim.id}@previous.invalid")
      claim.update_columns(user_id: user.id, carpool_id: ride.carpool_id, pickup_location: "Not provided")
    end

    change_column_null :carpools, :user_id, false
    change_column_null :rides, :user_id, false
    change_column_null :ride_claims, :user_id, false
    change_column_null :ride_claims, :carpool_id, false
    change_column_null :ride_claims, :pickup_location, false

    add_index :rides, %i[carpool_id user_id], unique: true
    add_index :ride_claims, %i[carpool_id user_id], unique: true

    remove_column :rides, :name
    remove_column :rides, :contact
    remove_column :rides, :edit_token
    remove_column :ride_claims, :name
    remove_column :ride_claims, :contact
  end

  def down
    add_column :rides, :name, :string, null: false, default: "Previous user"
    add_column :rides, :contact, :string
    add_column :rides, :edit_token, :string, null: false, default: "previous"
    add_column :ride_claims, :name, :string, null: false, default: "Previous user"
    add_column :ride_claims, :contact, :string
    remove_reference :ride_claims, :carpool
    remove_reference :ride_claims, :user
    remove_reference :rides, :user
    remove_reference :carpools, :user
    remove_column :ride_claims, :pickup_location
    remove_column :ride_claims, :seats
    drop_table :users
  end
end
