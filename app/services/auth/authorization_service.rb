# frozen_string_literal: true
module Auth
  class AuthorizationService < ApplicationService
    include Constants::Jwt

    def initialize(authorization_header:)
      @authorization_header= authorization_header
    end

    def call
      authorize
    end

    private

    attr_reader :authorization_header

    def authorize
      return OpenStruct.new(success?: false, data: nil, errors: ['Authorization header is not presented']) if authorization_header.nil?

      token = get_token_from_header
      begin
        decoded_token = Jwt::DecoderService.call(token: token,
                                                 type: 'access').first
        return OpenStruct.new(success?: true, data: decoded_token, errors: nil)
      rescue => e
        return OpenStruct.new(success?: false, data: nil, errors: [e.message])
      end
    end

    def get_token_from_header
      authorization_header.split(' ')[1]
    end

  end
end
