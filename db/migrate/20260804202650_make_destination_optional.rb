class MakeDestinationOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :carpools, :destination, true
  end
end
