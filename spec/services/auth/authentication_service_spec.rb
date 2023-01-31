require 'rails_helper'

RSpec.describe Auth::AuthenticationService do
  let(:user) { create(:user) }

  describe '#authenticate' do
    context 'when error occurs' do
      before do
        allow(User).to receive(:find_by).and_raise('Some error')
      end

      it 'contains error and doesnt return user' do
        result = described_class.call(user_params: attributes_for(:user))
        expect(result.error).to eq('Some error')
      end
    end

    context 'when email is invalid' do
      it 'contains error and doesnt return user' do
        result = described_class.call(user_params: { email: ' ', password: ' '})

        expect(result.error).to eq('Can\'t find user with such email')
        expect(result.data).to be_nil
      end
    end

    context 'when password is invalid' do
      it 'contains error message and does not return user' do
        result = described_class.call(user_params: { email: user.email, password: ' '})

        expect(result.error).to eq('Invalid password')
        expect(result.data).to be_nil
      end
    end

    context 'when credentials are correct' do
      it 'does not contains any errors and returns correct user' do
        result = described_class.call(user_params: { email: user.email, password: user.password } )

        expect(result.error).to be_nil

        expect(result.data).to_not be_nil
        expect(result.data.id).to eq(user.id)
      end
    end
  end
end