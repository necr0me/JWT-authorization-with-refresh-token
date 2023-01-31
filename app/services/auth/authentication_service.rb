module Auth
  class AuthenticationService < ApplicationService
    def initialize(user_params:)
      @email = user_params[:email]
      @password = user_params[:password]
    end

    def call
      authenticate
    end

    private

    attr_reader :email, :password

    def authenticate
      user = User.find_by(email: email)
      return fail!(error: 'Can\'t find user with such email') if user.nil?

      user.authenticate(password) ? success!(data: user) : fail!(error: 'Invalid password')
    end

  end
end