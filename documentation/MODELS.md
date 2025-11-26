# Models Documentation

Detailed documentation of all ActiveRecord models in the Recipy application.

## User Model

**File**: `app/models/user.rb`

### Purpose
Core user account model with authentication, profile management, and social features.

### Attributes
- `email` (string) - User email address
- `username` (string) - Unique username
- `encrypted_password` (string) - Devise encrypted password
- `first_name` (string) - User's first name
- `last_name` (string) - User's last name
- `phone` (string) - Phone number
- `admin` (boolean) - Admin flag
- `account_type` (string) - Account type
- `theme_id` (integer) - Selected theme
- `provider` (string) - OAuth provider
- `uid` (string) - OAuth UID
- `confirmation_code` (string) - 6-digit email confirmation code
- `confirmation_code_sent_at` (datetime) - When code was sent
- `confirmed_at` (datetime) - When email was confirmed

### Devise Configuration
```ruby
devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :validatable,
       :timeoutable, :omniauthable, omniauth_providers: [:google_oauth2, :apple]
```

### Key Methods

#### Authentication
- `find_for_database_authentication(warden_conditions)` - Custom authentication lookup
  - Handles `:login` parameter (email or username)
  - Searches by email or username
  - Returns user or nil

- `active_for_authentication?` - Override to check email confirmation
  - Returns `super` (allows all users to authenticate)

#### Email Confirmation
- `generate_confirmation_code!` - Generates 6-digit random code
  - Code valid for 15 minutes
  - Saves code and timestamp

- `confirmation_code_valid?(code)` - Validates confirmation code
  - Checks code matches
  - Checks code not expired (15 minutes)

- `confirm_email_with_code!(code)` - Confirms email with code
  - Validates code
  - Sets `confirmed_at` timestamp
  - Clears confirmation code

- `email_confirmed?` - Checks if email is confirmed
  - Returns true if `confirmed_at` is present

#### Virtual Attributes
- `login=` - Prevents `:login` attribute assignment error
- `login` - Returns email or username for display

### Associations
```ruby
has_many :recipes, dependent: :destroy
has_many :comments, dependent: :destroy
has_many :likes, dependent: :destroy
has_many :favorites, dependent: :destroy
has_many :follows, foreign_key: 'follower_id', dependent: :destroy
has_many :followers, class_name: 'Follow', foreign_key: 'followed_id', dependent: :destroy
has_many :sent_conversations, class_name: 'Conversation', foreign_key: 'sender_id'
has_many :received_conversations, class_name: 'Conversation', foreign_key: 'recipient_id'
has_many :messages, dependent: :destroy
has_many :notifications, dependent: :destroy
has_many :shared_recipes, foreign_key: 'sender_id', dependent: :destroy
has_one_attached :avatar
belongs_to :theme, optional: true
```

### Validations
- `username`: presence, uniqueness (unless OAuth user)
- `email`: presence (unless admin), uniqueness

### Callbacks
- `before_save :auto_confirm_existing_users` - Auto-confirms existing users

---

## Recipe Model

**File**: `app/models/recipe.rb`

### Purpose
Recipe content management with ingredients, instructions, and metadata.

### Attributes
- `title` (string) - Recipe title
- `description` (text) - Recipe description
- `ingredients` (text) - Recipe ingredients
- `instructions` (text) - Cooking instructions
- `prep_time` (integer) - Preparation time in minutes
- `cook_time` (integer) - Cooking time in minutes
- `servings` (integer) - Number of servings
- `user_id` (integer) - Recipe author
- `category_id` (integer) - Recipe category
- `cuisine_id` (integer) - Recipe cuisine
- `food_type_id` (integer) - Food type
- `likes_count` (integer) - Cached likes count
- `comments_count` (integer) - Cached comments count

### Associations
```ruby
belongs_to :user
belongs_to :category, optional: true
belongs_to :cuisine, optional: true
belongs_to :food_type, optional: true
has_many :comments, dependent: :destroy
has_many :likes, dependent: :destroy
has_many :favorites, dependent: :destroy
has_many :shared_recipes, dependent: :destroy
```

### Key Methods
- Scopes for filtering by category, cuisine, food_type
- Methods for calculating total time (prep + cook)

### Validations
- `title`: presence
- `description`: presence
- `ingredients`: presence
- `instructions`: presence
- `user_id`: presence

---

## Comment Model

**File**: `app/models/comment.rb`

### Purpose
User comments on recipes.

### Attributes
- `content` (text) - Comment text
- `user_id` (integer) - Comment author
- `recipe_id` (integer) - Recipe being commented on

### Associations
```ruby
belongs_to :user
belongs_to :recipe
```

### Validations
- `content`: presence
- `user_id`: presence
- `recipe_id`: presence

---

## Like Model

**File**: `app/models/like.rb`

