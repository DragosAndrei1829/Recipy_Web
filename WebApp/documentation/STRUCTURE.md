# Code Structure Documentation

This document provides an overview of the Recipy application structure, organized by component type.

## Table of Contents

1. [Controllers](#controllers)
2. [Models](#models)
3. [Views](#views)
4. [Mailers](#mailers)
5. [Helpers](#helpers)
6. [JavaScript](#javascript)
7. [Routes](#routes)
8. [Configuration](#configuration)

---

## Controllers

### Main Controllers

#### `ApplicationController`
- Base controller for all application controllers
- Handles locale switching
- Sets up authentication and authorization

#### `RecipesController`
- **Purpose**: Manages recipe CRUD operations
- **Key Actions**:
  - `index` - List all recipes with filters
  - `show` - Display single recipe with comments
  - `new` / `create` - Create new recipe
  - `edit` / `update` - Update recipe
  - `destroy` - Delete recipe
  - `top_recipes` - Display trending recipes
- **Filters**: Category, cuisine, food type
- **Associations**: Comments, likes, favorites

#### `UsersController`
- **Purpose**: User profile management
- **Key Actions**:
  - `show` - Display user profile
  - `search` - Search for users
  - `followers` - List user's followers
  - `change_theme` - Update user theme preference

#### `CommentsController`
- **Purpose**: Recipe comment management
- **Key Actions**:
  - `create` - Add comment to recipe
  - `destroy` - Delete comment
- **Uses**: Turbo Streams for real-time updates

#### `LikesController`
- **Purpose**: Recipe like/unlike functionality
- **Key Actions**:
  - `create` - Like a recipe
  - `destroy` - Unlike a recipe
- **Uses**: Turbo Streams for real-time updates

#### `FavoritesController`
- **Purpose**: Favorite recipe management
- **Key Actions**:
  - `create` - Add recipe to favorites
  - `destroy` - Remove from favorites
  - `index` - List user's favorite recipes
- **Uses**: Turbo Streams for real-time updates

#### `FollowsController`
- **Purpose**: User follow/unfollow functionality
- **Key Actions**:
  - `create` - Follow a user
  - `destroy` - Unfollow a user
- **Uses**: Turbo Streams for real-time updates

#### `ConversationsController`
- **Purpose**: Direct messaging between users
- **Key Actions**:
  - `index` - List all conversations
  - `show` - Display conversation with messages
  - `create` - Start new conversation

#### `MessagesController`
- **Purpose**: Individual message management
- **Key Actions**:
  - `create` - Send message in conversation
- **Uses**: Turbo Streams for real-time updates

#### `NotificationsController`
- **Purpose**: User notification management
- **Key Actions**:
  - `index` - List all notifications
  - `mark_read` - Mark notification as read
  - `mark_all_read` - Mark all notifications as read

#### `SearchController`
- **Purpose**: Unified search functionality
- **Key Actions**:
  - `index` - Search recipes and users
- **Search Types**: Recipes, users, combined

#### `SharedRecipesController`
- **Purpose**: Recipe sharing via messages
- **Key Actions**:
  - `index` - List shared recipes
  - `create` - Share recipe with user

#### `ContactController`
- **Purpose**: Contact page display
- **Key Actions**:
  - `show` - Display contact information

### Devise Controllers (Custom)

#### `Users::SessionsController`
- **Purpose**: Custom login/logout handling
- **Key Features**:
  - Supports login with email or username via `:login` parameter
  - Custom error messages
  - Processes `:login` parameter before authentication
- **Methods**:
  - `sign_in_params` - Converts `:login` to `:email` or `:username`
  - `process_login_param` - Handles login parameter conversion
  - `build_resource` - Prevents `:login` attribute assignment error

#### `Users::RegistrationsController`
- **Purpose**: Custom signup handling
- **Key Features**:
  - Email confirmation with 6-digit code
  - Admin bypass for confirmation
  - Generates and sends confirmation code
- **Methods**:
  - `create` - Creates user and sends confirmation code
  - `configure_sign_up_params` - Permits email and username

#### `Users::PasswordsController`
- **Purpose**: Password reset functionality
- **Extends**: Standard Devise password controller

#### `Users::OmniauthCallbacksController`
- **Purpose**: OAuth authentication callbacks
- **Providers**: Google, Apple
- **Handles**: OAuth success and failure callbacks

### Admin Controllers

#### `Admin::AdminController`
- **Purpose**: Admin dashboard and management
- **Key Actions**:
  - `index` - Admin dashboard
  - `settings` - Site settings management
  - `users` - User management
  - `recipes` - Recipe moderation
  - `categories` / `cuisines` / `food_types` - Content management
  - `reports` - System reports
  - `reset_password` - Admin password reset
  - `change_user_email` - Admin email change

### Other Controllers

#### `ConfirmationsController`
- **Purpose**: Email confirmation code verification
- **Key Actions**:
  - `show` - Display confirmation form
  - `verify` - Verify 6-digit confirmation code

---

## Models

### Core Models

#### `User`
- **Purpose**: User account management
- **Devise Modules**: `database_authenticatable`, `registerable`, `recoverable`, `rememberable`, `validatable`, `timeoutable`, `omniauthable`
- **Key Attributes**:
  - `email`, `username`, `password`
  - `first_name`, `last_name`, `phone`
  - `admin`, `account_type`, `theme_id`
  - `confirmation_code`, `confirmation_code_sent_at`, `confirmed_at`
- **Key Methods**:
  - `find_for_database_authentication` - Handles login with email or username
  - `generate_confirmation_code!` - Generates 6-digit confirmation code
  - `confirmation_code_valid?` - Validates confirmation code
  - `confirm_email_with_code!` - Confirms email with code
  - `email_confirmed?` - Checks if email is confirmed
  - `active_for_authentication?` - Override for authentication checks
- **Associations**:
  - `has_many :recipes`, `has_many :comments`, `has_many :likes`
  - `has_many :favorites`, `has_many :follows`, `has_many :followers`
  - `has_many :conversations`, `has_many :messages`
  - `has_many :notifications`, `has_one_attached :avatar`
  - `belongs_to :theme` (optional)

#### `Recipe`
- **Purpose**: Recipe content management
- **Key Attributes**:
  - `title`, `description`, `instructions`
  - `ingredients`, `prep_time`, `cook_time`, `servings`
  - `category_id`, `cuisine_id`, `food_type_id`
  - `user_id`, `likes_count`, `comments_count`
- **Associations**:
  - `belongs_to :user`
  - `belongs_to :category`, `belongs_to :cuisine`, `belongs_to :food_type`
  - `has_many :comments`, `has_many :likes`, `has_many :favorites`
  - `has_many :shared_recipes`

#### `Comment`
- **Purpose**: Recipe comments
- **Key Attributes**: `content`, `user_id`, `recipe_id`
- **Associations**: `belongs_to :user`, `belongs_to :recipe`

#### `Like`
- **Purpose**: Recipe likes
- **Key Attributes**: `user_id`, `recipe_id`
- **Associations**: `belongs_to :user`, `belongs_to :recipe`

#### `Favorite`
- **Purpose**: User favorite recipes
- **Key Attributes**: `user_id`, `recipe_id`
- **Associations**: `belongs_to :user`, `belongs_to :recipe`

#### `Follow`
- **Purpose**: User follow relationships
- **Key Attributes**: `follower_id`, `followed_id`
- **Associations**: `belongs_to :follower`, `belongs_to :followed`

#### `Conversation`
- **Purpose**: Direct messaging conversations
- **Key Attributes**: `sender_id`, `recipient_id`
- **Associations**: `belongs_to :sender`, `belongs_to :recipient`, `has_many :messages`

#### `Message`
- **Purpose**: Individual messages in conversations
- **Key Attributes**: `content`, `user_id`, `conversation_id`, `read_at`
- **Associations**: `belongs_to :user`, `belongs_to :conversation`

#### `Notification`
- **Purpose**: User notifications
- **Key Attributes**: `user_id`, `notifiable_type`, `notifiable_id`, `notification_type`, `read_at`
- **Associations**: `belongs_to :user`, `belongs_to :notifiable` (polymorphic)

#### `SharedRecipe`
- **Purpose**: Shared recipes via messaging
- **Key Attributes**: `recipe_id`, `sender_id`, `recipient_id`, `message`
- **Associations**: `belongs_to :recipe`, `belongs_to :sender`, `belongs_to :recipient`

### Content Models

#### `Category`
- **Purpose**: Recipe categories
- **Key Attributes**: `name`, `description`
- **Associations**: `has_many :recipes`

#### `Cuisine`
- **Purpose**: Recipe cuisines
- **Key Attributes**: `name`, `description`
- **Associations**: `has_many :recipes`

#### `FoodType`
- **Purpose**: Recipe food types (e.g., vegetarian, vegan)
- **Key Attributes**: `name`, `description`
- **Associations**: `has_many :recipes`

### System Models

#### `SiteSetting`
- **Purpose**: Application-wide settings
- **Key Attributes**: Various site configuration options
- **Methods**: `instance` - Singleton pattern for settings

#### `Theme`
- **Purpose**: UI theme management
- **Key Attributes**: `name`, `primary_color`, `secondary_color`, `is_default`
- **Associations**: `has_many :users`
- **Methods**: `default` - Returns default theme

---

## Views

### Layout Structure

#### `layouts/application.html.erb`
- Main application layout
- Includes navigation, flash messages, footer
- Theme styles integration

#### `layouts/mailer.html.erb` / `layouts/mailer.text.erb`
- Email template layouts

### View Organization

Views are organized by controller:
- `recipes/` - Recipe views (index, show, new, edit, top_recipes)
- `users/` - User profile views
- `devise/` - Authentication views (login, signup, password reset)
- `admin/` - Admin dashboard views
- `conversations/` - Messaging views
- `notifications/` - Notification views
- `favorites/` - Favorite recipes views
- `comments/` - Comment views (Turbo Streams)
- `likes/` - Like views (Turbo Streams)
- `follows/` - Follow views (Turbo Streams)
- `messages/` - Message views (Turbo Streams)
- `confirmations/` - Email confirmation views
- `shared_recipes/` - Shared recipe views

### Partial Organization

Common partials:
- `recipes/_card.html.erb` - Recipe card component
- `recipes/_form.html.erb` - Recipe form
- `recipes/_show_comments.html.erb` - Comments section
- `follows/_button.html.erb` - Follow/unfollow button
- `messages/_message.html.erb` - Message display
- `notifications/_notification.html.erb` - Notification display

---

## Mailers

#### `ApplicationMailer`
- Base mailer class

#### `ConfirmationMailer`
- **Purpose**: Email confirmation code delivery
- **Methods**:
  - `send_confirmation_code(user, code)` - Sends 6-digit confirmation code
- **Templates**: `send_confirmation_code.html.erb`, `send_confirmation_code.text.erb`

#### `MfaMailer`
- **Purpose**: Multi-factor authentication codes
- **Methods**: `send_code(user, code)`

---

## Helpers

Helper modules correspond to controllers:
- `ApplicationHelper` - General application helpers
- `RecipesHelper` - Recipe-related helpers
- `UsersHelper` - User-related helpers
- `ConversationsHelper` - Messaging helpers
- `MessagesHelper` - Message helpers
- `ConfirmationsHelper` - Confirmation helpers
- `HomepageHelper` - Homepage helpers
- `SharedRecipesHelper` - Shared recipe helpers

---

## JavaScript

### Stimulus Controllers

Located in `app/javascript/controllers/`:
- `application.js` - Base Stimulus application
- `hello_controller.js` - Example controller

### Turbo Streams

The application uses Turbo Streams for real-time updates:
- Comments (create, destroy)
- Likes (create, destroy)
- Favorites (create, destroy)
- Follows (create, destroy)
- Messages (create)
- Notifications (mark_read)

### Custom JavaScript

- `app/javascript/application.js` - Main JavaScript entry point
- View-specific JavaScript in respective view files

---

## Routes

### Main Routes

- `/` - Recipes index (root)
- `/recipes` - Recipe resources
- `/users/:id` - User profiles
- `/search` - Unified search
- `/top_recipes` - Trending recipes
- `/favorites` - User favorites
- `/conversations` - Messaging
- `/notifications` - Notifications
- `/contact` - Contact page

### Authentication Routes

- `/users/sign_in` - Login
- `/users/sign_up` - Signup
- `/users/sign_out` - Logout
- `/users/password/new` - Password reset
- `/confirmations/:user_id` - Email confirmation

### Admin Routes

- `/admin/dashboard` - Admin dashboard
- `/admin/settings` - Site settings
- `/admin/users` - User management
- `/admin/recipes` - Recipe moderation
- `/admin/categories` - Category management
- `/admin/cuisines` - Cuisine management
- `/admin/food_types` - Food type management
- `/admin/reports` - System reports

### OAuth Routes

- `/users/auth/google_oauth2` - Google OAuth
- `/users/auth/apple` - Apple OAuth
- `/users/auth/:provider/callback` - OAuth callbacks

---

## Configuration

### Initializers

- `config/initializers/devise.rb` - Devise configuration
  - Authentication keys: `[:login]`
  - Custom authentication handling
- `config/initializers/assets.rb` - Asset pipeline configuration
- `config/initializers/filter_parameter_logging.rb` - Parameter filtering

### Locales

- `config/locales/en.yml` - English translations
- `config/locales/ro.yml` - Romanian translations
- `config/locales/devise.en.yml` - Devise English translations
- `config/locales/devise.ro.yml` - Devise Romanian translations

### Database

- `config/database.yml` - Database configuration
- `db/schema.rb` - Database schema
- `db/migrate/` - Database migrations

---

## Key Features Implementation

### Email Confirmation System

1. User signs up → `Users::RegistrationsController#create`
2. Confirmation code generated → `User#generate_confirmation_code!`
3. Email sent → `ConfirmationMailer#send_confirmation_code`
4. User enters code → `ConfirmationsController#verify`
5. Code validated → `User#confirmation_code_valid?`
6. Email confirmed → `User#confirm_email_with_code!`

### Login with Email or Username

1. Form submits `:login` parameter
2. `Users::SessionsController#process_login_param` converts to `:email` or `:username`
3. `User.find_for_database_authentication` searches by email or username
4. Devise authenticates user

### Real-time Updates (Turbo Streams)

- Comments, likes, favorites, follows use Turbo Streams
- Updates happen without full page reload
- Views respond with `.turbo_stream.erb` templates

---

## Development Notes

### Adding New Features

1. **New Model**: Create migration, model, controller, views
2. **New Controller**: Add routes, controller, views, helpers
3. **New Mailer**: Create mailer class and templates
4. **New View**: Add to appropriate controller view folder

### Testing

- Model tests in `test/models/`
- Controller tests in `test/controllers/`
- System tests in `test/system/`

### Deployment

- Configure environment variables
- Set up database
- Run migrations
- Configure email (SMTP)
- Set up OAuth credentials

---

Last Updated: 2025-11-14

