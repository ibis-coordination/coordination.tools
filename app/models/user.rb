class User < ApplicationRecord
  has_many :carpools, dependent: :restrict_with_error
  has_many :rides, dependent: :restrict_with_error
  has_many :ride_claims, dependent: :restrict_with_error

  generates_token_for :magic_link, expires_in: 30.minutes

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
