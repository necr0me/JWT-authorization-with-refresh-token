require 'rails_helper'

RSpec.describe Jwt::TokensRefresherService do
  let(:user) { create(:user, :with_refresh_token) }
  let(:secret_key) { Constants::Jwt::JWT_SECRET_KEYS['refresh'] }
  let(:secret_access_key) { Constants::Jwt::JWT_SECRET_KEYS['access'] }
  let(:algorithm) { Constants::Jwt::JWT_ALGORITHM }


  describe 'no refresh token presented' do
    subject { described_class.call(refresh_token: nil) }

    it 'success? value is false' do
      expect(subject.success?).to eq(false)
    end

    it 'contains error message that token is not presented' do
      expect(subject.errors).to include(/Nil JSON/)
    end

    it 'does not returns tokens' do
      expect(subject.tokens).to be_nil
    end
  end


  describe 'presented refresh token and refresh token in db are not matching' do
    subject { described_class.call(refresh_token: JWT.encode({ user_id: user.id }, secret_key, algorithm))}

    it 'success? value is false' do
      expect(subject.success?).to eq(false)
    end

    it 'contains error message that tokens aren\'t matching' do
      expect(subject.errors).to include('Tokens aren\'t matching')
    end

    it 'does not returns tokens' do
      expect(subject.tokens).to be_nil
    end
  end

  describe 'expired refresh token presented' do
    subject { described_class.call(refresh_token: user.reload.refresh_token.value) }

    before do
      user.refresh_token.update(value: JWT.encode({ user_id: user.id, exp: Time.now.to_i - 1.minutes.to_i },
                                                  secret_key,
                                                  algorithm))
    end

    it 'success? value is false' do
      expect(subject.success?).to eq(false)
    end

    it 'contains error message that token signature is expired' do
      expect(subject.errors).to include('Signature has expired')
    end

    it 'does not returns tokens' do
      expect(subject.tokens).to be_nil
    end
  end

  describe 'access token presented instead of refresh token' do
    subject { described_class.call(refresh_token: JWT.encode({ user_id: user.id},
                                                             secret_access_key,
                                                             algorithm)) }

    it 'success? value is false' do
      expect(subject.success?).to eq(false)
    end

    it 'contains signature verification error message' do
      expect(subject.errors).to include('Signature verification failed')
    end

    it 'does not returns tokens' do
      expect(subject.tokens).to be_nil
    end
  end

  describe 'correct refresh token presented' do
    subject { described_class.call(refresh_token: user.reload.refresh_token.value) }

    before do
      user.refresh_token.update(value: JWT.encode({ user_id: user.id },
                                                  secret_key,
                                                  algorithm))
    end

    it 'success? value is true' do
      expect(subject.success?).to eq(true)
    end

    it 'no errors presented' do
      expect(subject.errors).to be_nil
    end

    it 'returns 2 tokens' do
      expect(subject.tokens.count).to eq(2)
    end

    it 'updates token in db' do
      old_token = user.reload.refresh_token.value
      new_token = subject.tokens.last

      expect(user.reload.refresh_token.value).to eq(new_token)
      expect(user.refresh_token.value).to_not eq(old_token)
    end
  end
end