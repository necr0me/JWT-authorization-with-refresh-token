require 'rails_helper'

RSpec.describe Auth::AuthorizationService do
  let(:user) { create(:user) }
  let(:access_token) { JWT.encode({ user_id: user.id},
                                  Constants::Jwt::JWT_SECRET_KEYS['access'],
                                  Constants::Jwt::JWT_ALGORITHM) }
  let(:expired_access_token) { JWT.encode({ user_id: user.id, exp: Time.now.to_i - 1.minutes.to_i },
                                          Constants::Jwt::JWT_SECRET_KEYS['access'],
                                          Constants::Jwt::JWT_ALGORITHM) }
  let(:refresh_token) { JWT.encode({ user_id: user.id},
                                   Constants::Jwt::JWT_SECRET_KEYS['refresh'],
                                   Constants::Jwt::JWT_ALGORITHM) }

  describe 'when authorization header is not presented' do
    subject { described_class.call(authorization_header: nil) }

    it 'success? value is false' do
      expect(subject.success?).to eq(false)
    end

    it 'contains error message that header is not presented' do
      expect(subject.errors).to include('Authorization header is not presented')
    end

    it 'doesn\'t returns decoded token' do
      expect(subject.data).to be_nil
    end
  end

  describe 'when refresh token presented instead of access token' do
    subject { described_class.call(authorization_header: "Bearer #{refresh_token}")}

    it 'success? value is false' do
      expect(subject.success?).to eq(false)
    end

    it 'contains error message' do
      expect(subject.errors).to include('Signature verification failed')
    end

    it 'doesn\'t returns decoded token' do
      expect(subject.data).to be_nil
    end
  end

  describe 'when access token is expired' do
    subject { described_class.call(authorization_header: "Bearer #{expired_access_token}") }

    it 'success? value is false' do
      expect(subject.success?).to eq(false)
    end

    it 'contains error message' do
      expect(subject.errors).to include('Signature has expired')
    end

    it 'doesn\'t returns decoded token' do
      expect(subject.data).to be_nil
    end
  end

  describe 'when access token is not presented' do
    subject { described_class.call(authorization_header: "Bearer") }

    it 'success? value is false' do
      expect(subject.success?).to eq(false)
    end

    it 'contains error message' do
      expect(subject.errors).to include('Nil JSON web token')
    end

    it 'doesn\'t returns decoded token' do
      expect(subject.data).to be_nil
    end
  end

  describe 'when access token is presented' do
    subject { described_class.call(authorization_header: "Bearer #{access_token}") }

    it 'success? value is true' do
      expect(subject.success?).to eq(true)
    end

    it 'doesn\'t contains any error message' do
      expect(subject.errors).to be_nil
    end

    it 'returns decoded token' do
      expect(subject.data['user_id']).to eq(user.id)
    end
  end
end
