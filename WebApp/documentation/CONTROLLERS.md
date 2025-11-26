# Controllers Documentation

Detailed documentation of all controllers in the Recipy application.

## ApplicationController

**File**: `app/controllers/application_controller.rb`

### Purpose
Base controller for all application controllers.

### Key Features
- Locale switching functionality
- Authentication setup
- Authorization helpers

### Methods
- `switch_locale` - Handles language switching
- `set_locale` - Sets current locale from params or default

---

## RecipesController

**File**: `app/controllers/recipes_controller.rb`

### Purpose
Manages recipe CRUD operations and display.

### Actions

#### `index`
- **Purpose**: List all recipes with filtering
- **Filters**: Category, cuisine, food type
- **Sorting**: By date, popularity, likes
- **Pagination**: Uses Kaminari or similar

#### `show`
- **Purpose**: Display single recipe
- **Includes**: Comments, likes, author info
- **Related**: Top recipes sidebar

#### `new`
- **Purpose**: Display recipe creation form
- **Requires**: User authentication

#### `create`
- **Purpose**: Create new recipe
- **Validates**: Required fields
- **Associates**: With current user

#### `edit`
- **Purpose**: Display recipe edit form
- **Authorization**: Only recipe owner or admin

#### `update`
- **Purpose**: Update recipe
- **Authorization**: Only recipe owner or admin

#### `destroy`
- **Purpose**: Delete recipe
- **Authorization**: Only recipe owner or admin

#### `top_recipes`
- **Purpose**: Display trending/popular recipes
- **Sorting**: By likes, comments, views

### Strong Parameters
```ruby
def recipe_params
  params.require(:recipe).permit(:title, :description, :ingredients, 
                                 :instructions, :prep_time, :cook_time, 
                                 :servings, :category_id, :cuisine_id, 
                                 :food_type_id)
end
```

---

## UsersController

**File**: `app/controllers/users_controller.rb`

### Purpose
User profile management and display.

### Actions

#### `show`
- **Purpose**: Display user profile
- **Includes**: User recipes, followers, following count

#### `search`
- **Purpose**: Search for users
- **Query**: By username, email, name
- **Returns**: JSON or HTML results

#### `followers`
- **Purpose**: List user's followers
- **Pagination**: Yes

#### `change_theme`
- **Purpose**: Update user's theme preference
- **Method**: POST
- **Updates**: User's `theme_id`

### Strong Parameters
```ruby
def user_params
  params.require(:user).permit(:theme_id)
end
```

---

## CommentsController

**File**: `app/controllers/comments_controller.rb`

### Purpose
Recipe comment management.

### Actions

#### `create`
- **Purpose**: Add comment to recipe
- **Response**: Turbo Stream for real-time update
- **Validates**: Comment content

#### `destroy`
- **Purpose**: Delete comment
- **Authorization**: Comment owner or admin
- **Response**: Turbo Stream for real-time update

### Strong Parameters
```ruby
def comment_params
  params.require(:comment).permit(:content, :recipe_id)
end
```

---

## LikesController

**File**: `app/controllers/likes_controller.rb`

### Purpose
Recipe like/unlike functionality.

### Actions

#### `create`
- **Purpose**: Like a recipe
- **Response**: Turbo Stream for real-time update
- **Prevents**: Duplicate likes

#### `destroy`
- **Purpose**: Unlike a recipe
- **Response**: Turbo Stream for real-time update

### Strong Parameters
```ruby
def like_params
  params.require(:like).permit(:recipe_id)
end
```

---

## FavoritesController

**File**: `app/controllers/favorites_controller.rb`

### Purpose
Favorite recipe management.

### Actions

#### `create`
- **Purpose**: Add recipe to favorites
- **Response**: Turbo Stream for real-time update

#### `destroy`
- **Purpose**: Remove from favorites
- **Response**: Turbo Stream for real-time update

#### `index`
- **Purpose**: List user's favorite recipes
- **Requires**: User authentication

### Strong Parameters
```ruby
def favorite_params
  params.require(:favorite).permit(:recipe_id)
end
```

---

## FollowsController

