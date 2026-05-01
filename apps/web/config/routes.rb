Rails.application.routes.draw do
  resources :users, only: [ :new, :create ]
  resource :session
  resources :passwords, param: :token
  resources :boards, only: [ :index, :show ]
  resources :boards, only: [] do
    resources :tickets, only: [ :new, :create ] do
      collection do
        get :pick
      end
    end
    resources :columns, only: [] do
      collection do
        patch :reorder
      end
    end
  end
  resources :tickets, only: [ :edit, :update ] do
    member do
      patch :move
      patch :archive
      delete :destroy
    end
  end
  resources :document_artifacts, only: [ :index, :show, :new, :create, :edit, :update ] do
    member do
      post :promote
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "boards#index"
end
