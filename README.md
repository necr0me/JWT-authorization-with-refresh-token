This is my tutorial how to set up JWT authorization with access and refresh tokens.

Here you may read about JSON Web Token: https://en.wikipedia.org/wiki/JSON_Web_Token

This solution is built using jwt-ruby gem. For hashing user passwords, I used bcrypt gem.

**1. Registration**

First of all, we need to install all necessary gems. Open your `Gemfile` and write following: 
```ruby
gem 'bcrypt'
gem 'jwt'
```
and run bundle install:
```
$ bundle install
```
After, we need to create a User model. First of all, create that migration:
```ruby
class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
```
`user.rb` file:
```ruby
class User < ApplicationRecord

  validates :email, presence: true, uniqueness: true  # you may validate it's format with your own regexp
  validates :password, presence: true                 # same with password

  has_secure_password                                 # https://api.rubyonrails.org/classes/ActiveModel/SecurePassword/ClassMethods.html

end
```
Before starting migration, we need to set up db credentials. Firstly, open your `cretendials` file:
```
$ EDITOR=gedit rails credentials:edit
```
And paste in the following, with all your db credentials (in my case db is postgres):
```
db:
  user: <your_db_user>
  password: <your_db_password>
```
Don't forget to save this file.
Then, open your `config/database.yml` file and write following lines: 
```ruby
development:
  <<: *default
  database: JWT_authorization_with_refresh_token_development
  username: <%= Rails.application.credentials.pg[:username] %>
  password: <%= Rails.application.credentials.pg[:password] %>
  
test:
  <<: *default
  database: JWT_authorization_with_refresh_token_test
  username: <%= Rails.application.credentials.pg[:username] %>
  password: <%= Rails.application.credentials.pg[:password] %>  
```
Save this file. Now you may start migrations (don't forget to create db firstly):
```
$ rails db:create db:migrate
```
Now, we can create our `RegistrationsController`:
```
rails g controller Users::Registrations
```
`RegistrationsController` will have two actions - create (registration of user) and destroy (deleting user). Let's write this in `config/routes.rb` file:
```ruby
Rails.application.routes.draw do
  namespace :users do
    post 'sign_up', to: 'registrations#create'
    delete ':id', to: 'registrations#destroy'
  end
end
```
I suggest to move some common logic for  future controllers that will work with users in two concerns - `UserParamable` (for permitting user params) and `UserFindable` (for finding user from id in params before action).

`app/controllers/concerns/user_paramable.rb`:
```ruby
module UserParamable
  extend ActiveSupport::Concern
  
  included do
    private
    
    def user_params
      params.require(:user).permit(:email, :password)
    end
  end
 end
```
`app/controllers/concerns/user_findable.rb`:
```ruby
module UserFindable
  extend ActiveSupport::Concern
  
  included do
    private
    
    def find_user
      @user ||= User.find(params[:id])
    end 
  end
 end
```
Let's implement create and destroy actions in `RegistrationsController` (don't forget to include your concerns):
```ruby
module Users
  class RegistrationsController < ApplicationController
    include UserFindable, UserParamable

    before_action :find_user, only: :destroy

    def create
      user = User.create(user_params)
      if user.persisted?
        render json: { message: 'You have successfully registered' },
               status: 201
      else
        render json: { errors: user.errors.full_messages },
               status: 422
      end
    end

    def destroy
      if @user.destroy
        head 204
      else
        render json: { message: 'Something went wrong',
                       errors: @user.errors.full_messages },
               status: 422
      end
    end
  end
end
```
**2. JWT generation**

Now, let's implement JWT generation. 

Firstly, let's create `RefreshToken` model that will store refresh token in db.

Create migration:
```ruby
class CreateRefreshTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :refresh_tokens do |t|
      t.string :value
      t.belongs_to :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
```

And `RefreshToken` model:
```ruby
class RefreshToken < ApplicationRecord
  belongs_to :user
end
```

And necessary accosiation in `User` model:
```ruby
class User < ApplicationRecord
  has_one :refresh_token, dependent: :destroy
end
```

Don't forget to run migration:
```
$ rails db:migrate
```

All logic of creating JSON Web Tokens will be implemented in service objects. So, we need to create `app/services` folder.
Then, in this folder, create `ApplicationService` class that will be inherited by other service objects:

```ruby
class ApplicationService
  attr_reader :error, :data

  def self.call(...)
    instance = new(...)
    instance.call
    instance
  rescue => e
    instance.send(:fail!, error: e.message)
    instance
  end

  def success?
    error.nil?
  end

  protected

  def success(data: nil)
    @data = data
  end

  alias success! success

  def fail(data: nil, error: )
    @data = data
    @error = error
  end

  alias fail! fail
end
```

Well, let's start implementing JWT.
First of all, to create signature of JWT we need to use some kind of secret keys. So, generate this keys with this command:
```
$ rake secret
```
And paste in `credentials` file:
```
$ EDITOR=gedit rails credentials:edit
```
```
jwt:
  secret_access_key: <your_secret_access_key>
  secret_refresh_key: <your_secret_refresh_key>
```

