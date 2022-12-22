class User < ApplicationRecord
  before_create :hash_password!

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true

  def hash_password(password)
    BCrypt::Password.create(password)
  end

  private

  def hash_password!
    self.password = hash_password(self.password)
  end

end
