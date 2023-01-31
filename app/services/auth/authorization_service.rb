module Auth
  class AuthorizationService < ApplicationService
    def initialize(authorization_header:)
      @authorization_header= authorization_header
    end

    def call
      authorize
    end

    private

    attr_reader :authorization_header

    def authorize
      return fail!(error: 'Authorization header is not presented') if authorization_header.nil?

      token = get_token_from_header
      result = Jwt::DecoderService.call(token: token,
                                        type: 'access')
      result.success? ? success!(data: result.data.first) : fail!(error: result.error)
    end

    def get_token_from_header
      authorization_header.split(' ')[1]
    end
  end
end