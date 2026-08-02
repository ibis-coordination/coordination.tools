class CreateCarpools < ActiveRecord::Migration[8.1]
  def change
    create_table :carpools do |t|
      t.string :public_id, null: false
      t.string :name, null: false
      t.string :destination, null: false
      t.datetime :starts_at, null: false
      t.text :details
      t.timestamps
    end
    add_index :carpools, :public_id, unique: true
  end
end
