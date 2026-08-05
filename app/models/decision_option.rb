class DecisionOption < ApplicationRecord
  belongs_to :decision
  belongs_to :user
  has_many :decision_votes, dependent: :destroy

  validates :title, presence: true, length: { maximum: 1_000 }
  validate :decision_accepts_options, on: :create

  private

  def decision_accepts_options
    errors.add(:decision, "is no longer accepting options") if decision&.closed? || !decision&.options_open?
  end
end
