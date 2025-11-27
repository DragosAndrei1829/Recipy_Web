Rails.application.routes.draw do
  get "confirmations/show"
  get "confirmations/verify"

  # API v1 routes
  namespace :api do
    namespace :v1 do
      # Authentication
      post "auth/login", to: "auth#login"
      post "auth/register", to: "auth#register"
      post "auth/logout", to: "auth#logout"
      post "auth/refresh_token", to: "auth#refresh_token"
      post "auth/forgot_password", to: "auth#forgot_password"
      post "auth/change_password", to: "auth#change_password"
      post "auth/verify_email", to: "auth#verify_email"
      post "auth/resend_confirmation", to: "auth#resend_confirmation"
      get "auth/me", to: "auth#me"

      # Recipes
      resources :recipes, only: [ :index, :show, :create, :update, :destroy ] do
        collection do
          get :feed
          get :top
          get :search
        end
        member do
          post :like, to: "likes#create"
          delete :like, to: "likes#destroy"
          post :favorite, to: "favorites#create"
          delete :favorite, to: "favorites#destroy"
        end
        resources :comments, only: [ :index, :create, :destroy ]
      end

      # Favorites
      resources :favorites, only: [ :index ]

      # Users
      resources :users, only: [ :show ] do
        collection do
          get :search
          get :profile, to: "users#profile"
          put :profile, to: "users#update_profile"
          patch :profile, to: "users#update_profile"
          post :avatar, to: "users#update_avatar"
          delete :avatar, to: "users#delete_avatar"
        end
        member do
          get :recipes
          get :followers
          get :following
          post :follow
          delete :follow, to: "users#unfollow"
        end
      end

      # Notifications
      resources :notifications, only: [ :index, :destroy ] do
        member do
          patch :read, to: "notifications#mark_read"
        end
        collection do
          post :mark_all_read
          get :unread_count
        end
      end

      # Conversations & Messages
      resources :conversations, only: [ :index, :show, :create ] do
        member do
          get :messages
          post :messages, to: "conversations#create_message"
        end
      end

      # Categories, Cuisines, Food Types
      get "categories", to: "categories#index"
      get "cuisines", to: "categories#cuisines"
      get "food_types", to: "categories#food_types"

      # Reports
      get "reports/reasons", to: "reports#reasons"
      get "reports/my_reports", to: "reports#my_reports"
      
      # Report a recipe
      resources :recipes, only: [] do
        resources :reports, only: [:create], controller: "reports"
      end
      
      # Report a user
      resources :users, only: [] do
        resources :reports, only: [:create], controller: "reports"
      end

      # Contact/Support
      post "contact", to: "contact#create"

      # Groups
      resources :groups, only: [:index, :show, :create, :update, :destroy] do
        collection do
          post :join
        end
        member do
          delete :leave
          get :members
          get :recipes
          post :recipes, action: :add_recipe
          delete "recipes/:recipe_id", action: :remove_recipe
          get :messages
          post :messages, action: :send_message
        end
      end

      # AI Assistant
      scope :ai, as: :ai do
        post "chat", to: "ai_assistant#chat"
        get "providers", to: "ai_assistant#providers"
        get "conversations", to: "ai_assistant#conversations"
        get "conversations/:id", to: "ai_assistant#show_conversation", as: :conversation
        delete "conversations/:id", to: "ai_assistant#destroy_conversation"
        post "save_recipe", to: "ai_assistant#save_recipe"
      end

      # OAuth for mobile
      post "auth/google", to: "auth#google"
      post "auth/apple", to: "auth#apple"
    end
  end
  # Language switching route (outside locale scope)
  get "/switch_locale/:locale", to: "application#switch_locale", as: :switch_locale

  # OAuth callbacks must be outside locale scope
  devise_for :users, only: :omniauth_callbacks, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # Admin routes (outside locale scope)
  namespace :admin do
    get "/dashboard", to: "admin#index", as: :dashboard
    get "/settings", to: "admin#settings", as: :settings
    patch "/settings", to: "admin#update_settings"
    get "/themes", to: "admin#themes", as: :themes
    get "/themes/new", to: "admin#new_theme", as: :new_theme
    post "/themes", to: "admin#create_theme", as: :create_theme
    get "/themes/:id/edit", to: "admin#edit_theme", as: :edit_theme
    patch "/themes/:id", to: "admin#update_theme", as: :update_theme
    post "/themes/:id/set_default", to: "admin#set_default_theme", as: :set_default_theme
    get "/users", to: "admin#users", as: :users
    get "/users/:id/edit", to: "admin#edit_user", as: :edit_user
    patch "/users/:id", to: "admin#update_user", as: :update_user
    get "/recipes", to: "admin#recipes", as: :recipes
    delete "/recipes/:id", to: "admin#destroy_recipe", as: :destroy_recipe
    get "/categories", to: "admin#categories", as: :categories
    get "/cuisines", to: "admin#cuisines", as: :cuisines
    get "/food_types", to: "admin#food_types", as: :food_types
    get "/reports", to: "admin#reports", as: :reports
    get "/reports/export", to: "admin#export_reports", as: :export_reports
    post "/users/:user_id/reset_password", to: "admin#reset_password", as: :reset_user_password
    post "/users/:user_id/change_email", to: "admin#change_user_email", as: :change_user_email

    # Legal Pages Management
    get "/legal", to: "admin#legal_contents", as: :legal_contents
    get "/legal/:page_type/edit", to: "admin#edit_legal_page", as: :edit_legal_page
    patch "/legal/:page_type", to: "admin#update_legal_page", as: :update_legal_page

    # Moderation Dashboard
    get "/moderation", to: "admin#moderation", as: :moderation
    get "/moderation/reports", to: "admin#moderation_reports", as: :moderation_reports
    get "/moderation/quarantined", to: "admin#quarantined_recipes", as: :quarantined_recipes
    get "/moderation/flagged_users", to: "admin#flagged_users", as: :flagged_users
    
    # Report actions
    patch "/reports/:id/review", to: "admin#review_report", as: :review_report
    
    # Recipe moderation actions
    post "/recipes/:id/quarantine", to: "admin#quarantine_recipe", as: :quarantine_recipe
    post "/recipes/:id/release", to: "admin#release_recipe", as: :release_recipe
    delete "/recipes/:id/delete_reported", to: "admin#delete_reported_recipe", as: :delete_reported_recipe
    
    # User moderation actions
    post "/users/:id/block", to: "admin#block_user", as: :block_user
    post "/users/:id/unblock", to: "admin#unblock_user", as: :unblock_user
  end

  # Legacy route for admin dashboard (redirects to new route)
  get "/adminDashboard", to: redirect("/admin/dashboard")

  scope "(:locale)", locale: /ro|en/ do
    devise_for :users, skip: :omniauth_callbacks, controllers: {
      registrations: "users/registrations",
      sessions: "users/sessions",
      passwords: "users/passwords"
    }

    # Email confirmation routes
    get "/confirmations/:user_id", to: "confirmations#show", as: :confirmation
    post "/confirmations/:user_id/verify", to: "confirmations#verify", as: :verify_confirmation
    resources :recipes
    resources :users, only: [ :show ] do
      collection do
        get :search
      end
      member do
        get :followers
        post :follow, to: "follows#create"
        delete :follow, to: "follows#destroy"
      end
    end

    # Unified search
    get "/search", to: "search#index", as: :search
    get "contact", to: "contact#show", as: :contact
    get "politica-confidentialitate", to: "legal#privacy", as: :privacy_policy
    get "termeni-si-conditii", to: "legal#terms", as: :terms_conditions
    get "politica-cookie", to: "legal#cookies", as: :cookie_policy
    root "recipes#index"

    resources :recipes do
      resource  :like,     only: [ :create, :destroy ]
      resource  :favorite, only: [ :create, :destroy ]
      resources :comments, only: [ :create, :destroy ]
      resources :reports, only: [ :new, :create ], controller: 'reports'
    end

    # User reports
    resources :users, only: [] do
      resources :reports, only: [ :new, :create ], controller: 'reports'
    end

    # Top recipes page
    get "/top_recipes", to: "recipes#top_recipes", as: :top_recipes

    # Groups
    resources :groups do
      member do
        get :chat
        post :send_message
        get :settings
        get :members
        get :recipes
        post :add_recipe
        delete :remove_recipe
        delete :leave
        post :regenerate_invite
        patch :update_member_role
        delete :remove_member
      end
      collection do
        post :join
      end
    end

    resources :favorites, only: [ :index ]

    resources :notifications, only: [ :index ] do
      collection do
        post :mark_all_read
      end
      member do
        patch :mark_read
      end
    end

    resources :conversations, only: [ :index, :show ] do
      collection do
        post :create
      end
      resources :messages, only: [ :create ]
    end

    resources :shared_recipes, only: [ :index, :create ]

    # Theme switching
    post "/users/change_theme", to: "users#change_theme", as: :change_theme

    # AI Assistant
    get "/chef-ai", to: "ai_assistant#index", as: :ai_assistant
    post "/chef-ai/chat", to: "ai_assistant#chat", as: :ai_assistant_chat
    delete "/chef-ai/clear", to: "ai_assistant#clear_conversation", as: :clear_ai_conversation
    post "/chef-ai/save_recipe", to: "ai_assistant#save_recipe", as: :ai_assistant_save_recipe
    post "/chef-ai/set_provider", to: "ai_assistant#set_provider", as: :set_ai_provider
    post "/chef-ai/generate", to: "ai_assistant#generate", as: :ai_assistant_generate
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
