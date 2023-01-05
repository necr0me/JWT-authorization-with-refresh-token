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
**2. JWT**

**3. Authorization and authentication**
