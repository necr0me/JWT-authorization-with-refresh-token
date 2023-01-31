require 'rails_helper'

RSpec.describe Authorization do
  let(:user) { create(:user) }
  let(:token) { Jwt::EncoderService.call(payload: { user_id: user.id }, type: 'access').data }

  controller(ActionController::API) do
    include Authorization

    def action
      authorize!
      render json: { user: current_user } if @current_user.present?
    end
  end

  before do
    routes.draw { get :action, to: 'anonymous#action' }
  end

  describe '#authorize!' do
    context 'with valid token' do
      before do
        request.headers['Authorization'] = "Bearer #{token}"
        get :action
      end

      it 'authorizes user with correct token' do
        expect(json_response['user']['id']).to eq(user.id)
      end
    end

    context 'with invalid token' do
      before do
        request.headers['Authorization'] = "Bearer"
        get :action
      end

      it 'returns 401 and contains message that you are not logged in' do
        expect(response).to have_http_status(401)
        expect(json_response['message']).to eq("You're not logged in")
      end
    end
  end

  describe '#current_user' do
    context 'when authorization was successful' do
      before do
        request.headers['Authorization'] = "Bearer #{token}"
        get :action
      end

      it 'returns authorized user' do
        expect(controller.send(:current_user)).to be_kind_of(User)
        expect(controller.send(:current_user).id).to eq(user.id)
      end
    end

    context "when authorization wasn't successful" do
      before do
        request.headers['Authorization'] = "Bearer"
        get :action
      end

      it 'current_user raises error (because @result is nil)' do
        expect { controller.send(:current_user) }.to raise_error(NoMethodError)
      end
    end
  end
end