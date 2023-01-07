require 'rails_helper'
# To make this tests better necessary to make described service unit testable

RSpec.describe Jwt::DecoderService do
  let(:user) { create(:user) }

  describe 'refresh token' do
    before do
      @refresh_token = JWT.encode({ user_id: user.id },
                                  Constants::Jwt::JWT_SECRET_KEYS['refresh'],
                                  Constants::Jwt::JWT_ALGORITHM)
    end

    it 'raises verification error when using wrong key' do
      expect { described_class.call(token: @refresh_token,
                                  type: 'access') }.to raise_error(JWT::VerificationError)
    end

    it 'raises expired signature error when token is expired' do
      @refresh_token = JWT.encode({ user_id: user.id, exp: Time.now.to_i - 1.minutes.to_i },
                                  Constants::Jwt::JWT_SECRET_KEYS['refresh'],
                                  Constants::Jwt::JWT_ALGORITHM)
      expect { described_class.call(token: @refresh_token,
                                    type: 'refresh') }.to raise_error(JWT::ExpiredSignature)
    end

    it 'raises nil json web token error when token is not present' do
      expect { described_class.call(token: ' ',
                                    type: 'refresh') }.to raise_error(JWT::DecodeError)
    end

    it 'decodes token with correct key' do
      decoded = described_class.call(token: @refresh_token,
                                     type: 'refresh').first
      expect(decoded['user_id']).to eq(user.id)
    end
  end

  describe 'access token' do
    before do
      @access_token = JWT.encode({ user_id: user.id },
                                  Constants::Jwt::JWT_SECRET_KEYS['access'],
                                  Constants::Jwt::JWT_ALGORITHM)
    end

    it 'raises verification error when using wrong key' do
      expect { described_class.call(token: @access_token,
                                    type: 'refresh') }.to raise_error(JWT::VerificationError)
    end

    it 'raises expired signature error when token is expired' do
      @access_token = JWT.encode({ user_id: user.id, exp: Time.now.to_i - 1.minutes.to_i },
                                  Constants::Jwt::JWT_SECRET_KEYS['access'],
                                  Constants::Jwt::JWT_ALGORITHM)
      expect { described_class.call(token: @access_token,
                                    type: 'access') }.to raise_error(JWT::ExpiredSignature)
    end

    it 'raises nil json web token error when token is not present' do
      expect { described_class.call(token: ' ',
                                    type: 'access') }.to raise_error(JWT::DecodeError)
    end

    it 'decodes token with correct key' do
      decoded = described_class.call(token: @access_token,
                                     type: 'access').first
      expect(decoded['user_id']).to eq(user.id)
    end
  end
end
