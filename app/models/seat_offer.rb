class SeatOffer < ApplicationRecord
  belongs_to :ride
  belongs_to :carpool
  belongs_to :user

  after_commit -> { broadcast_refresh_to carpool }

  # One offer per driver-ride and rider, ever: a declined offer stays as a
  # record so the driver cannot re-offer (pester) the same person.
  validates :user_id, uniqueness: { scope: :ride_id }
  validate :ride_is_a_driver_ride
  validate :carpool_matches_ride

  scope :pending, -> { where(declined_at: nil) }

  def pending? = declined_at.nil?

  private

  def ride_is_a_driver_ride
    errors.add(:ride, "must be a driver's ride") if ride && !ride.driver?
  end

  def carpool_matches_ride
    errors.add(:carpool, "must match the ride") if ride && carpool != ride.carpool
  end
end
