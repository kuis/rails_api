Brandscopic::Application.routes.draw do


  devise_for :users

  resources :activities

  scope '/admin' do
    resources :users do
      member do
        get :deactivate
      end
    end

    resources :teams do
      member do
        get :deactivate
      end
    end    
  end


  root :to => 'users#dashboard'

end
