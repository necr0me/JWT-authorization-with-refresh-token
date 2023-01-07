require 'rails_helper'

RSpec.describe RefreshToken, type: :model do
  describe 'associations' do
    context 'user' do
      it 'refresh_token belongs to user' do
        expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
      end
    end
  end
end

