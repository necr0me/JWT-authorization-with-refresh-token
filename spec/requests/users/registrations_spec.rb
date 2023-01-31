require 'rails_helper'

RSpec.describe Users::RegistrationsController, :type => :request do

  let(:user) { build(:user) }
  let(:existing_user) { create(:user) }

  describe 'concerns' do
    context 'UserFindable' do
      it 'includes UserFindable concern' do
        expect(described_class.ancestors).to include(UserFindable)
      end
    end

    context 'UserParamable' do
      it 'includes UserParamable concern' do
        expect(described_class.ancestors).to include(UserParamable)
      end
    end
  end

  describe '#sign_up' do
    context 'user tries to register with blank data' do
      before do
        post '/users/sign_up',
             params: {
               user: {
                 email: ' ',
                 password: ' '
               }
             }
      end

      it 'returns 422 and contains error messages' do
        expect(response).to have_http_status(422)
        expect(json_response['errors']).to include(/Email can't be blank/)
        expect(json_response['errors']).to include(/Password can't be blank/)
      end
    end

    context 'user tries to register with already taken email' do
      before do
        post '/users/sign_up',
             params: {
               user: {
                 email: existing_user.email,
                 password: existing_user.password
               }
             }
      end

      it 'returns 422 and contains error message' do
        expect(response).to have_http_status(422)
        expect(json_response['errors']).to include(/Email has already been taken/)
      end
    end

    context 'user tries to register with valid data' do
      before do
        post '/users/sign_up',
             params: {
               user: {
                 email: user.email,
                 password: user.email
               }
             }
      end

      it 'returns 201 and creates user in db' do
        expect(response).to have_http_status(201)
        expect(User.find_by(email: user.email).email).to eq(user.email)
      end
    end
  end

  describe '#destroy' do
    context 'when user is unauthorized' do
      before do
        delete "/users/#{existing_user.id}"
      end

      it 'returns 401' do
        expect(response).to have_http_status(401)
      end
    end

    context 'when error occurs during destroying of user' do
      before do
        allow_any_instance_of(User).to receive(:destroy).and_return(false)
        allow_any_instance_of(ActiveModel::Errors).to receive(:full_messages).and_return(['Error message'])

        delete "/users/#{existing_user.id}", headers: auth_header_for(existing_user)
      end

      it 'returns 422 and error message' do
        expect(response).to have_http_status(422)
        expect(json_response['errors']).to include('Error message')
      end
    end

    context 'when user tries to destroy existing user' do
      before do
        delete "/users/#{existing_user.id}", headers: auth_header_for(existing_user)
      end

      it 'returns 204 and deletes user from db' do
        expect(response).to have_http_status(204)
        expect { existing_user.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
