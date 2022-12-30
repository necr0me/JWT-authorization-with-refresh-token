# frozen_string_literal: true

module Jwt
  class TokensGeneratorService < ApplicationService

    def initialize(user_id:)
      @user_id = user_id
    end

    def call
      generate_tokens
    end

    private

    attr_reader :user_id

    def generate_tokens
      access_token = Jwt::EncoderService.call(payload: { user_id: user_id },
                                              type: 'access')
      refresh_token = Jwt::EncoderService.call(payload: { user_id: user_id },
                                                 type: 'refresh')
      user = User.includes(:refresh_token).find(user_id)
      if user.refresh_token.present?
        user.refresh_token.update(value: refresh_token)
      else
        user.create_refresh_token(value: refresh_token)
      end
      [access_token, refresh_token]
    end

  end
end
