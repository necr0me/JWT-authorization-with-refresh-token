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
