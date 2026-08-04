class Ride < ApplicationRecord
  belongs_to :carpool
  belongs_to :user
  has_many :ride_claims, dependent: :destroy
  has_many :seat_offers, dependent: :destroy

  after_commit -> { broadcast_refresh_to carpool }

  validates :role, :direction, presence: true
  validates :role, inclusion: { in: %w[driver rider] }
  validates :direction, inclusion: { in: %w[outbound return] }
  validates :seats, numericality: { only_integer: true, in: 1..12 }
  validates :user_id, uniqueness: { scope: %i[carpool_id direction], message: "already has an entry for this direction" }
  validate :capacity_covers_claims
  validate :passengers_pin_role_and_direction
  validate :user_has_not_claimed_a_ride

  def driver? = role == "driver"
  def available_seats = [seats - ride_claims.sum(&:seats), 0].max

  private

  def capacity_covers_claims
    return unless driver? && seats.present? && seats < ride_claims.sum(:seats)
    errors.add(:seats, "cannot be less than the number already claimed")
  end

  def passengers_pin_role_and_direction
    return if new_record? || !ride_claims.exists?
    errors.add(:role, "cannot change while passengers are assigned") if role_changed? && role_was == "driver"
    errors.add(:direction, "cannot change while passengers are assigned") if direction_changed?
  end

  def user_has_not_claimed_a_ride
    return unless user && carpool && carpool.ride_claims.where(user: user, direction: direction).exists?
    errors.add(:user, "must leave the current ride first")
  end
end
