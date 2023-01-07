require 'rails_helper'

RSpec.describe Jwt::EncoderService do
  let(:user) { create(:user) }

  describe 'refresh token' do
    before do
      @refresh_token = described_class.call(
        payload: { user_id: user.id },
        type: 'refresh'
      )
      @secret_key = Constants::Jwt::JWT_SECRET_KEYS['refresh']
      @options = { algorithm: Constants::Jwt::JWT_ALGORITHM }
    end

    it 'contains \'exp\' field' do
      decoded = JWT.decode(@refresh_token,
                           @secret_key,
                           @options).first
      expect(decoded['exp']).to_not be_nil
    end

    it 'contains \'iat\' field' do
      decoded = JWT.decode(@refresh_token,
                           @secret_key,
                           @options).first
      expect(decoded['iat']).to_not be_nil
    end

    it 'expires in 30 days' do
      expires_in = JWT.decode(@refresh_token,
                              @secret_key,
                              @options).first['exp'] - Time.now.to_i
      expect(expires_in).to be_between(29.days.to_i, 31.days.to_i)
    end

    it 'hashing all payload' do
      decoded = JWT.decode(@refresh_token,
                           @secret_key,
                           @options).first
      expect(JSON.generate(decoded)).to_not eq(@refresh_token)
    end
  end

  describe 'access token' do
    before do
      @access_token = described_class.call(
        payload: { user_id: user.id },
        type: 'access'
      )
      @secret_key = Constants::Jwt::JWT_SECRET_KEYS['access']
      @options = { algorithm: Constants::Jwt::JWT_ALGORITHM }
    end

    it 'contains \'exp\' field' do
      decoded = JWT.decode(@access_token,
                           @secret_key,
                           @options).first
      expect(decoded['exp']).to_not be_nil
    end

    it 'contains \'iat\' field' do
      decoded = JWT.decode(@access_token,
                           @secret_key,
                           @options).first
      expect(decoded['iat']).to_not be_nil
    end

    it 'expires in 30 minutes' do
      expires_in = JWT.decode(@access_token,
                              @secret_key,
                              @options).first['exp'] - Time.now.to_i
      expect(expires_in).to be_between(29.minutes.to_i, 31.minutes.to_i)
    end

    it 'hashing all payload' do
      decoded = JWT.decode(@access_token,
                           @secret_key,
                           @options).first
      expect(JSON.generate(decoded)).to_not eq(@access_token)
    end
  end
end
