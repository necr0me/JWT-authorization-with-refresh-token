class User < ApplicationRecord
  has_one :refresh_token, dependent: :destroy

  VALID_EMAIL_REGEX = /\A[a-zA-Z0-9_.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-.]+\z/i

  validates :email, presence: true, uniqueness: true,
            format: VALID_EMAIL_REGEX, length: { maximum: 64}
  validates :password, presence: true,
            length: { minimum: 7, maximum: 64}

  has_secure_password

end