**File**: `app/controllers/follows_controller.rb`

### Purpose
User follow/unfollow functionality.

### Actions

#### `create`
- **Purpose**: Follow a user
- **Response**: Turbo Stream for real-time update
- **Prevents**: Following self, duplicate follows

#### `destroy`
- **Purpose**: Unfollow a user
- **Response**: Turbo Stream for real-time update

### Strong Parameters
```ruby
def follow_params
  params.require(:follow).permit(:followed_id)
end
```

---

## ConversationsController

**File**: `app/controllers/conversations_controller.rb`

### Purpose
Direct messaging conversations.

### Actions

#### `index`
- **Purpose**: List all user's conversations
- **Requires**: User authentication
- **Shows**: Unread message counts

#### `show`
- **Purpose**: Display conversation with messages
- **Marks**: Messages as read when viewed
- **Pagination**: Messages paginated

#### `create`
- **Purpose**: Start new conversation
- **Validates**: Recipient exists
- **Prevents**: Duplicate conversations

### Strong Parameters
```ruby
def conversation_params
  params.require(:conversation).permit(:recipient_id)
end
```

---

## MessagesController

**File**: `app/controllers/messages_controller.rb`

### Purpose
Individual message management.

### Actions

#### `create`
- **Purpose**: Send message in conversation
- **Response**: Turbo Stream for real-time update
- **Validates**: Message content
- **Creates**: Notification for recipient

### Strong Parameters
```ruby
def message_params
  params.require(:message).permit(:content, :conversation_id)
end
```

---

## NotificationsController

**File**: `app/controllers/notifications_controller.rb`

### Purpose
User notification management.

### Actions

#### `index`
- **Purpose**: List all user's notifications
- **Requires**: User authentication
- **Sorting**: By date (newest first)
- **Shows**: Unread count

#### `mark_read`
- **Purpose**: Mark single notification as read
- **Response**: Turbo Stream for real-time update
- **Method**: PATCH

#### `mark_all_read`
- **Purpose**: Mark all notifications as read
- **Response**: Turbo Stream for real-time update
- **Method**: POST

---

## SearchController

**File**: `app/controllers/search_controller.rb`

### Purpose
Unified search functionality.

### Actions

#### `index`
- **Purpose**: Search recipes and users
- **Query**: Search term
- **Types**: Recipes, users, or both
- **Returns**: Combined or separate results

### Search Logic
- Searches recipe titles, descriptions, ingredients
- Searches user usernames, names
- Uses PostgreSQL full-text search or LIKE queries

---

## SharedRecipesController

**File**: `app/controllers/shared_recipes_controller.rb`

### Purpose
Recipe sharing via messages.

### Actions

#### `index`
- **Purpose**: List recipes shared with user
- **Requires**: User authentication
- **Shows**: Shared recipes with sender info

#### `create`
- **Purpose**: Share recipe with user
- **Creates**: SharedRecipe record
- **Creates**: Notification for recipient
- **Optional**: Message with share

### Strong Parameters
```ruby
def shared_recipe_params
  params.require(:shared_recipe).permit(:recipe_id, :recipient_id, :message)
end
```

---

## ContactController

**File**: `app/controllers/contact_controller.rb`

### Purpose
Contact page display.

### Actions

#### `show`
- **Purpose**: Display contact information
- **Shows**: Contact form or information

---

## Users::SessionsController

**File**: `app/controllers/users/sessions_controller.rb`

### Purpose
Custom login/logout handling with email or username support.

### Key Features
- Supports login with email or username via `:login` parameter
- Custom error messages
- Processes `:login` parameter before authentication

### Methods

#### `sign_in_params`
- **Purpose**: Override Devise's sign_in_params
- **Converts**: `:login` to `:email` or `:username`
- **Returns**: Sanitized parameters

#### `process_login_param`
- **Purpose**: Convert `:login` parameter
- **Logic**: If contains '@', treat as email; otherwise username
- **Runs**: Before authentication

#### `build_resource`
- **Purpose**: Prevent `:login` attribute assignment error
- **Removes**: `:login` from hash before building User

