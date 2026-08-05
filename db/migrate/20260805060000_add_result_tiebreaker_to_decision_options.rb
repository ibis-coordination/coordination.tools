class AddResultTiebreakerToDecisionOptions < ActiveRecord::Migration[8.1]
  def change
    add_column :decision_options, :result_tiebreaker, :bigint
  end
end
