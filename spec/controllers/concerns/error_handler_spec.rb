require 'rails_helper'

RSpec.describe ErrorHandler do
  describe '#record_not_found' do
    controller(ActionController::API) do
      include ErrorHandler

      def action
        raise ActiveRecord::RecordNotFound.new "Can't find this record"
      end
    end

    before do
      routes.draw { get :action, to: 'anonymous#action'}
      get :action
    end

    it 'returns 404' do
      expect(response).to have_http_status(404)
    end

    it 'contains error message' do
      expect(json_response['message']).to eq("Can't find this record")
    end
  end
end