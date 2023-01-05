class User < ApplicationRecord
  has_one :refresh_token, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true

  has_secure_password

end
