require 'rails_helper'


RSpec.describe 'Api::V1::SessionsController', :type => :request do
  let(:user) { create(:user) }
  let(:user_attributes) { attributes_for(:user) }

  describe '#login' do
    context 'when user sends blank credentials' do
      before do
        login_with_api( { email: '', password: ''} )
      end

      it 'returns 400' do
        expect(response.status).to eq(400)
      end

      it 'contains error message' do
        expect(json_response['errors']).to_not be_nil
      end
    end

    context 'when user tries to login with not existing email' do
      before do
        login_with_api( { email: '', password: ''} )
      end

      it 'returns 400' do
        expect(response.status).to eq(400)
      end

      it 'contains error message that can not find user with such email' do
        expect(json_response['errors']).to include(/Can't find user with such email/)
      end
    end

    context 'when user password is invalid' do
      before do
        login_with_api( { email: user.email, password: user.email} )
      end

      it 'returns 400' do
        expect(response.status).to eq(400)
      end

      it 'contains error message that password is invalid' do
        expect(json_response['errors']).to include(/Invalid password/)
      end
    end

    context 'when user tries to login with correct data' do
      before do
        user
        login_with_api(user_attributes)
      end

      it 'returns 200' do
        expect(response.status).to eq(200)
      end

      it 'generates access token' do
        expect(json_response['access_token']).to_not be_nil
      end

      it 'sets refresh token into cookies' do
        expect(cookies[:refresh_token]).to_not be_nil
      end

      it 'generates refresh token for user' do
        expect(cookies[:refresh_token]).to eq(user.refresh_token.value)
      end
    end
  end

  describe '#refresh_tokens' do
    context 'when refresh token does not match to users refresh token in db' do
      before do
        user
        login_with_api(user_attributes)
        user.refresh_token.update(value: 'blah-blah-blah')
        get '/api/v1/refresh_tokens'
      end

      it 'returns 401' do
        expect(response.status).to eq(401)
      end

      it 'contains error message that tokens are not matching' do
        expect(json_response['errors']).to include(/Tokens aren't matching/)
      end
    end

    context 'when token has been expired' do
      before do
        user
        login_with_api(user_attributes)
        decoded = JWT.decode(cookies[:refresh_token],
                             Constants::Jwt::JWT_SECRET_KEYS['refresh']).first
        decoded['iat'] = (Time.now - 30.minutes).to_i
        decoded['exp'] = (Time.now - 20.minutes).to_i
        cookies[:refresh_token] = JWT.encode({ user_id: decoded['user_id'],
                                               iat: decoded['iat'],
                                               exp: decoded['exp']},
                                             Constants::Jwt::JWT_SECRET_KEYS['refresh'],
                                             Constants::Jwt::JWT_ALGORITHM)
        get '/api/v1/refresh_tokens'
      end

      it 'returns 401' do
        expect(response.status).to eq(401)
      end

      it 'contains error message that token has been expired' do
        expect(json_response['errors']).to include(/has expired/)
      end
    end

    context 'when token has wrong signature' do
      before do
        user
        login_with_api(user_attributes)
        cookies[:refresh_token]+='x'
        get '/api/v1/refresh_tokens'
      end

      it 'returns 401' do
        expect(response.status).to eq(401)
      end

      it 'contains error message that token verification failed' do
        expect(json_response['errors']).to include(/verification failed/)
      end
    end

    context 'when there is no refresh token presented' do
      before do
        user
        login_with_api(user_attributes)
        cookies.delete 'refresh_token'
        get '/api/v1/refresh_tokens'
      end

      it 'returns 401' do
        expect(response.status).to eq(401)
      end

      it 'contains error message that nil json web token' do
        expect(json_response['errors']).to include(/Nil JSON/)
      end
    end

    context 'when refresh token matches to token in db', long: true do
      before do
        user
        login_with_api(user_attributes)
        @old_refresh_token = cookies[:refresh_token]
        sleep 1 # to prevent generating same signatures for 2 tokens
        get '/api/v1/refresh_tokens'
      end

      it 'returns 200' do
        expect(response.status).to eq(200)
      end

      it 'returns new access token' do
        expect(json_response['access_token']).to_not be_nil
      end

      it 'generates new refresh token' do
        expect(cookies[:refresh_token]).to_not eq(@old_refresh_token)
      end

      it 'saves new refresh token to db' do
        expect(cookies[:refresh_token]).to eq(user.refresh_token.value)
      end
    end
  end

  describe '#test_method' do
    context 'when user is not authorized' do
      before { get '/api/v1/test_method' }

      it 'returns 401' do
        expect(response.status).to eq(401)
      end

      it 'returns message that you are not logged in' do
        expect(json_response['message']).to eq('You\'re not logged in.')
      end
    end

    context 'when user is authorized' do
      before do
        user
        login_with_api(user_attributes)
        get '/api/v1/test_method',
            headers: {
              'Authorization': "Bearer #{json_response['access_token']}"
            }
      end

      it 'returns 200' do
        expect(response.status).to eq(200)
      end

      it 'returns current user' do
        expect(json_response['id']).to eq(user.id)
      end
    end
  end

  describe '#destroy' do
    context 'when user is not authorized' do
      before { delete '/api/v1/logout' }

      it 'returns 401' do
        expect(response.status).to eq(401)
      end

      it 'contains message that you are not logged in' do
        expect(json_response['message']).to eq('You\'re not logged in.')
      end

    end

    context 'when user is authorized' do
      before do
        user
        login_with_api(user_attributes)
        delete '/api/v1/logout',
               headers: {
                 'Authorization': "Bearer #{json_response['access_token']}"
               }
      end

      it 'returns 200' do
        expect(response.status).to eq(200)
      end

      it 'destroys refresh token' do
        expect(user.reload.refresh_token).to be_nil
       end

      it 'clears cookies' do
        expect(cookies[:refresh_token]).to be_blank
      end

      it 'contains message that you are logged out' do
        expect(json_response['message']).to eq('You have successfully logged out.')
      end
    end
  end
end


