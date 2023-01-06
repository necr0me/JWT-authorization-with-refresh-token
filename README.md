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
  host: <your_db_host>
  port: <your_db_port>
```
Don't forget to save this file.
Then, open your `config/database.yml` file and write following lines: 
```ruby
default: &default
  adapter: postgresql
  encoding: unicode
  user: <%= Rails.application.credentials.pg[:user] %>
  password: <%= Rails.application.credentials.pg[:password] %>
  port: <%= Rails.application.credentials.pg[:port] %>
  host: <%= Rails.application.credentials.pg[:host] %>
```
Save this file. Now you may start migrations (don't forget to create db firstly):
```
$ rails db:create db:migrate
```
Now, we can create our RegistrationsController:
```
rails g controller Api::V1::Registrations
```
RegistrationsController will have two actions - create (registration of user) and destroy (deleting user). Let's write this in `config/routes.rb` file:
```ruby
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      namespace :users do
        post 'sign_up', to: 'registrations#create'
        delete ':id', to: 'registrations#destroy'
      end
    end
  end
```
I suggest to move some common logic for  future controllers that will work with users in two concerns - UserParamable (for permitting user params) and UserFindable (for finding user from id in params before action).

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
class Api::V1::Users::RegistrationsController < ApplicationController
  include UserParamble
  include UserFindable
  
  before_action :find_user, only: :destroy

  def create
    @user = User.create(user_params)
    if @user.errors.empty?
      render json: { message: 'You have successfully registered'}, status: 200
    else
      render json: { message: 'Something went wrong', errors: @user.errors}, status: 422
    end
  end

  def destroy
    @user.destroy
    head: 204
  end

end
```
**2. JWT generation**

Now, let's implement JWT generation. 

Firstly, let's create RefreshToken model that will store refresh token in db.

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
  def self.call(...)
    new(...).call
  end
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
      JWT.encode(payload, JWT_SECRET_KEYS[type], JWT_ALGORITHM)
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
      JWT.decode(token, JWT_SECRET_KEYS[type], true, { alg: JWT_ALGORITHM })
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
      access_token = Jwt::EncoderService.call(payload: { user_id: user_id },
                                              type: 'access')
      refresh_token = Jwt::EncoderService.call(payload: { user_id: user_id },
                                               type: 'refresh')
      user = User.includes(:refresh_token).find(user_id)
      if user.refresh_token.present?
        user.refresh_token.update(value: refresh_token)
      else
        user.create_refresh_token(value: refresh_token)
      end
      [access_token, refresh_token]
    end

  end
end
```

**3. Authorization and authentication**

