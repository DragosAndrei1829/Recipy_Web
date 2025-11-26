Rails.application.routes.draw do
  get "confirmations/show"
  get "confirmations/verify"
  # Language switching route (outside locale scope)
  get '/switch_locale/:locale', to: 'application#switch_locale', as: :switch_locale
  
  # OAuth callbacks must be outside locale scope
  devise_for :users, only: :omniauth_callbacks, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
  
  # Admin routes (outside locale scope)
  namespace :admin do
    get '/dashboard', to: 'admin#index', as: :dashboard
    get '/settings', to: 'admin#settings', as: :settings
    patch '/settings', to: 'admin#update_settings'
    get '/themes', to: 'admin#themes', as: :themes
    get '/themes/new', to: 'admin#new_theme', as: :new_theme
    post '/themes', to: 'admin#create_theme', as: :create_theme
    get '/themes/:id/edit', to: 'admin#edit_theme', as: :edit_theme
    patch '/themes/:id', to: 'admin#update_theme', as: :update_theme
    post '/themes/:id/set_default', to: 'admin#set_default_theme', as: :set_default_theme
    get '/users', to: 'admin#users', as: :users
    get '/users/:id/edit', to: 'admin#edit_user', as: :edit_user
    patch '/users/:id', to: 'admin#update_user', as: :update_user
    get '/recipes', to: 'admin#recipes', as: :recipes
    delete '/recipes/:id', to: 'admin#destroy_recipe', as: :destroy_recipe
    get '/categories', to: 'admin#categories', as: :categories
    get '/cuisines', to: 'admin#cuisines', as: :cuisines
    get '/food_types', to: 'admin#food_types', as: :food_types
    get '/reports', to: 'admin#reports', as: :reports
    get '/reports/export', to: 'admin#export_reports', as: :export_reports
    post '/users/:user_id/reset_password', to: 'admin#reset_password', as: :reset_user_password
    post '/users/:user_id/change_email', to: 'admin#change_user_email', as: :change_user_email
    
    # Legal Pages Management
    get '/legal', to: 'admin#legal_contents', as: :legal_contents
    get '/legal/:page_type/edit', to: 'admin#edit_legal_page', as: :edit_legal_page
    patch '/legal/:page_type', to: 'admin#update_legal_page', as: :update_legal_page
  end
  
  # Legacy route for admin dashboard (redirects to new route)
  get '/adminDashboard', to: redirect('/admin/dashboard')
  
  scope "(:locale)", locale: /ro|en/ do
    devise_for :users, skip: :omniauth_callbacks, controllers: { 
      registrations: 'users/registrations',
      sessions: 'users/sessions',
      passwords: 'users/passwords'
    }
    
    # Email confirmation routes
    get '/confirmations/:user_id', to: 'confirmations#show', as: :confirmation
    post '/confirmations/:user_id/verify', to: 'confirmations#verify', as: :verify_confirmation
    resources :recipes
    resources :users, only: [:show] do
      collection do
        get :search
      end
      member do
        get :followers
        post :follow, to: 'follows#create'
        delete :follow, to: 'follows#destroy'
      end
    end
    
    # Unified search
    get '/search', to: 'search#index', as: :search
    get 'contact', to: 'contact#show', as: :contact
    get 'politica-confidentialitate', to: 'legal#privacy', as: :privacy_policy
    get 'termeni-si-conditii', to: 'legal#terms', as: :terms_conditions
    get 'politica-cookie', to: 'legal#cookies', as: :cookie_policy
    root 'recipes#index'

    resources :recipes do
      resource  :like,     only: [:create, :destroy]
      resource  :favorite, only: [:create, :destroy]
      resources :comments, only: [:create, :destroy]
    end
    
    # Top recipes page
    get '/top_recipes', to: 'recipes#top_recipes', as: :top_recipes
    
    resources :favorites, only: [:index]
    
    resources :notifications, only: [:index] do
      collection do
        post :mark_all_read
      end
      member do
        patch :mark_read
      end
    end
    
    resources :conversations, only: [:index, :show] do
      collection do
        post :create
      end
      resources :messages, only: [:create]
    end
    
    resources :shared_recipes, only: [:index, :create]
    
    # Theme switching
    post '/users/change_theme', to: 'users#change_theme', as: :change_theme
  end



  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
