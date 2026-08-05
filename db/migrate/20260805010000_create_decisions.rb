class CreateDecisions < ActiveRecord::Migration[8.1]
  def change
    create_table :decisions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :public_id, null: false
      t.string :question, null: false
      t.text :description
      t.datetime :deadline
      t.datetime :closed_at
      t.text :final_statement
      t.boolean :options_open, null: false, default: true
      t.timestamps
    end
    add_index :decisions, :public_id, unique: true

    create_table :decision_options do |t|
      t.references :decision, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.timestamps
    end

    create_table :decision_votes do |t|
      t.references :decision, null: false, foreign_key: true
      t.references :decision_option, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :accepted, null: false, default: false
      t.boolean :preferred, null: false, default: false
      t.timestamps
    end
    add_index :decision_votes, %i[decision_option_id user_id], unique: true
  end
end
