require 'rails_helper'

RSpec.describe Auth::AuthorizationService do
  let(:user) { create(:user) }
  let(:access_token) { JWT.encode({ user_id: user.id },
                                  Constants::Jwt::JWT_SECRET_KEYS['access'],
                                  Constants::Jwt::JWT_ALGORITHM) }
  let(:expired_access_token) { JWT.encode({ user_id: user.id, exp: Time.now.to_i - 1.minutes.to_i },
                                          Constants::Jwt::JWT_SECRET_KEYS['access'],
                                          Constants::Jwt::JWT_ALGORITHM) }
  let(:refresh_token) { JWT.encode({ user_id: user.id},
                                   Constants::Jwt::JWT_SECRET_KEYS['refresh'],
                                   Constants::Jwt::JWT_ALGORITHM) }
  describe '#authorize' do
    context 'when error occurs' do
      before do
        allow_any_instance_of(described_class).to receive(:get_token_from_header).and_raise('Some error')
      end

      it 'contains error message' do
        result = described_class.call(authorization_header: "Bearer #{access_token}")
        expect(result.error).to eq('Some error')
      end
    end

    context 'when authorization header is not presented' do
      it 'contains error message and does not returns decoded token ' do
        result = described_class.call(authorization_header: nil)

        expect(result.error).to eq('Authorization header is not presented')
        expect(result.data).to be_nil
      end
    end

    context 'when refresh token presented instead of access token' do
      it 'contains error message and does not returns decoded token' do
        result = described_class.call(authorization_header: "Bearer #{refresh_token}")

        expect(result.error).to eq('Signature verification failed')
        expect(result.data).to be_nil
      end
    end

    context 'when access token is expired' do
      it 'contains error message and does not returns decoded token' do
        result = described_class.call(authorization_header: "Bearer #{expired_access_token}")

        expect(result.error).to eq('Signature has expired')
        expect(result.data).to be_nil
      end
    end

    context 'when access token is not presented' do
      it 'contains error message and does not returns decoded token' do
        result = described_class.call(authorization_header: "Bearer")

        expect(result.error).to eq('Nil JSON web token')
        expect(result.data).to be_nil
      end
    end

    context 'when access token is presented' do
      it 'no errors and returns authorized user' do
        result = described_class.call(authorization_header: "Bearer #{access_token}")

        expect(result.error).to be_nil
        expect(result.data['user_id']).to eq(user.id)
      end
    end
  end
end