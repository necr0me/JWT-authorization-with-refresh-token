FactoryBot.define do
  factory :user do
    email { 'johndoe@gmail.com' }
    password { 'password'}

    trait :with_refresh_token do
      after :create do |user|
        user.create_refresh_token(value: 'some_value')
      end
    end
  end
end

