# frozen_string_literal: true

module Constants
  module Jwt
    JWT_SECRET_KEYS = {
      'access' => Rails.application.credentials.jwt[:secret_access_key],
      'refresh' => Rails.application.credentials.jwt[:secret_refresh_key]
    }

    JWT_EXPIRATION_TIMES = {
      'access' => 30.minutes,
      'refresh' => 30.days
    }
    JWT_ALGORITHM = 'HS256'
    # TODO
    # Add default values for secret keys and expiration times.
  end
end
