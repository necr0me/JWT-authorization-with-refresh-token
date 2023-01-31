module Authorization
  extend ActiveSupport::Concern

  included do
    protected

    def authorize!
      @result = Auth::AuthorizationService.call(authorization_header: request.headers['Authorization'])
      if @result.success?
        current_user
      else
        render json: { message: 'You\'re not logged in',
                       errors: [@result.error] },
               status: 401
      end
    end

    def current_user
      @current_user ||= User.find(@result.data['user_id'])
    end
  end
end
