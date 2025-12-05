# 📱 RECIPY - MOBILE APP API DOCUMENTATION

**Version:** 2.0  
**Base URL:** `https://recipy-web.fly.dev`  
**Updated:** 5 Decembrie 2024

---

## 📋 TABLE OF CONTENTS

1. [Authentication](#authentication)
2. [Recipes](#recipes)
3. [Users](#users)
4. [Comments & Reviews](#comments--reviews)
5. [Likes & Favorites](#likes--favorites)
6. [Collections](#collections)
7. [Groups](#groups)
8. [Conversations & Messages](#conversations--messages)
9. [AI Chat](#ai-chat)
10. [Meal Planner](#meal-planner)
11. [Notifications](#notifications)
12. [Search](#search)
13. [Image Upload](#image-upload)

---

## 🔐 AUTHENTICATION

### Base URL
```
/ro/  (Romanian)
/en/  (English)
```

### 1. Sign Up
```http
POST /{locale}/users
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "username": "johndoe",
    "password": "password123",
    "password_confirmation": "password123"
  }
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "johndoe",
  "created_at": "2024-12-05T00:00:00.000Z",
  "authentication_token": "abc123xyz..."
}
```

### 2. Sign In
```http
POST /{locale}/users/sign_in
Content-Type: application/json

{
  "user": {
    "login": "user@example.com",
    "password": "password123"
  }
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "johndoe",
  "avatar_url": "https://...",
  "authentication_token": "abc123xyz..."
}
```

### 3. Sign Out
```http
DELETE /{locale}/users/sign_out
Authorization: Bearer {token}
```

### 4. Google OAuth
```http
POST /{locale}/users/auth/google_oauth2
```

---

## 🍳 RECIPES

### Base Endpoints
```
GET    /{locale}/recipes           # List all recipes
GET    /{locale}/recipes/:id       # Get single recipe
POST   /{locale}/recipes           # Create recipe
PATCH  /{locale}/recipes/:id       # Update recipe
DELETE /{locale}/recipes/:id       # Delete recipe
```

### 1. List Recipes (Feed)
```http
GET /{locale}/recipes?page=1&per_page=20&category_id=1&cuisine_id=2
Authorization: Bearer {token}
```

**Query Parameters:**
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 20)
- `category_id` - Filter by category
- `cuisine_id` - Filter by cuisine
- `difficulty` - Filter by difficulty (1-5)
- `max_time` - Max cooking time (minutes)
- `min_rating` - Minimum rating (1-5)
- `search` - Search query
- `sort` - Sort by: `recent`, `popular`, `rating`

**Response (200 OK):**
```json
{
  "recipes": [
    {
      "id": 1,
      "title": "Pasta Carbonara",
      "description": "Classic Italian pasta dish",
      "time_to_make": 30,
      "difficulty": 3,
      "servings": 4,
      "cover_photo_url": "https://...",
      "photos": [
        "https://..."
      ],
      "user": {
        "id": 1,
        "username": "johndoe",
        "avatar_url": "https://..."
      },
      "category": {
        "id": 1,
        "name": "Main Course"
      },
      "cuisine": {
        "id": 2,
        "name": "Italian"
      },
      "likes_count": 42,
      "comments_count": 15,
      "favorites_count": 8,
      "average_rating": 4.5,
      "is_liked": true,
      "is_favorited": false,
      "created_at": "2024-12-05T00:00:00.000Z",
      "updated_at": "2024-12-05T00:00:00.000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 10,
    "total_count": 200,
    "per_page": 20
  }
}
```

### 2. Get Single Recipe
```http
GET /{locale}/recipes/:id
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "title": "Pasta Carbonara",
  "description": "Classic Italian pasta dish with eggs, cheese, and pancetta",
  "time_to_make": 30,
  "difficulty": 3,
  "servings": 4,
  "cover_photo_url": "https://...",
  "photos": ["https://..."],
  "ingredients": [
    {
      "name": "Spaghetti",
      "quantity": "400g"
    },
    {
      "name": "Eggs",
      "quantity": "4"
    }
  ],
  "preparation": "1. Cook pasta\n2. Mix eggs with cheese\n3. Combine everything",
  "user": {
    "id": 1,
    "username": "johndoe",
    "avatar_url": "https://..."
  },
  "category": {
    "id": 1,
    "name": "Main Course"
  },
  "cuisine": {
    "id": 2,
    "name": "Italian"
  },
  "likes_count": 42,
  "comments_count": 15,
  "favorites_count": 8,
  "average_rating": 4.5,
  "is_liked": true,
  "is_favorited": false,
  "created_at": "2024-12-05T00:00:00.000Z",
  "updated_at": "2024-12-05T00:00:00.000Z"
}
```

### 3. Create Recipe
```http
POST /{locale}/recipes
Authorization: Bearer {token}
Content-Type: multipart/form-data

{
  "recipe": {
    "title": "New Recipe",
    "description": "Description",
    "time_to_make": 30,
    "difficulty": 3,
    "servings": 4,
    "ingredients": "[{\"name\":\"Flour\",\"quantity\":\"500g\"}]",
    "preparation": "Step by step instructions",
    "category_id": 1,
    "cuisine_id": 2,
    "photos": [file1, file2],
    "cover_photo": file
  }
}
```

**Response (201 Created):**
```json
{
  "id": 123,
  "title": "New Recipe",
  "message": "Recipe created successfully"
}
```

### 4. Update Recipe
```http
PATCH /{locale}/recipes/:id
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

### 5. Delete Recipe
```http
DELETE /{locale}/recipes/:id
Authorization: Bearer {token}
```

---

## 👤 USERS

### 1. Get User Profile
```http
GET /{locale}/users/:username
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "username": "johndoe",
  "email": "user@example.com",
  "avatar_url": "https://...",
  "bio": "Love cooking!",
  "recipes_count": 25,
  "followers_count": 120,
  "following_count": 80,
  "is_following": false,
  "is_admin": false,
  "created_at": "2024-12-05T00:00:00.000Z",
  "recipes": [
    {
      "id": 1,
      "title": "Recipe Title",
      "cover_photo_url": "https://...",
      "likes_count": 10
    }
  ]
}
```

### 2. Update Profile
```http
PATCH /{locale}/users/:id
Authorization: Bearer {token}
Content-Type: multipart/form-data

{
  "user": {
    "username": "newusername",
    "bio": "New bio",
    "avatar": file
  }
}
```

### 3. Follow User
```http
POST /{locale}/users/:user_id/follow
Authorization: Bearer {token}
```

### 4. Unfollow User
```http
DELETE /{locale}/users/:user_id/unfollow
Authorization: Bearer {token}
```

---

## 💬 COMMENTS & REVIEWS

### 1. Get Recipe Comments
```http
GET /{locale}/recipes/:recipe_id/comments
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "comments": [
    {
      "id": 1,
      "body": "Great recipe!",
      "rating": 5,
      "user": {
        "id": 1,
        "username": "johndoe",
        "avatar_url": "https://..."
      },
      "created_at": "2024-12-05T00:00:00.000Z",
      "replies_count": 3,
      "likes_count": 5
    }
  ]
}
```

### 2. Create Comment/Review
```http
POST /{locale}/recipes/:recipe_id/comments
Authorization: Bearer {token}
Content-Type: application/json

{
  "comment": {
    "body": "Amazing recipe! Loved it!",
    "rating": 5
  }
}
```

**Response (201 Created):**
```json
{
  "id": 123,
  "body": "Amazing recipe!",
  "rating": 5,
  "user": {
    "id": 1,
    "username": "johndoe",
    "avatar_url": "https://..."
  },
  "created_at": "2024-12-05T00:00:00.000Z"
}
```

### 3. Update Comment
```http
PATCH /{locale}/comments/:id
Authorization: Bearer {token}
Content-Type: application/json

{
  "comment": {
    "body": "Updated comment",
    "rating": 4
  }
}
```

### 4. Delete Comment
```http
DELETE /{locale}/comments/:id
Authorization: Bearer {token}
```

**Response (204 No Content)**

---

## ❤️ LIKES & FAVORITES

### 1. Like Recipe
```http
POST /{locale}/recipes/:recipe_id/like
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "liked": true,
  "likes_count": 43
}
```

### 2. Unlike Recipe
```http
DELETE /{locale}/recipes/:recipe_id/like
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "liked": false,
  "likes_count": 42
}
```

### 3. Favorite Recipe
```http
POST /{locale}/recipes/:recipe_id/favorite
Authorization: Bearer {token}
```

### 4. Unfavorite Recipe
```http
DELETE /{locale}/recipes/:recipe_id/favorite
Authorization: Bearer {token}
```

### 5. Get User Favorites
```http
GET /{locale}/favorites
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "favorites": [
    {
      "id": 1,
      "recipe": {
        "id": 1,
        "title": "Pasta Carbonara",
        "cover_photo_url": "https://...",
        "user": {
          "username": "johndoe"
        }
      },
      "created_at": "2024-12-05T00:00:00.000Z"
    }
  ]
}
```

---

## 📚 COLLECTIONS

### 1. List User Collections
```http
GET /{locale}/collections
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "collections": [
    {
      "id": 1,
      "name": "Italian Classics",
      "description": "My favorite Italian recipes",
      "is_public": true,
      "recipes_count": 15,
      "cover_photo_url": "https://...",
      "created_at": "2024-12-05T00:00:00.000Z"
    }
  ]
}
```

### 2. Create Collection
```http
POST /{locale}/collections
Authorization: Bearer {token}
Content-Type: application/json

{
  "collection": {
    "name": "Breakfast Ideas",
    "description": "Quick breakfast recipes",
    "is_public": true
  }
}
```

### 3. Add Recipe to Collection
```http
POST /{locale}/collections/:id/add_recipe
Authorization: Bearer {token}
Content-Type: application/json

{
  "recipe_id": 123
}
```

### 4. Remove Recipe from Collection
```http
DELETE /{locale}/collections/:id/remove_recipe/:recipe_id
Authorization: Bearer {token}
```

---

## 👥 GROUPS

### 1. List User Groups
```http
GET /{locale}/groups
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "groups": [
    {
      "id": 1,
      "name": "Pasta Lovers",
      "description": "Group for pasta enthusiasts",
      "is_private": false,
      "members_count": 42,
      "recipes_count": 18,
      "invite_code": "ABC12345",
      "owner": {
        "id": 1,
        "username": "johndoe"
      },
      "created_at": "2024-12-05T00:00:00.000Z"
    }
  ]
}
```

### 2. Create Group
```http
POST /{locale}/groups
Authorization: Bearer {token}
Content-Type: application/json

{
  "group": {
    "name": "Vegan Recipes",
    "description": "Plant-based recipes",
    "is_private": false
  }
}
```

### 3. Join Group with Code
```http
POST /{locale}/groups/join
Authorization: Bearer {token}
Content-Type: application/json

{
  "invite_code": "ABC12345"
}
```

### 4. Get Group Details
```http
GET /{locale}/groups/:id
Authorization: Bearer {token}
```

### 5. Leave Group
```http
DELETE /{locale}/groups/:id/leave
Authorization: Bearer {token}
```

### 6. Group Chat Messages
```http
GET /{locale}/groups/:id/messages
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "messages": [
    {
      "id": 1,
      "body": "Check out my new recipe!",
      "user": {
        "id": 1,
        "username": "johndoe",
        "avatar_url": "https://..."
      },
      "created_at": "2024-12-05T00:00:00.000Z"
    }
  ]
}
```

### 7. Send Group Message
```http
POST /{locale}/groups/:id/messages
Authorization: Bearer {token}
Content-Type: application/json

{
  "message": {
    "body": "Hello everyone!"
  }
}
```

---

## 💬 CONVERSATIONS & MESSAGES

### 1. List Conversations
```http
GET /{locale}/conversations
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "conversations": [
    {
      "id": 1,
      "other_user": {
        "id": 2,
        "username": "janedoe",
        "avatar_url": "https://..."
      },
      "last_message": {
        "body": "Thanks for the recipe!",
        "created_at": "2024-12-05T00:00:00.000Z"
      },
      "unread_count": 2
    }
  ]
}
```

### 2. Get Conversation Messages
```http
GET /{locale}/conversations/:id
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "other_user": {
    "id": 2,
    "username": "janedoe",
    "avatar_url": "https://..."
  },
  "messages": [
    {
      "id": 1,
      "body": "Hi! How are you?",
      "sender": {
        "id": 1,
        "username": "johndoe"
      },
      "created_at": "2024-12-05T00:00:00.000Z"
    }
  ]
}
```

### 3. Send Message
```http
POST /{locale}/conversations/:id/messages
Authorization: Bearer {token}
Content-Type: application/json

{
  "message": {
    "body": "Hello!"
  }
}
```

### 4. Create Conversation
```http
POST /{locale}/conversations
Authorization: Bearer {token}
Content-Type: application/json

{
  "recipient_id": 2,
  "message": {
    "body": "Hi there!"
  }
}
```

---

## 🤖 AI CHAT

### 1. List AI Conversations
```http
GET /{locale}/ai_conversations
Authorization: Bearer {token}
```

### 2. Create AI Conversation
```http
POST /{locale}/ai_conversations
Authorization: Bearer {token}
Content-Type: application/json

{
  "ai_conversation": {
    "title": "Recipe Help"
  }
}
```

### 3. Send AI Message
```http
POST /{locale}/ai_conversations/:id/messages
Authorization: Bearer {token}
Content-Type: application/json

{
  "message": {
    "content": "How do I make pasta carbonara?"
  }
}
```

**Response (200 OK):**
```json
{
  "user_message": {
    "id": 1,
    "content": "How do I make pasta carbonara?",
    "role": "user"
  },
  "ai_response": {
    "id": 2,
    "content": "Here's how to make pasta carbonara...",
    "role": "assistant",
    "suggested_recipes": [
      {
        "id": 1,
        "title": "Classic Carbonara"
      }
    ]
  }
}
```

---

## 📅 MEAL PLANNER

### 1. Get Meal Plans
```http
GET /{locale}/meal_plans?start_date=2024-12-05&end_date=2024-12-12
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "meal_plans": [
    {
      "id": 1,
      "date": "2024-12-05",
      "meal_type": "breakfast",
      "recipe": {
        "id": 1,
        "title": "Scrambled Eggs",
        "cover_photo_url": "https://..."
      },
      "notes": "Add extra cheese"
    }
  ]
}
```

### 2. Create Meal Plan
```http
POST /{locale}/meal_plans
Authorization: Bearer {token}
Content-Type: application/json

{
  "meal_plan": {
    "recipe_id": 1,
    "date": "2024-12-05",
    "meal_type": "breakfast",
    "notes": "For Sunday brunch"
  }
}
```

**Meal Types:** `breakfast`, `lunch`, `dinner`, `snack`

### 3. Update Meal Plan
```http
PATCH /{locale}/meal_plans/:id
Authorization: Bearer {token}
```

### 4. Delete Meal Plan
```http
DELETE /{locale}/meal_plans/:id
Authorization: Bearer {token}
```

---

## 🔔 NOTIFICATIONS

### 1. Get Notifications
```http
GET /{locale}/notifications?unread_only=true
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "notifications": [
    {
      "id": 1,
      "type": "like",
      "message": "johndoe liked your recipe",
      "actor": {
        "id": 2,
        "username": "johndoe",
        "avatar_url": "https://..."
      },
      "recipe": {
        "id": 1,
        "title": "Pasta"
      },
      "read": false,
      "created_at": "2024-12-05T00:00:00.000Z"
    }
  ],
  "unread_count": 5
}
```

**Notification Types:**
- `like` - Someone liked your recipe
- `comment` - Someone commented on your recipe
- `follow` - Someone followed you
- `favorite` - Someone favorited your recipe
- `mention` - Someone mentioned you

### 2. Mark as Read
```http
PATCH /{locale}/notifications/:id/mark_read
Authorization: Bearer {token}
```

### 3. Mark All as Read
```http
POST /{locale}/notifications/mark_all_read
Authorization: Bearer {token}
```

---

## 🔍 SEARCH

### 1. Global Search
```http
GET /{locale}/search?q=pasta&type=recipes
Authorization: Bearer {token}
```

**Query Parameters:**
- `q` - Search query (required)
- `type` - Search type: `recipes`, `users`, `collections`, `groups`
- `page` - Page number
- `per_page` - Results per page

**Response (200 OK):**
```json
{
  "results": [
    {
      "id": 1,
      "title": "Pasta Carbonara",
      "type": "recipe",
      "cover_photo_url": "https://...",
      "user": {
        "username": "johndoe"
      }
    }
  ],
  "meta": {
    "total_count": 45,
    "query": "pasta"
  }
}
```

---

## 📸 IMAGE UPLOAD

### Upload Recipe Photos
```http
POST /{locale}/recipes/:id/attach_photos
Authorization: Bearer {token}
Content-Type: multipart/form-data

