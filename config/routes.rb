Rails.application.routes.draw do

  namespace :api do
    namespace :v1 do
      post 'login', to: 'sessions#login'
      delete 'logout', to: 'sessions#destroy'

      get 'refresh_tokens', to: 'sessions#refresh_tokens'

      get 'test_method', to: 'sessions#test_method'

      namespace :users do
        post 'sign_up', to: 'registrations#create'
        delete ':id', to: 'registrations#destroy'
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
