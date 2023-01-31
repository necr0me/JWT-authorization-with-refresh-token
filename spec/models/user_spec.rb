require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }
  let(:user_with_token) { create(:user, :user_with_refresh_token)}

  describe 'validations' do
    context '#email' do
      it 'is invalid when email is blank' do
        user.email = ' '
        expect(user).to_not be_valid
      end

      it 'is invalid when email has incorrect format' do
        user.email = 'mail'
        expect(user).to_not be_valid

        user.email = 'm@m'
        expect(user).to_not be_valid
      end

      it 'is invalid when email is too long (longer than 64 symbols)' do
        user.email = 'mail@mail.ru' + 'x' * 64
        expect(user).to_not be_valid
      end

      it 'is valid with correct format' do
        user.email = 'mail@gmail.com'
        expect(user).to be_valid

        user.email = 'my_mail_k3k@ya.ru'
        expect(user).to be_valid
      end
    end

    context '#password' do
      it 'is invalid when password is blank' do
        user.password = ' '
        expect(user).to_not be_valid
      end

      it 'is invalid when password is too short (shorter than 7 symbols)' do
        user.password = 'x' * 6
        expect(user).to_not be_valid
      end

      it 'is invalid when password is too long (longer than 64 symbols)' do
        user.password = 'x' * 65
        expect(user).to_not be_valid
      end

      it 'is valid when password is correct' do
        user.password = 'password'
        expect(user).to be_valid
      end
    end
  end

  describe 'associations' do
    context 'refresh_token' do
      it 'user has one refresh_token' do
        expect(described_class.reflect_on_association(:refresh_token).macro).to eq(:has_one)
      end

      it 'destroys with user' do
        user_id = user_with_token.id
        user_with_token.destroy
        expect(RefreshToken.find_by(user_id: user_id)).to be_nil
      end
    end
  end
end