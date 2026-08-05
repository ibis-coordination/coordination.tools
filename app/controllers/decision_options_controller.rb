class DecisionOptionsController < ApplicationController
  before_action :require_user

  def create
    decision = Decision.find_by!(public_id: params[:decision_public_id])
    option = decision.decision_options.new(option_params.merge(user: current_user))
    if option.save
      redirect_to decision_path(decision), notice: "Option added."
    else
      redirect_to decision_path(decision), alert: option.errors.full_messages.to_sentence
    end
  end

  private

  def option_params = params.require(:decision_option).permit(:title)
end
