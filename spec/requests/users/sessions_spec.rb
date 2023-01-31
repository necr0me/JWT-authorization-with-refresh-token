require 'rails_helper'

RSpec.describe Users::SessionsController, :type => :request do
  let(:user) { create(:user) }
  let(:user_credentials) { user; attributes_for(:user) }

  describe 'concerns' do
    context 'UserParamable' do
      it 'includes UserParamable concern' do
        expect(described_class.ancestors).to include(UserParamable)
      end
    end
  end

  describe '#login' do
    context 'when user sends blank credentials' do
      before do
        login_with_api( { email: '', password: ''} )
      end

      it 'returns 400 and contains error message' do
        expect(response).to have_http_status(400)
        expect(json_response['errors']).to_not be_nil
      end
    end

    context 'when user tries to login with not existing email' do
      before do
        login_with_api( { email: '', password: ''} )
      end

      it 'returns 400 and contains error message that can not find user with such email' do
        expect(response).to have_http_status(400)
        expect(json_response['errors']).to include(/Can't find user with such email/)
      end
    end

    context 'when user password is invalid' do
      before do
        login_with_api( { email: user.email, password: user.email} )
      end

      it 'returns 400 and contains error message that password is invalid' do
        expect(response).to have_http_status(400)
        expect(json_response['errors']).to include(/Invalid password/)
      end
    end

    context 'when user tries to login with correct data' do
      before do
        login_with_api(user_credentials)
      end

      it 'returns 201, generates access token, saves refresh token into cookies and in db' do
        expect(response).to have_http_status(201)
        expect(json_response['access_token']).to_not be_nil
        expect(cookies[:refresh_token]).to_not be_nil
        expect(cookies[:refresh_token]).to eq(user.refresh_token.value)
      end
    end
  end

  describe '#refresh_tokens' do
    context 'when refresh token does not match to users refresh token in db' do
      before do
        login_with_api(user_credentials)
        user.refresh_token.update(value: 'blah-blah-blah')
        get '/users/refresh_tokens'
      end

      it 'returns 401 and contains error message that tokens are not matching' do
        expect(response).to have_http_status(401)
        expect(json_response['errors']).to include(/Tokens aren't matching/)
      end
    end

    context 'when token has been expired' do
      before do
        login_with_api(user_credentials)
        decoded = JWT.decode(cookies[:refresh_token],
                             Constants::Jwt::JWT_SECRET_KEYS['refresh']).first
        decoded['iat'] = (Time.now - 30.minutes).to_i
        decoded['exp'] = (Time.now - 20.minutes).to_i
        cookies[:refresh_token] = JWT.encode({ user_id: decoded['user_id'],
                                               iat: decoded['iat'],
                                               exp: decoded['exp']},
                                             Constants::Jwt::JWT_SECRET_KEYS['refresh'],
                                             Constants::Jwt::JWT_ALGORITHM)
        get '/users/refresh_tokens'
      end

      it 'returns 401 and contains error message that token has been expired' do
        expect(response).to have_http_status(401)
        expect(json_response['errors']).to include(/has expired/)
      end
    end

    context 'when token has wrong signature' do
      before do
        login_with_api(user_credentials)
        cookies[:refresh_token]+='x'
        get '/users/refresh_tokens'
      end

      it 'returns 401 and contains error message that token verification failed' do
        expect(response).to have_http_status(401)
        expect(json_response['errors']).to include(/verification failed/)
      end
    end

    context 'when there is no refresh token presented' do
      before do
        user
        login_with_api(user_credentials)
        cookies.delete 'refresh_token'
        get '/users/refresh_tokens'
      end

      it 'returns 401 and contains error message that nil json web token' do
        expect(response).to have_http_status(401)
        expect(json_response['errors']).to include(/Nil JSON/)
      end
    end

    context 'when refresh token matches to token in db', long: true do
      before do
        login_with_api(user_credentials)
        @old_refresh_token = cookies[:refresh_token]
        sleep 1 # to prevent generating same signatures for 2 tokens
        get '/users/refresh_tokens'
      end

      it 'returns 200 and new access token' do
        expect(response).to have_http_status(200)
        expect(json_response['access_token']).to_not be_nil
      end

      it 'generates new refresh token and saves it to db' do
        expect(cookies[:refresh_token]).to_not eq(@old_refresh_token)
        expect(cookies[:refresh_token]).to eq(user.refresh_token.value)
      end
    end
  end

  describe '#test_method' do
    context 'when user is unauthorized' do
      before do
        get '/users/test_method'
      end

      it 'returns 401' do
        expect(response).to have_http_status(401)
      end
    end

    context 'when user is authorized' do
      before do
        get '/users/test_method', headers: auth_header
      end

      it 'returns 200 and current user' do
        expect(response).to have_http_status(200)
        expect(json_response['user']['id']).to eq(user.id)
      end
    end
  end

  describe '#destroy' do
    context 'when user is unauthorized' do
      before { delete '/users/logout' }

      it 'returns 401' do
        expect(response).to have_http_status(401)
      end
    end

    context 'when user is authorized' do
      before do
        login_with_api(user_credentials)
        delete '/users/logout', headers: auth_header
      end

      it 'returns 200, destroys refresh token and clears cookies' do
        expect(response).to have_http_status(200)
        expect(user.reload.refresh_token).to be_nil
        expect(cookies[:refresh_token]).to be_blank
        expect(json_response['message']).to eq('You have successfully logged out.')
      end
    end
  end
end