{
  "photos": [file1, file2, file3]
}
```

### Upload Cover Photo
```http
POST /{locale}/recipes/:id/attach_cover
Authorization: Bearer {token}
Content-Type: multipart/form-data

{
  "cover_photo": file
}
```

### Upload Avatar
```http
PATCH /{locale}/users/avatar
Authorization: Bearer {token}
Content-Type: multipart/form-data

{
  "avatar": file
}
```

**Image Requirements:**
- **Max size:** 10MB
- **Formats:** JPG, PNG, WEBP
- **Recommended:** 1200x800px for recipes, 400x400px for avatars

---

## 📊 STATISTICS & ANALYTICS

### 1. Get User Stats
```http
GET /{locale}/users/:username/stats
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "recipes_count": 25,
  "total_likes": 450,
  "total_comments": 120,
  "followers_count": 80,
  "following_count": 60,
  "collections_count": 5,
  "groups_count": 3
}
```

### 2. Get Recipe Analytics
```http
GET /{locale}/recipes/:id/analytics
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "views_count": 1250,
  "likes_count": 42,
  "favorites_count": 8,
  "comments_count": 15,
  "shares_count": 5,
  "average_rating": 4.5,
  "rating_distribution": {
    "5": 8,
    "4": 5,
    "3": 2,
    "2": 0,
    "1": 0
  }
}
```

---

## 🏆 CHALLENGES

### 1. Get Active Challenges
```http
GET /{locale}/challenges
Authorization: Bearer {token}
```

### 2. Join Challenge
```http
POST /{locale}/challenges/:id/join
Authorization: Bearer {token}
```

### 3. Submit Challenge Entry
```http
POST /{locale}/challenges/:id/entries
Authorization: Bearer {token}
Content-Type: application/json

