class AddPendingEmailToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :pending_email, :string
  end
end
