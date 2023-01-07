require 'rails_helper'

RSpec.describe Auth::AuthenticationService do
  let(:user) { create(:user) }

  describe 'when email is invalid' do
    subject { described_class.call(user_params: { email: ' ', password: ' '}) }

    it 'success? value is false' do
      expect(subject.success?).to eq(false)
    end

    it 'contains error message that can\'t find user with such email' do
      expect(subject.errors).to include('Can\'t find user with such email')
    end

    it 'doesn\'t return user' do
      expect(subject.user).to be_nil
    end
  end

  describe 'when password is invalid' do
    subject { described_class.call(user_params: { email: user.email, password: ' '}) }

    it 'success? value is false' do
      expect(subject.success?).to eq(false)
    end

    it 'contains error message that password is invalid' do
      expect(subject.errors).to include('Invalid password')
    end

    it 'doesn\'t return user' do
      expect(subject.user).to be_nil
    end
  end

  describe 'when credentials are correct' do
    subject { described_class.call(user_params: { email: user.email, password: user.password } ) }

    it 'success? value is true' do
      expect(subject.success?).to eq(true)
    end

    it 'doesn\'t contains any errors' do
      expect(subject.errors).to be_nil
    end

    it 'returns correct user' do
      expect(subject.user).to_not be_nil
      expect(subject.user.id).to eq(user.id)
    end
  end
end
