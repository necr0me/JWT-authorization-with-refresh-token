require 'rails_helper'

RSpec.describe Jwt::TokensRefresherService do
  let(:user) { create(:user, :user_with_refresh_token) }

  let(:payload) { { user_id: user.id } }
  let(:refresh_secret) { Constants::Jwt::JWT_SECRET_KEYS['refresh'] }
  let(:access_secret) { Constants::Jwt::JWT_SECRET_KEYS['access'] }
  let(:algorithm) { Constants::Jwt::JWT_ALGORITHM }

  let(:refresh_token) { JWT.encode(payload, refresh_secret, algorithm)}

  describe '#refresh_tokens' do
    context 'when error occurs' do
      before do
        allow(User).to receive(:includes).and_raise('Some error')
      end

      it 'does not return tokens and contains error message' do
        result = described_class.call(refresh_token: refresh_token)

        expect(result.data).to be_nil
        expect(result.error).to eq('Some error')
      end
    end

    context 'no refresh token presented' do
      it 'contains error message and does not returns tokens' do
        result = described_class.call(refresh_token: nil)

        expect(result.error).to match(/Nil JSON/)
        expect(result.data).to be_nil
      end
    end


    context 'presented refresh token and refresh token in db are not matching' do
      it 'success? value is false, contains error message and does not returns tokens' do
        result = described_class.call(refresh_token: refresh_token)

        expect(result.error).to eq('Tokens aren\'t matching')
        expect(result.data).to be_nil
      end
    end

    context 'expired refresh token presented' do
      before do
        user.refresh_token.update(value: JWT.encode(payload.merge({ exp: Time.now.to_i - 1.minutes.to_i }),
                                                    refresh_secret,
                                                    algorithm))
      end

      it 'success? value is false, contains error message and does not returns tokens' do
        result = described_class.call(refresh_token: user.reload.refresh_token.value)

        expect(result.error).to eq('Signature has expired')
        expect(result.data).to be_nil
      end
    end

    context 'access token presented instead of refresh token' do
      it 'success? value is false, contains error message and does not returns tokens' do
        result = described_class.call(refresh_token: JWT.encode(payload, access_secret, algorithm))

        expect(result.error).to eq('Signature verification failed')
        expect(result.data).to be_nil
      end
    end

    context 'correct refresh token presented' do
      before { user.refresh_token.update(value: refresh_token) }

      it 'success? value is true, no errors, returns 2 tokens and updates refresh token in db' do
        old_token = user.reload.refresh_token.value
        result = described_class.call(refresh_token: user.reload.refresh_token.value)
        new_token = result.data.last

        expect(result.error).to be_nil
        expect(result.data.count).to eq(2)

        expect(user.reload.refresh_token.value).to eq(new_token)
        expect(user.refresh_token.value).to_not eq(old_token)
      end
    end
  end
end