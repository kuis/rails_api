Brandscopic::Application.routes.draw do

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  devise_for :users
  ActiveAdmin.routes(self)

  resources :activities

  get '/users/complete-profile', to: 'users#complete', as: :complete_profile
  put '/users/update-profile', to: 'users#update_profile', as: :update_profile

  get "countries/states"

  resources :documents, only: [:destroy]

  resources :user_groups do
    collection do
      put :set_permissions
    end
  end

  resources :users do
    member do
      get :deactivate
    end
  end

  resources :teams do
    member do
      get :deactivate
      get :users
    end
  end

  resources :campaigns do
    member do
      get :deactivate
    end
  end

  resources :events do
    resources :tasks, :documents
    member do
      match 'delete_member/:member_id' => 'events#delete_member', via: :delete, as: :delete_member
    end
  end

  root :to => 'dashboard#index'
end
