class CreateRideClaims < ActiveRecord::Migration[8.1]
  def change
    create_table :ride_claims do |t|
      t.references :ride, null: false, foreign_key: true
      t.string :name, null: false
      t.string :contact
      t.timestamps
    end
  end
end
