class DecisionVotesController < ApplicationController
  before_action :require_user

  def create
    decision = Decision.find_by!(public_id: params[:decision_public_id])
    raise ActiveRecord::RecordInvalid, decision if decision.closed?

    accepted = Array(params[:accepted_option_ids]).map(&:to_i)
    preferred = Array(params[:preferred_option_ids]).map(&:to_i)
    valid_ids = decision.decision_options.pluck(:id)
    accepted &= valid_ids
    preferred &= accepted

    DecisionVote.transaction do
      decision.decision_votes.where(user: current_user).delete_all
      valid_ids.each do |option_id|
        DecisionVote.create!(decision:, user: current_user, decision_option_id: option_id,
          accepted: accepted.include?(option_id), preferred: preferred.include?(option_id))
      end
    end
    redirect_to decision_path(decision), notice: "Your vote was recorded."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to decision_path(decision), alert: e.record.errors.full_messages.to_sentence.presence || "This decision is closed."
  end
end
