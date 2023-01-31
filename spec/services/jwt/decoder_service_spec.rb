require 'rails_helper'

RSpec.describe Jwt::DecoderService do
  let(:payload) { { user_id: '1337' } }
  let(:algorithm) { Constants::Jwt::JWT_ALGORITHM }

  describe '#call' do
    context 'refresh token' do
      let(:token_type) { 'refresh' }
      let(:secret) { Constants::Jwt::JWT_SECRET_KEYS[token_type] }

      context 'when error occurs' do
        before do
          allow(JWT).to receive(:decode).and_raise('Some error')
        end

        it 'does not contains decoded token and contains error message' do
          result = described_class.call(token: JWT.encode(payload, secret, algorithm),
                                        type: token_type)
          expect(result.data).to be_nil
          expect(result.error).to eq('Some error')
        end
      end

      context 'when no errors occurs' do
        it 'decodes token with correct key' do
          result = described_class.call(token: JWT.encode(payload, secret, algorithm),
                                        type: 'refresh')

          expect(result.success?).to be_truthy
          expect(result.data.first['user_id']).to eq(payload[:user_id])
        end
      end
    end

    context 'access token' do
      let(:token_type) { 'access' }
      let(:secret) { Constants::Jwt::JWT_SECRET_KEYS[token_type] }

      context 'when error occurs' do
        before do
          allow(JWT).to receive(:decode).and_raise('Some error')
        end

        it 'does not contains decoded token and returns error' do
          result = described_class.call(token: JWT.encode(payload, secret, algorithm),
                                        type: 'access')
          expect(result.data).to be_nil
          expect(result.error).to eq('Some error')
        end
      end

      context 'when no error occurs' do
        it 'returns decoded token' do
          result = described_class.call(token: JWT.encode(payload, secret, algorithm),
                                        type: 'access')

          expect(result.success?).to be_truthy
          expect(result.data.first['user_id']).to eq(payload[:user_id])
        end
      end
    end
  end
end