{
  "entry": {
    "recipe_id": 123
  }
}
```

---

## 🔧 UTILITY ENDPOINTS

### 1. Get Categories
```http
GET /{locale}/categories
```

**Response (200 OK):**
```json
{
  "categories": [
    {"id": 1, "name": "Main Course", "display_name": "Main Course"},
    {"id": 2, "name": "Dessert", "display_name": "Dessert"},
    {"id": 3, "name": "Appetizer", "display_name": "Appetizer"}
  ]
}
```

### 2. Get Cuisines
```http
GET /{locale}/cuisines
```

### 3. Get Ingredients
```http
GET /{locale}/ingredients?search=tom
```

---

## 🔒 ERROR RESPONSES

### 401 Unauthorized
```json
{
  "error": "Unauthorized",
  "message": "You must be signed in to access this resource"
}
```

### 403 Forbidden
```json
{
  "error": "Forbidden",
  "message": "You don't have permission to access this resource"
}
```

### 404 Not Found
```json
{
  "error": "Not Found",
  "message": "Recipe not found"
}
```

### 422 Unprocessable Entity
```json
{
  "error": "Validation Failed",
  "messages": [
    "Title can't be blank",
    "Preparation is too short"
  ]
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal Server Error",
  "message": "Something went wrong",
  "error_id": "85ff44ee-b6b1-4077-acea-1a569ce59e3e"
}
```

---

## 🔑 AUTHENTICATION HEADERS

All authenticated requests must include:

```http
Authorization: Bearer {authentication_token}
Accept: application/json
Content-Type: application/json
```

---

## 📦 PAGINATION

Standard pagination format:

**Request:**
```http
GET /{locale}/recipes?page=2&per_page=20
```

**Response Meta:**
```json
{
  "meta": {
    "current_page": 2,
    "total_pages": 10,
    "total_count": 200,
    "per_page": 20,
    "next_page": 3,
    "prev_page": 1
  }
}
```

---

## 🎯 RATE LIMITING

**Limits:**
- **Authenticated:** 1000 requests/hour
- **Unauthenticated:** 100 requests/hour

**Headers:**
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 995
X-RateLimit-Reset: 1638748800
```

