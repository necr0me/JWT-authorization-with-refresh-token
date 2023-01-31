FactoryBot.define do
  factory :user do
    email { 'johndoe@gmail.com' }
    password { 'password' }
  end

  trait :user_with_refresh_token do
    after :create do |user|
      user.create_refresh_token(value: 'value')
    end
  end
end

