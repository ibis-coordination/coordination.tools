class Decision < ApplicationRecord
  belongs_to :user
  has_many :decision_options, dependent: :destroy
  has_many :decision_votes, dependent: :destroy

  before_validation :set_public_id, on: :create
  validates :question, :public_id, presence: true
  validates :question, length: { maximum: 1_000 }
  validates :public_id, uniqueness: true

  def to_param = public_id
  def closed? = closed_at.present? || deadline&.past?
  def voter_count = decision_votes.select(:user_id).distinct.count

  def results
    finalize_result_tiebreakers! if closed?

    decision_options.left_joins(:decision_votes)
      .select("decision_options.*, COUNT(CASE WHEN decision_votes.accepted THEN 1 END) AS acceptances, COUNT(CASE WHEN decision_votes.preferred THEN 1 END) AS preferences")
      .group("decision_options.id")
      .order(Arel.sql("acceptances DESC, preferences DESC, COALESCE(decision_options.result_tiebreaker, RANDOM()) DESC"))
  end

  def close!(final_statement: nil)
    transaction do
      lock!
      update!(closed_at: Time.current, final_statement: final_statement)
      finalize_result_tiebreakers!
    end
  end

  def finalize_result_tiebreakers!
    return unless closed?
    return unless decision_options.where(result_tiebreaker: nil).exists?

    transaction do
      lock!
      decision_options.where(result_tiebreaker: nil).find_each do |option|
        option.update!(result_tiebreaker: SecureRandom.random_number(2**63))
      end
    end
  end

  private

  def set_public_id
    self.public_id ||= SecureRandom.base58(10)
  end
end
