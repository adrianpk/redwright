Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "commands", to: "command_queries#create", defaults: { kind: "command" }
      post "queries", to: "command_queries#create", defaults: { kind: "query" }
    end
  end

  resources :users, only: [ :new, :create ]
  resource :session
  resource :current_project, only: [ :update ]
  resources :passwords, param: :token
  resources :projects, only: [ :index, :new, :create, :show ]
  resources :projects, only: [] do
    resources :quizzes, only: [ :index, :show ] do
      collection do
        post :project
        post :use_case
      end
      member do
        post :answer
        post :skip
        post :done
        post :cancel
      end
    end
    resources :protocols, controller: "project_protocols", only: [ :index, :show, :edit, :update, :destroy ] do
      collection do
        get :playbooks
      end
    end
  end
  resources :protocol_templates, controller: "project_protocol_templates", only: [ :index, :show, :create ] do
    collection do
      get :common
      get :common_playbooks
      get "stacks", action: :stacks, as: :stacks
      get "stacks/new", action: :new_stack, as: :new_stack
      post "stacks", action: :create_stack
    end
    member do
      get :playbooks
      post :documents, action: :create_document
    end
    resources :documents, controller: "project_protocol_template_documents", only: [ :edit, :update, :destroy ]
  end
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
  resources :documents, only: [ :index, :show, :new, :create, :edit, :update ] do
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
