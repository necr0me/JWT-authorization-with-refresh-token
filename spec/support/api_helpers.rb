module ApiHelpers
  def json_response
    JSON.parse(response.body)
  end

  def login_with_api(credentials)
    post '/users/login',
         params: {
           user: credentials
         }
  end

  # This method using id of EXISTING user
  def access_token
    Jwt::EncoderService.call(payload: { user_id: user.id }, type: 'access').data
  end

  def access_token_for(user)
    Jwt::EncoderService.call(payload: { user_id: user.id }, type: 'access').data
  end

  def auth_header
    { Authorization: "Bearer #{access_token}" }
  end

  # Is you want to create auth_header for concrete user
  def auth_header_for(user)
    { Authorization: "Bearer #{access_token_for(user)}"}
  end
end