### Purpose
User likes on recipes.

### Attributes
- `user_id` (integer) - User who liked
- `recipe_id` (integer) - Recipe being liked

### Associations
```ruby
belongs_to :user
belongs_to :recipe
```

### Validations
- Unique like per user per recipe

---

## Favorite Model

**File**: `app/models/favorite.rb`

### Purpose
User favorite recipes collection.

### Attributes
- `user_id` (integer) - User who favorited
- `recipe_id` (integer) - Recipe being favorited

### Associations
```ruby
belongs_to :user
belongs_to :recipe
```

### Validations
- Unique favorite per user per recipe

---

## Follow Model

**File**: `app/models/follow.rb`

### Purpose
User follow relationships.

### Attributes
- `follower_id` (integer) - User who follows
- `followed_id` (integer) - User being followed

### Associations
```ruby
belongs_to :follower, class_name: 'User'
belongs_to :followed, class_name: 'User'
```

### Validations
- Unique follow relationship
- Cannot follow self

---

## Conversation Model

**File**: `app/models/conversation.rb`

### Purpose
Direct messaging conversations between users.

### Attributes
- `sender_id` (integer) - Conversation initiator
- `recipient_id` (integer) - Conversation recipient

### Associations
```ruby
belongs_to :sender, class_name: 'User'
belongs_to :recipient, class_name: 'User'
has_many :messages, dependent: :destroy
```

### Key Methods
- `other_user(current_user)` - Returns the other user in conversation
- `unread_messages_count(user)` - Counts unread messages for user

---

## Message Model

**File**: `app/models/message.rb`

### Purpose
Individual messages in conversations.

### Attributes
- `content` (text) - Message text
- `user_id` (integer) - Message sender
- `conversation_id` (integer) - Parent conversation
- `read_at` (datetime) - When message was read

### Associations
```ruby
belongs_to :user
belongs_to :conversation
```

### Key Methods
- `mark_as_read!` - Marks message as read
- `read?` - Checks if message is read

---

## Notification Model

**File**: `app/models/notification.rb`

### Purpose
User notifications for various events.

### Attributes
- `user_id` (integer) - Notification recipient
- `notifiable_type` (string) - Type of notifiable object
- `notifiable_id` (integer) - ID of notifiable object
- `notification_type` (string) - Type of notification
- `read_at` (datetime) - When notification was read

### Associations
```ruby
belongs_to :user
belongs_to :notifiable, polymorphic: true
```

### Notification Types
- `like` - Recipe liked
- `comment` - Recipe commented
- `follow` - User followed
- `message` - New message
- `shared_recipe` - Recipe shared

### Key Methods
- `mark_as_read!` - Marks notification as read
- `read?` - Checks if notification is read

---

## SharedRecipe Model

**File**: `app/models/shared_recipe.rb`

### Purpose
Recipes shared between users via messaging.

### Attributes
- `recipe_id` (integer) - Shared recipe
- `sender_id` (integer) - User who shared
- `recipient_id` (integer) - User who received
- `message` (text) - Optional message with share

### Associations
```ruby
belongs_to :recipe
belongs_to :sender, class_name: 'User'
belongs_to :recipient, class_name: 'User'
```

---

## Category Model

**File**: `app/models/category.rb`

### Purpose
Recipe categories (e.g., Breakfast, Dinner, Dessert).

### Attributes
- `name` (string) - Category name
- `description` (text) - Category description

### Associations
```ruby
has_many :recipes, dependent: :destroy
```

---

## Cuisine Model

**File**: `app/models/cuisine.rb`

### Purpose
Recipe cuisines (e.g., Italian, Mexican, Asian).

### Attributes
- `name` (string) - Cuisine name
- `description` (text) - Cuisine description

### Associations
```ruby
has_many :recipes, dependent: :destroy
```

---

## FoodType Model

**File**: `app/models/food_type.rb`

### Purpose
Food types (e.g., Vegetarian, Vegan, Gluten-free).

### Attributes
- `name` (string) - Food type name
- `description` (text) - Food type description

### Associations
```ruby
has_many :recipes, dependent: :destroy
```

---

## SiteSetting Model

**File**: `app/models/site_setting.rb`

### Purpose
Application-wide settings management.

### Attributes
- Various site configuration options

### Key Methods
- `instance` - Singleton pattern for site settings
- `self.instance` - Returns or creates site settings instance

---

## Theme Model

**File**: `app/models/theme.rb`

### Purpose
UI theme management with customizable colors.

### Attributes
- `name` (string) - Theme name
- `primary_color` (string) - Primary theme color
- `secondary_color` (string) - Secondary theme color
- `is_default` (boolean) - Default theme flag

### Associations
```ruby
has_many :users
```

### Key Methods
- `default` - Returns the default theme
- `self.default` - Class method to get default theme

---

Last Updated: 2025-11-14

