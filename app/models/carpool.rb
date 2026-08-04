class Carpool < ApplicationRecord
  belongs_to :user
  has_many :rides, dependent: :destroy
  has_many :ride_claims, dependent: :destroy

  before_validation :set_public_id, on: :create
  before_validation :default_name_from_destination
  validates :name, :public_id, presence: true
  validates :public_id, uniqueness: true
  validate :return_trip_follows_event

  def to_param = public_id

  private

  def set_public_id
    self.public_id ||= SecureRandom.base58(10)
  end

  def default_name_from_destination
    self.name = "Carpool to #{destination}" if name.blank? && destination.present?
  end

  def return_trip_follows_event
    return if return_starts_at.blank? || starts_at.blank? || return_starts_at > starts_at
    errors.add(:return_starts_at, "must be after the event start time")
  end
end
