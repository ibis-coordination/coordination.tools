class CreateRides < ActiveRecord::Migration[8.1]
  def change
    create_table :rides do |t|
      t.references :carpool, null: false, foreign_key: true
      t.string :role, null: false
      t.string :name, null: false
      t.string :origin, null: false
      t.datetime :departure_time
      t.integer :seats, null: false, default: 1
      t.string :contact
      t.text :notes
      t.string :edit_token, null: false
      t.timestamps
    end
    add_index :rides, :edit_token, unique: true
  end
end