#### `configure_sign_in_params`
- **Purpose**: Permit `:login` parameter
- **Allows**: `:login`, `:password`, `:remember_me`, `:email`, `:username`

---

## Users::RegistrationsController

**File**: `app/controllers/users/registrations_controller.rb`

### Purpose
Custom signup handling with email confirmation.

### Key Features
- Email confirmation with 6-digit code
- Admin bypass for confirmation
- Generates and sends confirmation code

### Methods

#### `create`
- **Purpose**: Override Devise's create
- **Flow**:
  1. Build user from params
  2. Save user
  3. If admin: auto-confirm and redirect to login
  4. If regular user: generate code, send email, redirect to confirmation
- **Sends**: Confirmation email with code

#### `configure_sign_up_params`
- **Purpose**: Permit signup parameters
- **Allows**: `:username`, `:email`, `:password`, `:password_confirmation`

#### `update_resource`
- **Purpose**: Handle user profile updates
- **Logic**: If password present, update with password; otherwise without

#### `after_update_path_for`
- **Purpose**: Redirect after profile update
- **Returns**: Edit registration path

---

## Users::PasswordsController

**File**: `app/controllers/users/passwords_controller.rb`

### Purpose
Password reset functionality.

### Extends
Standard Devise password controller with customizations.

---

## Users::OmniauthCallbacksController

**File**: `app/controllers/users/omniauth_callbacks_controller.rb`

### Purpose
OAuth authentication callbacks.

### Providers
- Google OAuth2
- Apple

### Methods

#### `google_oauth2`
- **Purpose**: Handle Google OAuth callback
- **Creates**: User if doesn't exist
- **Links**: OAuth account to existing user if email matches

#### `apple`
- **Purpose**: Handle Apple OAuth callback
- **Creates**: User if doesn't exist
- **Links**: OAuth account to existing user if email matches

#### `failure`
- **Purpose**: Handle OAuth failures
- **Redirects**: To sign up page with error message

---

## Admin::AdminController

**File**: `app/controllers/admin/admin_controller.rb`

### Purpose
Admin dashboard and management.

### Before Actions
- `authenticate_admin!` - Requires admin authentication

### Actions

#### `index`
- **Purpose**: Admin dashboard
- **Shows**: Statistics, recent activity

#### `settings`
- **Purpose**: Display site settings form
- **Shows**: All site configuration options

#### `update_settings`
- **Purpose**: Update site settings
- **Method**: PATCH
- **Validates**: Settings parameters

#### `users`
- **Purpose**: List all users
- **Shows**: User management interface
- **Actions**: Edit, delete, reset password

#### `edit_user`
- **Purpose**: Display user edit form
- **Shows**: User details form

#### `update_user`
- **Purpose**: Update user
- **Method**: PATCH
- **Allows**: Admin to update any user

#### `recipes`
- **Purpose**: List all recipes for moderation
- **Actions**: Delete, approve

#### `destroy_recipe`
- **Purpose**: Delete recipe (admin)
- **Method**: DELETE

#### `categories` / `cuisines` / `food_types`
- **Purpose**: Manage content categories
- **Actions**: Create, edit, delete

#### `reports`
- **Purpose**: Display system reports
- **Shows**: Statistics, analytics

#### `export_reports`
- **Purpose**: Export reports as CSV/PDF
- **Method**: GET

#### `reset_password`
- **Purpose**: Admin password reset for users
- **Method**: POST
- **Sends**: Password reset email

#### `change_user_email`
- **Purpose**: Admin email change for users
- **Method**: POST
- **Updates**: User email

---

## ConfirmationsController

**File**: `app/controllers/confirmations_controller.rb`

### Purpose
Email confirmation code verification.

### Actions

#### `show`
- **Purpose**: Display confirmation form
- **Requires**: `user_id` parameter
- **Shows**: 6-digit code input form

#### `verify`
- **Purpose**: Verify confirmation code
- **Method**: POST
- **Validates**: Code matches and not expired
- **Confirms**: User email if valid
- **Redirects**: To login on success, back to form on failure

### Before Actions
- `set_user` - Loads user from `user_id` parameter

---

Last Updated: 2025-11-14

