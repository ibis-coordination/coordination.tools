class CreateSeatOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :seat_offers do |t|
      t.references :ride, null: false, foreign_key: true
      t.references :carpool, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :declined_at

      t.timestamps
    end
    add_index :seat_offers, [ :ride_id, :user_id ], unique: true
  end
end