I would recommend to move all necessary constants in different file. Create `constants.rb` file in `config/initializers` folder and write following:
```ruby
module Constants
  module Jwt
    JWT_SECRET_KEYS = {
      'access' => Rails.application.credentials.jwt[:secret_access_key],
      'refresh' => Rails.application.credentials.jwt[:secret_refresh_key]
    }
    JWT_EXPIRATION_TIMES = {
      'access' => 30.minutes,
      'refresh' => 30.days
    }
    JWT_ALGORITHM = 'HS256'
  end
end
```

Now we able to get this constants like this:
```ruby
Constants::Jwt::JWT_ALGORITHM #=> 'HS256'
```
Or like this:
```ruby
include Constants::Jwt

JWT_ALGORITHM #=> 'HS256'
```

Let's create necessary service objects. At this stage we need 3 services - for encoding jwt, decoding jwt and generating both of refresh and access tokens.

Service for encoding JWTs 

`app/services/jwt/encoder_service.rb`:
```ruby
module Jwt
  class EncoderService < ApplicationService
    include Constants::Jwt

    def initialize(payload:, type:)
      @payload = payload
      @type = type
    end

    def call
      encode(payload, type)
    end

    private

    attr_reader :payload, :type

    def encode(payload, type)
      payload = payload.merge(jwt_data)
      success!(data: JWT.encode(payload, JWT_SECRET_KEYS[type], JWT_ALGORITHM))
    end

    def jwt_data
      {
        exp: JWT_EXPIRATION_TIMES[type].from_now.to_i,
        iat: Time.now.to_i
      }
    end
  end
end
```
Service for decoding JWTs

`app/services/jwt/decoder_service.rb`:
```ruby
module Jwt
  class DecoderService < ApplicationService
    include Constants::Jwt

    def initialize(token:, type:)
      @token = token
      @type = type
    end

    def call
      decode(token, type)
    end

    private

    attr_reader :token, :type

    def decode(token, type)
      decoded = JWT.decode(token, JWT_SECRET_KEYS[type], true, { alg: JWT_ALGORITHM })
      success!(data: decoded)
    end
  end
end
```
Service that generates pair of tokens and saves refresh token to db

`app/services/jwt/token_generator_service.rb`:
```ruby
module Jwt
  class TokensGeneratorService < ApplicationService
    def initialize(user_id:)
      @user_id = user_id
    end

    def call
      generate_tokens
    end

    private

    attr_reader :user_id

    def generate_tokens
      access_token = Jwt::EncoderService.call(payload: { user_id: user_id }, type: 'access')
      refresh_token = Jwt::EncoderService.call(payload: { user_id: user_id }, type: 'refresh')
      return fail!(error: access_token.error) if access_token.data.nil?
      return fail!(error: refresh_token.error) if refresh_token.data.nil?

      user = User.includes(:refresh_token).find(user_id)
      if user.refresh_token.present?
        user.refresh_token.update(value: refresh_token.data)
      else
        user.create_refresh_token(value: refresh_token.data)
      end
      success!(data: [access_token.data, refresh_token.data])
    end
  end
end
```

**3. Authorization and authentication**

Final part.
Authentication, authorization and tokens refreshing will be implented using services objects. All this services will return self as result, so we may to call some methods that we described in `ApplicationService`:

`success?` - boolean value, that shows, if service worked correctly (checks if any error occured during service work)

`data` - some data that should be returned after service work

`error` - error message that occured during service work

This way helps to handle any errors that occur during code execution. 

