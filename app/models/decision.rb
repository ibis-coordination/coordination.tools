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
    decision_options.left_joins(:decision_votes)
      .select("decision_options.*, COUNT(CASE WHEN decision_votes.accepted THEN 1 END) AS acceptances, COUNT(CASE WHEN decision_votes.preferred THEN 1 END) AS preferences")
      .group("decision_options.id")
      .order(Arel.sql("acceptances DESC, preferences DESC, RANDOM()"))
  end

  private

  def set_public_id
    self.public_id ||= SecureRandom.base58(10)
  end
end
