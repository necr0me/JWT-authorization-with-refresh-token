module Jwt
  class TokensRefresherService < ApplicationService
    def initialize(refresh_token: )
      @refresh_token = refresh_token
    end

    def call
      refresh_tokens
    end

    private

    attr_reader :refresh_token

    def refresh_tokens
      begin
        decoded_token = Jwt::DecoderService.call(token: refresh_token,
                                                 type: 'refresh').first
        user = User.includes(:refresh_token).find(decoded_token['user_id'])

        if user.refresh_token.value != refresh_token
          return OpenStruct.new(success?: false, tokens: nil, errors: ['Tokens aren\'t matching.'])
        end

        tokens = TokensGeneratorService.call(user_id: decoded_token['user_id'])
        return OpenStruct.new(success?: true, tokens: tokens, errors: nil)
      rescue JWT::VerificationError, JWT::ExpiredSignature, JWT::DecodeError => e
        return OpenStruct.new(success?: false, tokens: nil, errors: [e.message])
      end
    end

  end
end