---

## 🌐 LOCALIZATION

**Supported Locales:**
- `ro` - Romanian (default)
- `en` - English

**Usage:**
All endpoints support locale prefix: `/{locale}/...`

---

## 📱 MOBILE-SPECIFIC FEATURES

### 1. Device Registration (Push Notifications)
```http
POST /{locale}/devices
Authorization: Bearer {token}
Content-Type: application/json

{
  "device": {
    "token": "fcm_token_here",
    "platform": "ios",
    "app_version": "1.0.0"
  }
}
```

### 2. Report Issue
```http
POST /{locale}/reports
Authorization: Bearer {token}
Content-Type: application/json

{
  "report": {
    "reportable_type": "Recipe",
    "reportable_id": 123,
    "reason": "inappropriate",
    "description": "Contains spam"
  }
}
```

**Report Reasons:**
- `inappropriate`
- `spam`
- `copyright`
- `offensive`
- `other`

---

## 🧪 TESTING

**Test Account:**
```
Email: test@recipy.app
Password: Test123!
```

**Base URLs:**
- **Production:** `https://recipy-web.fly.dev`
- **Staging:** (TBD)

---

## 📞 SUPPORT

**Issues:** GitHub Issues  
**Email:** support@recipy.app  
**Documentation:** This file

---

## 🔄 CHANGELOG

**v2.0 (2024-12-05):**
- ✅ All images use originals (no variant processing)
- ✅ Mobile hamburger menu with slide-in sidebar
- ✅ Theme support (light/dark/system)
- ✅ Enhanced comments with ratings
- ✅ Profile pictures fixed on mobile
- ✅ Auth pages redesigned

**v1.0 (2024-11-01):**
- Initial API release

---

*Last Updated: 5 Decembrie 2024, 01:00*  
*API Version: 2.0*  
*Status: Production Ready*




