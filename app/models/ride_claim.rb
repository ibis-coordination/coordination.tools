class RideClaim < ApplicationRecord
  belongs_to :ride
  belongs_to :carpool
  belongs_to :user

  after_commit -> { broadcast_refresh_to ride.carpool }

  before_validation :set_direction_from_ride

  validates :direction, presence: true
  validates :direction, inclusion: { in: %w[outbound return] }
  validates :seats, numericality: { only_integer: true, in: 1..12 }
  validates :user_id, uniqueness: { scope: %i[carpool_id direction], message: "already claimed a ride for this direction" }
  validate :carpool_matches_ride

  private

  def carpool_matches_ride
    errors.add(:carpool, "must match the ride") if ride && carpool != ride.carpool
  end

  def set_direction_from_ride
    self.direction = ride.direction if ride
  end
end
