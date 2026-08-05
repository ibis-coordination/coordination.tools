class DecisionVote < ApplicationRecord
  belongs_to :decision
  belongs_to :decision_option
  belongs_to :user

  validates :decision_option_id, uniqueness: { scope: :user_id }
  validate :option_belongs_to_decision
  validate :preference_requires_acceptance
  validate :decision_is_open

  private

  def option_belongs_to_decision
    errors.add(:decision_option, "does not belong to this decision") if decision_option&.decision_id != decision_id
  end

  def preference_requires_acceptance
    errors.add(:preferred, "options must also be accepted") if preferred? && !accepted?
  end

  def decision_is_open
    errors.add(:decision, "is closed") if decision&.closed?
  end
end
