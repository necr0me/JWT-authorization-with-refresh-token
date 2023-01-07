# frozen_string_literal: true

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
      if user.present?
        if user.authenticate(password)
          OpenStruct.new(success?: true, user: user, errors: nil)
        else
          OpenStruct.new(success?: false, user: nil, errors: ['Invalid password'])
        end
      else
        OpenStruct.new(success?: false, user: nil, errors: ['Can\'t find user with such email'])
      end
    end

  end
end
