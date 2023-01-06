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
**3. Authorization and authentication**
