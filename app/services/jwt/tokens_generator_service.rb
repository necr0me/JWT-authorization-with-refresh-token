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
      access_token = Jwt::EncoderService.call(payload: { user_id: user_id }, type: 'access')
      refresh_token = Jwt::EncoderService.call(payload: { user_id: user_id }, type: 'refresh')
      return fail!(error: access_token.error) if access_token.data.nil?
      return fail!(error: refresh_token.error) if refresh_token.data.nil?

      user = User.includes(:refresh_token).find(user_id)
      if user.refresh_token.present?
        user.refresh_token.update(value: refresh_token.data)
      else
        user.create_refresh_token(value: refresh_token.data)
      end
      success!(data: [access_token.data, refresh_token.data])
    end
  end
end