# Recipy Developer Handover Guide

A comprehensive guide for developers taking over or contributing to the Recipy project. This document explains where to find and modify every major component of the application.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Getting Started](#getting-started)
3. [Directory Structure](#directory-structure)
4. [Modifying the User Interface](#modifying-the-user-interface)
5. [Working with Recipes](#working-with-recipes)
6. [User Authentication & Profiles](#user-authentication--profiles)
7. [Messaging System](#messaging-system)
8. [Notifications](#notifications)
9. [Admin Dashboard](#admin-dashboard)
10. [Theming System](#theming-system)
11. [Internationalization (i18n)](#internationalization-i18n)
12. [Database & Models](#database--models)
13. [JavaScript & Interactivity](#javascript--interactivity)
14. [Styling & CSS](#styling--css)
15. [Email System](#email-system)
16. [File Storage](#file-storage)
17. [Routes & URLs](#routes--urls)
18. [Testing](#testing)
19. [Deployment](#deployment)
20. [Common Tasks](#common-tasks)

---

## Project Overview

Recipy is a social recipe-sharing platform built with Ruby on Rails 7+. Users can create, share, and discover recipes, follow other users, like and favorite recipes, and communicate via direct messaging. The application supports multiple themes, two languages (English and Romanian), and includes a full admin dashboard.

### Technology Stack

- **Backend**: Ruby on Rails 7+
- **Database**: PostgreSQL (production), SQLite (development)
- **Frontend**: ERB templates, Tailwind CSS, Stimulus.js
- **Real-time**: Turbo Streams (Hotwire)
- **Authentication**: Devise with custom extensions
- **File Storage**: Active Storage (local/S3/Azure)
- **Asset Pipeline**: Propshaft

---

## Getting Started

### Prerequisites

```bash
ruby -v      # Ruby 3.2+
rails -v     # Rails 7.1+
node -v      # Node.js 18+
psql --version  # PostgreSQL 14+ (production)
```

### Initial Setup

```bash
cd WebApp
bundle install
rails db:create db:migrate db:seed
bin/dev  # Starts Rails server + Tailwind watcher
```

The application runs on `http://localhost:3000` by default.

---

## Directory Structure

```
WebApp/
├── app/
│   ├── assets/
│   │   ├── stylesheets/
│   │   │   ├── application.css      # Main stylesheet (all custom CSS)
│   │   │   ├── animations.css       # CSS animations
│   │   │   └── tailwind.css         # Tailwind directives
│   │   └── images/                  # Static images
│   ├── controllers/
│   │   ├── admin/                   # Admin controllers
│   │   ├── users/                   # Devise overrides
│   │   └── *.rb                     # Main controllers
│   ├── helpers/                     # View helpers
│   ├── javascript/
│   │   ├── controllers/             # Stimulus controllers
│   │   └── application.js           # JS entry point
│   ├── mailers/                     # Email templates
│   ├── models/                      # ActiveRecord models
│   └── views/
│       ├── layouts/                 # Application layouts
│       ├── recipes/                 # Recipe views
│       ├── users/                   # User profile views
│       ├── devise/                  # Authentication views
│       ├── conversations/           # Messaging views
│       ├── admin/                   # Admin views
│       └── shared/                  # Shared partials
├── config/
│   ├── routes.rb                    # All URL routes
│   ├── locales/                     # Translation files
│   └── initializers/                # App configuration
├── db/
│   ├── migrate/                     # Database migrations
│   ├── schema.rb                    # Current schema
│   └── seeds.rb                     # Seed data
└── documentation/                   # This documentation
```

---

## Modifying the User Interface

### Global Layout & Navigation

If you want to modify the main navigation bar, footer, or overall page structure, edit:

```
app/views/layouts/application.html.erb
```

This file contains:
- **Lines 103-331**: Top navigation bar (brand, search, user menu)
- **Lines 334-366**: Mobile sidebar menu
- **Lines 369-408**: Main content area with three-column grid
- **Lines 410-412**: Footer include
- **Lines 417-624**: JavaScript for interactivity (dropdowns, search, filters)

The navigation includes:
- Brand logo and admin hub link
- Unified search bar with quick filters
- Notifications button (bell icon)
- Messages button (chat icon)
- Add Recipe button
- Profile dropdown with theme selector
- Language switcher (RO/EN)

### Footer

To modify the footer, edit:

```
app/views/layouts/_footer.html.erb
```

### Theme Styles

Dynamic theme CSS variables are set in:

```
app/views/layouts/_theme_styles.html.erb
```

### Flash Messages

If you need to customize how success/error messages appear, look at the flash message handling in `application.html.erb` or create a dedicated partial.

---

## Working with Recipes

### Recipe List Page (Index)

To modify how recipes are displayed on the main feed:

```
app/views/recipes/index.html.erb          # Main index page
app/views/recipes/_card.html.erb          # Individual recipe card
app/views/recipes/_filters_sidebar.html.erb  # Filters panel (right sidebar)
app/views/recipes/_sidebar_quick_filters.html.erb  # Quick filter chips
app/views/recipes/_top_recipes_sidebar.html.erb    # Trending recipes (left sidebar)
app/views/recipes/_sidebar_insights.html.erb       # Statistics sidebar
```

The recipe index controller logic is in:

```
app/controllers/recipes_controller.rb     # index action
```

### Single Recipe Page (Show)

To modify the recipe detail page:

```
app/views/recipes/show.html.erb           # Main show page
app/views/recipes/_show_comments.html.erb # Comments section
```

The show action and related logic:

```
app/controllers/recipes_controller.rb     # show action
```

### Recipe Creation/Editing

To modify the recipe form:

```
app/views/recipes/new.html.erb            # New recipe page wrapper
app/views/recipes/edit.html.erb           # Edit recipe page wrapper
app/views/recipes/_form.html.erb          # Shared form partial
```

Controller logic:

```
app/controllers/recipes_controller.rb     # new, create, edit, update actions
```

### Recipe Model

To add new fields or modify recipe behavior:

```
app/models/recipe.rb                      # Model definition
db/migrate/                               # Create new migration for schema changes
```

---

## User Authentication & Profiles

### Login Page

To modify the login form and design:

```
app/views/devise/sessions/new.html.erb
```

Controller customizations:

```
app/controllers/users/sessions_controller.rb
```

The login system supports both email and username via a `:login` parameter.

### Registration Page

To modify the signup form:

```
app/views/devise/registrations/new.html.erb
```

Controller customizations:

```
app/controllers/users/registrations_controller.rb
```

### Email Confirmation

After registration, users must confirm their email with a 6-digit code:

```
app/views/confirmations/show.html.erb     # Code entry form
app/controllers/confirmations_controller.rb
app/mailers/confirmation_mailer.rb        # Email content
app/views/confirmation_mailer/            # Email templates
```

### Password Reset

```
app/views/devise/passwords/new.html.erb   # Request reset
app/views/devise/passwords/edit.html.erb  # Enter new password
app/controllers/users/passwords_controller.rb
```

### User Profile Page

To modify how user profiles are displayed:

```
app/views/users/show.html.erb             # Profile page
app/controllers/users_controller.rb       # show action
```

### Profile Settings

To modify account settings:

```
app/views/devise/registrations/edit.html.erb
```

### User Model

```
app/models/user.rb
```

Key methods include:
- `find_for_database_authentication` - Login lookup
- `generate_confirmation_code!` - Email confirmation
- `email_confirmed?` - Check confirmation status

---

## Messaging System

### Conversations List

To modify the inbox/conversations list:

```
app/views/conversations/index.html.erb
app/controllers/conversations_controller.rb  # index action
```

### Chat Interface

To modify the chat/messaging interface:

```
app/views/conversations/show.html.erb     # Main chat view
app/views/messages/_message.html.erb      # Individual message bubble
app/controllers/conversations_controller.rb  # show action
app/controllers/messages_controller.rb    # create action
```

The chat interface includes:
- Left panel: Emoji picker, shortcuts, guidelines
- Center: Message history and composer
- Right panel: User profile, activity stats, shared recipes

### Message Model

```
app/models/message.rb
app/models/conversation.rb
```

### Real-time Updates

Messages use Turbo Streams for real-time delivery:

```
app/views/messages/create.turbo_stream.erb
```

---

## Notifications

### Notifications Page

To modify the notifications list:

```
app/views/notifications/index.html.erb
app/views/notifications/_notification.html.erb
app/controllers/notifications_controller.rb
```

### Notification Model

```
app/models/notification.rb
```

Notification types include: `like`, `comment`, `follow`, `message`, `shared_recipe`

### Creating Notifications

Notifications are typically created in controllers when relevant actions occur. Search for `Notification.create` in controllers to see where they're generated.

---

## Admin Dashboard

### Dashboard Home

```
app/views/admin/admin/index.html.erb
app/controllers/admin/admin_controller.rb  # index action
```

### User Management

```
app/views/admin/admin/users.html.erb
app/views/admin/admin/edit_user.html.erb
```

### Recipe Moderation

```
app/views/admin/admin/recipes.html.erb
```

### Site Settings

```
app/views/admin/admin/settings.html.erb
app/views/admin/admin/update_settings action
```

### Category/Cuisine/Food Type Management

```
app/views/admin/admin/categories.html.erb
app/views/admin/admin/cuisines.html.erb
app/views/admin/admin/food_types.html.erb
```

### Theme Management

```
app/views/admin/admin/themes.html.erb
app/views/admin/admin/edit_theme.html.erb
app/views/admin/admin/new_theme.html.erb
```

### Reports

```
app/views/admin/admin/reports.html.erb
```

---

## Theming System

### How Themes Work

Themes are stored in the database and applied via CSS custom properties (variables). Each theme defines colors for:

- Primary, secondary, accent colors
- Background and card colors
- Text colors (primary, secondary)
- Border colors
- Status colors (success, warning, error)
- Footer colors

### Theme Model

```
app/models/theme.rb
```

### Applying Themes

Theme variables are set in the `<head>` of `application.html.erb` (lines 19-39) based on the current user's theme or the site default.

### Creating New Themes

1. Go to Admin Dashboard → Themes
2. Click "New Theme"
3. Fill in all color values
4. Save

Or via Rails console:

```ruby
Theme.create!(
  name: "My Theme",
  primary_color: "#3b82f6",
  secondary_color: "#8b5cf6",
  # ... other colors
)
```

### User Theme Selection

Users can change their theme from the profile dropdown in the navigation bar.

---

## Internationalization (i18n)

### Translation Files

```
config/locales/en.yml          # English translations
config/locales/ro.yml          # Romanian translations
config/locales/devise.en.yml   # Devise English
config/locales/devise.ro.yml   # Devise Romanian
```

### Adding New Translations

1. Add the key to both `en.yml` and `ro.yml`
2. Use in views: `<%= t('key.path') %>`

Example:

```yaml
# en.yml
en:
  recipes:
    new_button: "Add Recipe"

# ro.yml
ro:
  recipes:
    new_button: "Adaugă Rețetă"
```

```erb
<%= t('recipes.new_button') %>
```

### Locale Switching

The language switcher is in the navigation bar. The switch is handled by:

```
app/controllers/application_controller.rb  # switch_locale, set_locale
```

URLs include the locale prefix: `/en/recipes`, `/ro/recipes`

---

## Database & Models

### Schema

The current database schema is in:

```
db/schema.rb
```

### Creating Migrations

```bash
rails generate migration AddFieldToTable field:type
rails db:migrate
```

### Model Files

All models are in `app/models/`:

| Model | Purpose |
|-------|---------|
| `user.rb` | User accounts |
| `recipe.rb` | Recipes |
| `comment.rb` | Recipe comments |
| `like.rb` | Recipe likes |
| `favorite.rb` | Saved recipes |
| `follow.rb` | User follows |
| `conversation.rb` | Chat conversations |
| `message.rb` | Chat messages |
| `notification.rb` | User notifications |
| `shared_recipe.rb` | Shared recipes in chat |
| `category.rb` | Recipe categories |
| `cuisine.rb` | Cuisine types |
| `food_type.rb` | Dietary types |
| `theme.rb` | UI themes |
| `site_setting.rb` | Global settings |

### Common Model Operations

```ruby
# Find user by email or username
User.find_for_database_authentication(login: "john@example.com")

# Get user's recipes
user.recipes

# Get recipe's comments
recipe.comments.includes(:user)

# Check if user liked a recipe
user.likes.exists?(recipe_id: recipe.id)

# Get unread notifications
user.notifications.where(read_at: nil)
```

---

## JavaScript & Interactivity

### Stimulus Controllers

Located in `app/javascript/controllers/`:

```
application.js          # Stimulus application setup
index.js               # Controller imports
hello_controller.js    # Example controller
cookie_consent_controller.js  # Cookie banner
```

### Adding New Stimulus Controllers

```bash
rails generate stimulus controller_name
```

### Inline JavaScript

Many views contain inline `<script>` tags for page-specific functionality. Key locations:

- `application.html.erb` (lines 417-624): Global JS (dropdowns, search, filters)
- `conversations/show.html.erb`: Chat functionality (emoji, image preview, scroll)
- `recipes/_filters_sidebar.html.erb`: Advanced filters toggle

### Turbo Streams

Real-time updates use Turbo Streams. Response templates are named `*.turbo_stream.erb`:

```
app/views/comments/create.turbo_stream.erb
app/views/comments/destroy.turbo_stream.erb
app/views/likes/create.turbo_stream.erb
app/views/likes/destroy.turbo_stream.erb
app/views/favorites/create.turbo_stream.erb
app/views/favorites/destroy.turbo_stream.erb
app/views/follows/create.turbo_stream.erb
app/views/follows/destroy.turbo_stream.erb
app/views/messages/create.turbo_stream.erb
```

---

## Styling & CSS

### Main Stylesheet

All custom CSS is in:

```
app/assets/stylesheets/application.css
```

This file is organized into sections (marked with comments):

| Section | Lines (approx) | Purpose |
|---------|----------------|---------|
| Global layout | 14-150 | Body, app shell, glass panels |
| Navigation | 53-148 | Nav pills, quick links |
| Sidebar | 150-250 | Sidebar cards, filters |
| Feed | 255-470 | Recipe cards, feed layout |
| Buttons | 523-590 | Primary, outline, compact buttons |
| Comments | 594-630 | Comment bubbles, forms |
| Auth pages | 647-755 | Login, signup, confirmation |
| Profile | 908-1013 | User profile components |
| Admin | 1036-1155 | Admin dashboard styles |
| Chat | 1156-1890 | Messaging interface |
| Recipe show | 1889-2145 | Recipe detail page |

### Tailwind CSS

Tailwind is configured in:

```
config/tailwind.config.js (if present)
app/assets/stylesheets/tailwind.css
```

Tailwind classes are used extensively in views alongside custom CSS.

### Animations

CSS animations are in:

```
app/assets/stylesheets/animations.css
```

### Adding New Styles

1. Add CSS to `application.css` in the appropriate section
2. Use CSS custom properties (variables) for theme compatibility:

```css
.my-component {
  background: var(--card-background);
  color: var(--text-primary);
  border: 1px solid var(--border-color);
}
```

---

## Email System

### Mailers

```
app/mailers/application_mailer.rb      # Base mailer
app/mailers/confirmation_mailer.rb     # Email confirmation
app/mailers/mfa_mailer.rb              # MFA codes (if used)
```

### Email Templates

```
app/views/confirmation_mailer/send_confirmation_code.html.erb
app/views/confirmation_mailer/send_confirmation_code.text.erb
app/views/mfa_mailer/send_code.html.erb
app/views/mfa_mailer/send_code.text.erb
```

### Email Layouts

```
app/views/layouts/mailer.html.erb
app/views/layouts/mailer.text.erb
```

### SMTP Configuration

Configure in `config/environments/production.rb` or via environment variables:

```ruby
config.action_mailer.smtp_settings = {
  address: ENV['SMTP_ADDRESS'],
  port: ENV['SMTP_PORT'],
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  authentication: :plain,
  enable_starttls_auto: true
}
```

---

## File Storage

### Active Storage Configuration

```
config/storage.yml
```

This file defines storage services:
- `local` - Local disk storage (development)
- `amazon` - AWS S3
- `azure` - Azure Blob Storage

### Switching Storage Service

In `config/environments/production.rb`:

```ruby
config.active_storage.service = :amazon  # or :azure, :local
```

### Uploading Files

Files are attached to models using Active Storage:

```ruby
# User avatar
user.avatar.attach(params[:avatar])

# Recipe photos
recipe.photos.attach(params[:photos])
```

### Displaying Uploaded Images

```erb
<%= image_tag url_for(user.avatar.variant(resize_to_fill: [100, 100])) %>
```

---

## Routes & URLs

### Routes File

```
config/routes.rb
```

### Key Routes

| Path | Controller#Action | Purpose |
|------|-------------------|---------|
| `/` | `recipes#index` | Homepage/recipe feed |
| `/recipes` | `recipes#index` | Recipe list |
| `/recipes/:id` | `recipes#show` | Single recipe |
| `/recipes/new` | `recipes#new` | New recipe form |
| `/users/:id` | `users#show` | User profile |
| `/favorites` | `favorites#index` | User's favorites |
| `/conversations` | `conversations#index` | Inbox |
| `/conversations/:id` | `conversations#show` | Chat |
| `/notifications` | `notifications#index` | Notifications |
| `/search` | `search#index` | Search results |
| `/admin/dashboard` | `admin/admin#index` | Admin home |

### Authentication Routes (Devise)

| Path | Purpose |
|------|---------|
| `/users/sign_in` | Login |
| `/users/sign_up` | Register |
| `/users/sign_out` | Logout |
| `/users/password/new` | Forgot password |
| `/confirmations/:user_id` | Email confirmation |

### Adding New Routes

```ruby
# config/routes.rb

# Simple route
get '/about', to: 'pages#about'

# RESTful resources
resources :articles

# Nested resources
resources :recipes do
  resources :comments, only: [:create, :destroy]
end

# Admin namespace
namespace :admin do
  resources :users
end
```

---

## Testing

### Test Directory Structure

```
test/
├── controllers/     # Controller tests
├── models/          # Model tests
├── system/          # Browser/integration tests
├── fixtures/        # Test data
└── test_helper.rb   # Test configuration
```

### Running Tests

```bash
rails test                    # All tests
rails test test/models        # Model tests only
rails test test/controllers   # Controller tests only
rails test:system            # System/browser tests
```

### Writing Tests

```ruby
# test/models/recipe_test.rb
require "test_helper"

class RecipeTest < ActiveSupport::TestCase
  test "should not save recipe without title" do
    recipe = Recipe.new
    assert_not recipe.save
  end
end
```

---

## Deployment

### Environment Variables

Required environment variables for production:

```bash
# Database
DATABASE_URL=postgres://user:pass@host:5432/recipy_production

# Rails
SECRET_KEY_BASE=your_secret_key
RAILS_ENV=production

# Email
SMTP_ADDRESS=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password

# Storage (if using S3)
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_BUCKET=your_bucket
AWS_REGION=us-east-1

# OAuth (if used)
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
```

### Deployment Steps

1. Push code to server/container
2. Run `bundle install --deployment`
3. Run `rails db:migrate`
4. Run `rails assets:precompile`
5. Restart application server

### Docker

A `Dockerfile` is included for containerized deployments.

---

## Common Tasks

### Adding a New Page

1. Create route in `config/routes.rb`
2. Create controller action
3. Create view template
4. Add translations if needed

### Adding a New Model Field

1. Generate migration: `rails g migration AddFieldToModel field:type`
2. Run migration: `rails db:migrate`
3. Update model validations if needed
4. Update views/forms to include new field
5. Update controller strong parameters

### Adding a New Model

1. Generate model: `rails g model ModelName field:type`
2. Run migration: `rails db:migrate`
3. Add associations to related models
4. Create controller: `rails g controller ModelNames`
5. Add routes
6. Create views

### Modifying the Navigation

Edit `app/views/layouts/application.html.erb`:
- Top nav: lines 103-331
- Quick links bar: lines 310-331
- Mobile sidebar: lines 334-366

### Changing Theme Colors

1. Admin Dashboard → Themes
2. Edit existing theme or create new one
3. Update color values
4. Save

### Adding a New Language

1. Create `config/locales/xx.yml` (where xx is language code)
2. Add all translation keys
3. Update `config/application.rb` to include new locale
4. Add language switcher option in navigation

### Debugging

```ruby
# In controller or model
Rails.logger.debug "My debug message: #{variable.inspect}"

# In view
<%= debug @object %>

# Rails console
rails console
```

### Database Console

```bash
rails dbconsole
```

---

## Support & Resources

### Documentation Files

- `documentation/STRUCTURE.md` - Code structure overview
- `documentation/MODELS.md` - Model documentation
- `documentation/CONTROLLERS.md` - Controller documentation
- `documentation/HANDOVER_GUIDE.md` - This guide

### External Resources

- [Ruby on Rails Guides](https://guides.rubyonrails.org/)
- [Devise Documentation](https://github.com/heartcombo/devise)
- [Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction)
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)

---

## Quick Reference

### File Locations by Feature

| Feature | Key Files |
|---------|-----------|
| Navigation | `layouts/application.html.erb` |
| Recipe cards | `recipes/_card.html.erb` |
| Recipe form | `recipes/_form.html.erb` |
| Login | `devise/sessions/new.html.erb` |
| Signup | `devise/registrations/new.html.erb` |
| User profile | `users/show.html.erb` |
| Chat | `conversations/show.html.erb` |
| Notifications | `notifications/index.html.erb` |
| Admin | `admin/admin/*.html.erb` |
| Styles | `stylesheets/application.css` |
| Translations | `config/locales/*.yml` |
| Routes | `config/routes.rb` |

### Common Commands

```bash
bin/dev                    # Start development server
rails console              # Rails console
rails db:migrate           # Run migrations
rails db:rollback          # Undo last migration
rails routes               # List all routes
rails generate model X     # Generate model
rails generate controller X  # Generate controller
rails generate migration X # Generate migration
```

---

Last Updated: November 2024


