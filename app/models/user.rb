class User < ApplicationRecord
  has_many :carpools, dependent: :restrict_with_error
  has_many :rides, dependent: :restrict_with_error
  has_many :ride_claims, dependent: :restrict_with_error

  before_validation :normalize_email

  validates :name, :email, presence: true
  validates :email, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
