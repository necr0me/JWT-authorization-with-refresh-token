require 'rails_helper'

RSpec.describe Jwt::TokensGeneratorService do
  let(:user) { create(:user) }
  let(:user_with_token) { create(:user, :with_refresh_token) }

  let(:generate_tokens_for_user) { described_class.call(user_id: user.id) }
  let(:generate_tokens_for_user_with_token) { described_class.call(user_id: user_with_token.id) }


  describe 'no matter if refresh token exists or not' do
    it 'generates two tokens' do
      expect(generate_tokens_for_user.count).to eq(2)
    end

    it 'generates access token' do
      access_token = generate_tokens_for_user.first
      expect { JWT.decode(access_token,
                          Constants::Jwt::JWT_SECRET_KEYS['access'],
                          true,
                          { algorithm: Constants::Jwt::JWT_ALGORITHM})}.to_not raise_error
    end

    it 'generates refresh token' do
      refresh_token = generate_tokens_for_user.last
      expect { JWT.decode(refresh_token,
                          Constants::Jwt::JWT_SECRET_KEYS['refresh'],
                          true,
                          { algorithm: Constants::Jwt::JWT_ALGORITHM})}.to_not raise_error
    end
  end

  describe 'refresh token of user doesn\'t exists' do
    it 'creates refresh token for user if token is not created' do
      expect(user.refresh_token).to be_nil

      token = generate_tokens_for_user.last

      expect(user.reload.refresh_token).to_not be_nil
      expect(user.refresh_token.value).to eq(token)
    end
  end

  describe 'refresh token of user exists' do
    it 'updates refresh token for user if token is already exists' do
      old_token = user_with_token.refresh_token.value
      expect(user_with_token.refresh_token).to_not be_nil

      new_token = generate_tokens_for_user_with_token.last

      expect(user_with_token.reload.refresh_token.value).to eq(new_token)
      expect(user_with_token.refresh_token.value).to_not eq(old_token)
    end
  end
end