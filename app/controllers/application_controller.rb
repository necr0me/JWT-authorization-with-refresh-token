class ApplicationController < ActionController::API
  include ActionController::Cookies

  protected

  def authorize!
    @result = Auth::AuthorizationService.call(authorization_header: request.headers['Authorization'])
    if @result.success?
      current_user
    else
      render json: { 'message' => 'You\'re not logged in.', 'errors' => @result.errors }, status: 401
    end
  end

  def current_user
    @current_user ||= User.find(@result.data['user_id'])
  end
end
