Brandscopic::Application.routes.draw do

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  devise_for :users
  ActiveAdmin.routes(self)

  resources :activities

  get '/users/complete-profile', to: 'users#complete', as: :complete_profile
  put '/users/update-profile', to: 'users#update_profile', as: :update_profile

  get "countries/states"

  resources :roles do
    member do
      get :deactivate
      get :activate
    end
    collection do
      put :set_permissions
    end
  end

  resources :users do
    resources :tasks do
      member do
        get :deactivate
        get :activate
      end
    end
    member do
      get :deactivate
      get :activate
    end
  end

  resources :teams do
    member do
      get :deactivate
      get :activate
      match 'members/:member_id' => 'teams#delete_member', via: :delete, as: :delete_member
      match 'members/new' => 'teams#new_member', via: :get, as: :new_member
      match 'members' => 'teams#add_members', via: :post, as: :add_member
    end
  end

  resources :campaigns do
    member do
      get :deactivate
      get :activate
      match 'members/:member_id' => 'campaigns#delete_member', via: :delete, as: :delete_member
      match 'members/new' => 'campaigns#new_member', via: :get, as: :new_member
      match 'members' => 'campaigns#add_members', via: :post, as: :add_member
    end
  end

  resources :events do
    resources :tasks do
      member do
        get :deactivate
        get :activate
      end
      collection do
        get :progress_bar
      end
    end

    resources :documents

    member do
      get :deactivate
      get :activate
      match 'members/:member_id' => 'events#delete_member', via: :delete, as: :delete_member
      match 'members/new' => 'events#new_member', via: :get, as: :new_member
      match 'members' => 'events#add_members', via: :post, as: :add_member
    end
  end

  resources :tasks, only: [:new, :create, :edit, :update] do
    collection do
      get :mine, to: :index, :defaults => {:scope => "user"}, :constraints => { :scope => 'user' }
      get :my_teams, to: :index, :defaults => {:scope => "teams"}, :constraints => { :scope => 'teams' }
    end
    member do
      get :deactivate
      get :activate
    end
    resources :comments
  end

  root :to => 'dashboard#index'
end
