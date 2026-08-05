class User < ApplicationRecord
  has_many :carpools, dependent: :restrict_with_error
  has_many :rides, dependent: :restrict_with_error
  has_many :ride_claims, dependent: :restrict_with_error
  has_many :seat_offers, dependent: :destroy
  has_many :decisions, dependent: :restrict_with_error
  has_many :decision_options, dependent: :restrict_with_error
  has_many :decision_votes, dependent: :destroy

  generates_token_for :magic_link, expires_in: 30.minutes

  # Embedding pending_email invalidates outstanding links whenever a newer
  # change request replaces it.
  generates_token_for :email_change, expires_in: 30.minutes do
    pending_email
  end

  before_validation :normalize_email

  validates :name, :email, presence: true
  validates :email, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

  def email_confirmed? = email_confirmed_at.present?

  def confirm_email!
    update!(email_confirmed_at: Time.current) unless email_confirmed?
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