Firstly, implement `app/services/jwt/tokens_refresher_service.rb`:
```ruby
module Jwt
  class TokensRefresherService < ApplicationService
    def initialize(refresh_token: )
      @refresh_token = refresh_token
    end

    def call
      refresh_tokens
    end

    private

    attr_reader :refresh_token

    def refresh_tokens
      decode_result = Jwt::DecoderService.call(token: refresh_token,
                                               type: 'refresh')
      return fail!(error: decode_result.error) if decode_result.data.nil?

      decoded_token = decode_result.data.first

      user = User.includes(:refresh_token).find(decoded_token['user_id'])
      return fail!(error: "Tokens aren't matching") if user.refresh_token.value != refresh_token

      tokens_result = TokensGeneratorService.call(user_id: decoded_token['user_id'])

      tokens_result.success? ? success!(data: tokens_result.data) : fail!(error: tokens_result.error)
    end
  end
end
```
Then, create `app/services/auth` folder, where auth services will be stored.
After, create `AuthenticationService`:
```ruby
module Auth
  class AuthenticationService < ApplicationService
    def initialize(user_params:)
      @email = user_params[:email]
      @password = user_params[:password]
    end

    def call
      authenticate
    end

    private

    attr_reader :email, :password

    def authenticate
      user = User.find_by(email: email)
      return fail!(error: 'Can\'t find user with such email') if user.nil?

      user.authenticate(password) ? success!(data: user) : fail!(error: 'Invalid password')
    end

  end
end
```
And `AuthorizationService`:
```ruby
module Auth
  class AuthorizationService < ApplicationService
    def initialize(authorization_header:)
      @authorization_header= authorization_header
    end

    def call
      authorize
    end

    private

    attr_reader :authorization_header

    def authorize
      return fail!(error: 'Authorization header is not presented') if authorization_header.nil?

      token = get_token_from_header
      result = Jwt::DecoderService.call(token: token,
                                        type: 'access')
      result.success? ? success!(data: result.data.first) : fail!(error: result.error)
    end

    def get_token_from_header
      authorization_header.split(' ')[1]
    end
  end
end
```
After implementing necessary services, let's modify our `ApplicationController` for: handling authorization, handling RecordNotFound error and making all necessary methods avaiable in all of controllers. But before it, enable cookies in your `config/application.rb` file. Paste this lines in the end of file:
```ruby
  config.middleware.use ActionDispatch::Cookies
  config.middleware.use ActionDispatch::Session::CookieStore
```
I suggest to place authorization and error handling logic at `Authorization` and 'ErrorHandler' concerns:
`app/controllers/concerns/authorization.rb`:
```ruby
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
```
`app/controllers/concerns/error_handler.rb`:
```ruby
module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

    protected

    def record_not_found(e)
      render json: { message: e.message },
             status: 404
    end
  end
end
```
Now, update your `ApplicationController`:
```ruby
class ApplicationController < ActionController::API
  include ActionController::Cookies

  include Authorization
  include ErrorHandler
end
```
Now you able to write in any controller (of course, that inherits from ApplicationController) such line:
```ruby
before_action :authorize!, only: :action_name
```
Which means, that you may require authorization for any actions. So, when you trying to reach `:action_name` endpoint, you need to set up your `Authorization` header. This header should look like this:
```
Authorization: Bearer <your_access_token>
```
Update `RegiststationsController`:
```ruby
before_action :find_user, :authorize!, only: :destroy
```
We are close to the end. Update your `config/routes.rb`:
```ruby
Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  namespace :users do
    post 'login', to: 'sessions#create'
    get 'refresh_tokens', to: 'sessions#refresh_tokens'
    get 'test_method', to: 'sessions#test_method'
    delete 'logout', to: 'sessions#destroy'

    post 'sign_up', to: 'registrations#create'
    delete ':id', to: 'registrations#destroy'
  end
end
```
`test_method` will be used for testing `authorize!` method, that we are previously defined in `Authorization` concern.
Create `SessionsController`:
```
$ rails g controller Users::Sessions
```
Update generated controller with following code:
```ruby
module Users
  class SessionsController < ApplicationController
    include UserParamable

    before_action :authorize!, only: %i[test_method destroy]

    def create
      result = Auth::AuthenticationService.call(user_params: user_params)
      if result.success?
        access_token, refresh_token = Jwt::TokensGeneratorService.call(user_id: result.data.id).data
        cookies['refresh_token'] = {
          value: refresh_token,
          expires: Constants::Jwt::JWT_EXPIRATION_TIMES['refresh'],
          httponly: true }
        render json: { access_token: access_token },
               status: 201
      else
        render json: { errors: [result.error]  },
               status: 400
      end
    end

    def refresh_tokens
      result = Jwt::TokensRefresherService.call(refresh_token: cookies['refresh_token'])
      if result.success?
        access_token, refresh_token = result.data
        cookies['refresh_token'] = {
          value: refresh_token,
          expires: Constants::Jwt::JWT_EXPIRATION_TIMES['refresh'],
          httponly: true }
        render json: { access_token: access_token },
               status: 200
      else
        render json: { errors: [result.error] },
               status: 401
      end
    end

    def test_method
      render json: { user: current_user }
    end

    def destroy
      current_user.refresh_token.destroy
      cookies.delete :refresh_token
      render json: { message: 'You have successfully logged out.' },
             status: 200
    end
  end
end
```
Let me explain some logic here. `login` action takes from your params email and password, gives it to `AuthenticationService` and generates two tokens, if authentication was successful. Refresh token saves to cookies and has `httpOnly` flag, access token is sent as JSON and must be saved in localStorage. 
`refresh_tokens` action takes `refresh_token` from cookies, gives it to `TokensRefresherService`, and, if everything were succesful sends two new tokens back (access token as JSON and refresh token in cookies). Otherwise, server sends 401 response.

**Congratulations!**

You wrote your own authentication with JWT authorization and refresh token! 
Don't forget to cover written code with tests.

**Thank you for your attention!**

<sub>P.S. I am beginner at Ruby and Rails, so mark anything you will find at Issues</sub>

<sub>P.P.S Sorry for bad English :D</sub>
