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
      [
        Jwt::EncoderService.call(payload: { user_id: user_id },
                                 type: 'access'),
        Jwt::EncoderService.call(payload: { user_id: user_id },
                                 type: 'refresh')
      ]
    end

  end
end
