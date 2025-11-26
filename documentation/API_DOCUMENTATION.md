# Recipy Mobile API Documentation

## Overview

This document provides complete API documentation for the Recipy mobile application built with **Flutter**. The API is RESTful and uses JSON for request and response bodies.

**Base URL:** `https://your-domain.com/api/v1`

**API Version:** v1

**Target Platform:** Flutter (iOS & Android)

---

## Table of Contents

1. [Authentication](#authentication)
2. [Recipes](#recipes)
3. [Users](#users)
4. [Social Features](#social-features)
5. [Notifications](#notifications)
6. [Conversations & Messages](#conversations--messages)
7. [Categories & Taxonomies](#categories--taxonomies)
8. [Reports & Moderation](#reports--moderation)
9. [Error Handling](#error-handling)
10. [Pagination](#pagination)
11. [Data Models](#data-models)
12. [Flutter Integration Guide](#flutter-integration-guide)

---

## Authentication

All authenticated endpoints require a Bearer token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

### Login

**POST** `/auth/login`

Login with email/username and password.

**Request Body:**
```json
{
  "login": "user@example.com",
  "password": "YourPassword123!"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiJ9...",
    "expires_in": 604800,
    "user": {
      "id": 1,
      "email": "user@example.com",
      "username": "johndoe",
      "first_name": "John",
      "last_name": "Doe",
      "avatar_url": "https://...",
      "email_confirmed": true,
      "created_at": "2025-01-01T00:00:00Z",
      "followers_count": 150,
      "following_count": 75,
      "recipes_count": 25
    }
  }
}
```

**Error Response (401 Unauthorized):**
```json
{
  "success": false,
  "error": "Invalid login credentials"
}
```

---

### Register

**POST** `/auth/register`

Create a new user account.

**Request Body:**
```json
{
  "email": "newuser@example.com",
  "username": "newuser",
  "password": "SecurePass123!",
  "password_confirmation": "SecurePass123!",
  "first_name": "Jane",
  "last_name": "Doe",
  "terms_accepted": true,
  "privacy_policy_accepted": true
}
```

**Password Requirements:**
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiJ9...",
    "expires_in": 604800,
    "user": { ... },
    "message": "Registration successful. Please check your email for confirmation code."
  }
}
```

---

### Logout

**POST** `/auth/logout`

🔒 **Requires Authentication**

Logout the current user. Note: For JWT, logout is handled client-side by removing the token.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "message": "Logged out successfully"
  }
}
```

---

### Refresh Token

**POST** `/auth/refresh_token`

Get a new access token using a refresh token.

**Headers:**
```
Authorization: Bearer <refresh_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "expires_in": 604800
  }
}
```

---

### Forgot Password

**POST** `/auth/forgot_password`

Request password reset email.

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "message": "If the email exists, password reset instructions will be sent"
  }
}
```

---

### Change Password

**POST** `/auth/change_password`

🔒 **Requires Authentication**

Change the current user's password.

**Request Body:**
```json
{
  "current_password": "OldPassword123!",
  "new_password": "NewPassword456!",
  "new_password_confirmation": "NewPassword456!"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "message": "Password changed successfully"
  }
}
```

---

### Verify Email

**POST** `/auth/verify_email`

🔒 **Requires Authentication**

Verify email with 6-digit confirmation code.

**Request Body:**
```json
{
  "code": "123456"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "message": "Email verified successfully",
    "user": { ... }
  }
}
```

---

### Resend Confirmation

**POST** `/auth/resend_confirmation`

🔒 **Requires Authentication**

Resend email confirmation code.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "message": "Confirmation code sent to your email"
  }
}
```

---

### Get Current User

**GET** `/auth/me`

🔒 **Requires Authentication**

Get the currently authenticated user's profile.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "email": "user@example.com",
      "username": "johndoe",
      "first_name": "John",
      "last_name": "Doe",
      "avatar_url": "https://...",
      "email_confirmed": true,
      "created_at": "2025-01-01T00:00:00Z",
      "followers_count": 150,
      "following_count": 75,
      "recipes_count": 25
    }
  }
}
```

---

## Recipes

### List Recipes

**GET** `/recipes`

Get a paginated list of recipes with optional filters.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `page` | integer | Page number (default: 1) |
| `per_page` | integer | Items per page (default: 20, max: 100) |
| `category_id` | integer | Filter by category |
| `cuisine_id` | integer | Filter by cuisine |
| `food_type_id` | integer | Filter by food type |
| `max_calories` | integer | Maximum calories |
| `max_time` | integer | Maximum preparation time (minutes) |
| `min_difficulty` | integer | Minimum difficulty (1-5) |
| `min_healthiness` | integer | Minimum healthiness (1-5) |
| `min_rating` | float | Minimum average rating |

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "recipes": [
      {
        "id": 1,
        "title": "Spaghetti Carbonara",
        "description": "Classic Italian pasta dish",
        "difficulty": 3,
        "time_to_make": 30,
        "healthiness": 3,
        "likes_count": 245,
        "comments_count": 18,
        "nutrition": {
          "calories": 450,
          "protein": 15,
          "fat": 20,
          "carbs": 55,
          "sugar": 3
        },
        "created_at": "2025-01-15T10:30:00Z",
        "updated_at": "2025-01-15T10:30:00Z",
        "user": {
          "id": 5,
          "username": "chef_mario",
          "avatar_url": "https://..."
        },
        "category": { "id": 1, "name": "Paste" },
        "cuisine": { "id": 2, "name": "Italiană" },
        "food_type": { "id": 1, "name": "Prânz" },
        "cover_photo_url": "https://...",
        "photos": [
          { "id": 1, "url": "https://..." },
          { "id": 2, "url": "https://..." }
        ]
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total_items": 150,
      "total_pages": 8
    }
  }
}
```

---

### Get Recipe Feed

**GET** `/recipes/feed`

🔒 **Requires Authentication**

Get personalized recipe feed (recipes from followed users + recommendations).

**Query Parameters:** Same as List Recipes

**Response:** Same structure as List Recipes

---

### Get Top Recipes

**GET** `/recipes/top`

Get top recipes by likes for a specific period.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `period` | string | `day`, `week`, `month`, `year` (default: `day`) |
| `page` | integer | Page number |
| `per_page` | integer | Items per page |

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "recipes": [ ... ],
    "pagination": { ... },
    "period": "day"
  }
}
```

---

### Search Recipes

**GET** `/recipes/search`

Search recipes by title or ingredients.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `q` | string | **Required.** Search query |
| Other filters | | Same as List Recipes |

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "recipes": [ ... ],
    "pagination": { ... },
    "query": "carbonara"
  }
}
```

---

### Get Recipe Details

**GET** `/recipes/:id`

Get full details of a specific recipe.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "recipe": {
      "id": 1,
      "title": "Spaghetti Carbonara",
      "description": "Classic Italian pasta dish",
      "ingredients": "400g spaghetti\n200g pancetta\n4 egg yolks\n100g pecorino romano\nBlack pepper",
      "preparation": "1. Cook pasta...\n2. Fry pancetta...\n3. Mix eggs with cheese...",
      "difficulty": 3,
      "time_to_make": 30,
      "healthiness": 3,
      "likes_count": 245,
      "comments_count": 18,
      "nutrition": { ... },
      "created_at": "2025-01-15T10:30:00Z",
      "user": { ... },
      "category": { ... },
      "cuisine": { ... },
      "food_type": { ... },
      "cover_photo_url": "https://...",
      "photos": [ ... ],
      "is_liked": true,
      "is_favorited": false,
      "average_rating": 4.5,
      "comments": [
        {
          "id": 1,
          "body": "Delicious recipe!",
          "rating": 5,
          "created_at": "2025-01-16T14:00:00Z",
          "user": {
            "id": 10,
            "username": "foodlover",
            "avatar_url": "https://..."
          }
        }
      ]
    }
  }
}
```

---

### Create Recipe

**POST** `/recipes`

🔒 **Requires Authentication**

Create a new recipe.

**Request Body (multipart/form-data):**
```
title: "My New Recipe"
description: "A delicious dish"
ingredients: "Ingredient 1\nIngredient 2\nIngredient 3"
preparation: "Step 1...\nStep 2...\nStep 3..."
category_id: 1
cuisine_id: 2
food_type_id: 1
difficulty: 3
time_to_make: 45
healthiness: 4
nutrition[calories]: 350
nutrition[protein]: 20
nutrition[fat]: 15
nutrition[carbs]: 40
nutrition[sugar]: 5
photos[]: <file>
photos[]: <file>
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "recipe": { ... }
  }
}
```

---

### Update Recipe

**PUT** `/recipes/:id`

🔒 **Requires Authentication** (owner only)

Update an existing recipe.

**Request Body:** Same as Create Recipe (all fields optional)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "recipe": { ... }
  }
}
```

---

### Delete Recipe

**DELETE** `/recipes/:id`

🔒 **Requires Authentication** (owner or admin only)

Delete a recipe.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "message": "Recipe deleted successfully"
  }
}
```

---

## Users

### Search Users

**GET** `/users/search`

Search users by username or email.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `q` | string | **Required.** Search query |

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": 1,
        "username": "johndoe",
        "avatar_url": "https://...",
        "recipes_count": 25,
        "followers_count": 150,
        "following_count": 75
      }
    ]
  }
}
```

---

### Get User Profile

**GET** `/users/:id`

Get a user's public profile.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "username": "johndoe",
      "email": "john@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "avatar_url": "https://...",
      "recipes_count": 25,
      "followers_count": 150,
      "following_count": 75,
      "created_at": "2025-01-01T00:00:00Z",
      "is_following": true,
      "is_followed_by": false
    }
  }
}
```

---

### Get User's Recipes

**GET** `/users/:id/recipes`

🔒 **Requires Authentication**

Get recipes created by a specific user.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `page` | integer | Page number |
| `per_page` | integer | Items per page |

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "recipes": [ ... ],
    "pagination": { ... }
  }
}
```

---

### Get User's Followers

**GET** `/users/:id/followers`

🔒 **Requires Authentication**

Get list of users following this user.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "users": [ ... ],
    "pagination": { ... }
  }
}
```

---

### Get User's Following

**GET** `/users/:id/following`

🔒 **Requires Authentication**

Get list of users this user is following.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "users": [ ... ],
    "pagination": { ... }
  }
}
```

---

### Follow User

**POST** `/users/:id/follow`

🔒 **Requires Authentication**

Follow a user.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "message": "Now following johndoe",
    "following": true
  }
}
```

---

### Unfollow User

**DELETE** `/users/:id/follow`

🔒 **Requires Authentication**

Unfollow a user.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "message": "Unfollowed johndoe",
    "following": false
  }
}
```

---

### Update Profile

**PUT** `/users/profile`

🔒 **Requires Authentication**

Update the current user's profile.

**Request Body:**
```json
{
  "username": "newusername",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+40712345678"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "user": { ... }
  }
}
```

---

### Update Avatar

**POST** `/users/avatar`

🔒 **Requires Authentication**

Upload a new avatar image.

**Request Body (multipart/form-data):**
```
avatar: <file>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "message": "Avatar updated successfully",
    "avatar_url": "https://..."
  }
}
```

---

### Delete Avatar

**DELETE** `/users/avatar`

🔒 **Requires Authentication**

Remove the current user's avatar.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "message": "Avatar removed successfully"
  }
}
```

---

## Social Features

### Like Recipe

**POST** `/recipes/:recipe_id/like`

🔒 **Requires Authentication**

Like a recipe.

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "message": "Recipe liked",
    "liked": true,
    "likes_count": 246
  }
}
```

---

### Unlike Recipe

**DELETE** `/recipes/:recipe_id/like`

🔒 **Requires Authentication**

Remove like from a recipe.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "message": "Recipe unliked",
    "liked": false,
    "likes_count": 245
  }
}
```

---

### Add to Favorites

**POST** `/recipes/:recipe_id/favorite`

🔒 **Requires Authentication**

Add a recipe to favorites.

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "message": "Recipe added to favorites",
    "favorited": true
  }
}
```

---

### Remove from Favorites

**DELETE** `/recipes/:recipe_id/favorite`

🔒 **Requires Authentication**

Remove a recipe from favorites.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "message": "Recipe removed from favorites",
    "favorited": false
  }
}
```

---

### List Favorites

**GET** `/favorites`

🔒 **Requires Authentication**

Get the current user's favorite recipes.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "recipes": [ ... ],
    "pagination": { ... }
  }
}
```

---

### List Comments

**GET** `/recipes/:recipe_id/comments`

Get comments for a recipe.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "comments": [
      {
        "id": 1,
        "body": "Great recipe!",
        "rating": 5,
        "created_at": "2025-01-16T14:00:00Z",
        "user": {
          "id": 10,
          "username": "foodlover",
          "avatar_url": "https://..."
        }
      }
    ],
    "pagination": { ... },
    "average_rating": 4.5
  }
}
```

---

### Create Comment

**POST** `/recipes/:recipe_id/comments`

🔒 **Requires Authentication**

Add a comment to a recipe.

**Request Body:**
```json
{
  "body": "This recipe is amazing!",
  "rating": 5
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "comment": { ... }
  }
}
```

---

### Delete Comment

**DELETE** `/recipes/:recipe_id/comments/:id`

🔒 **Requires Authentication** (owner or admin only)

Delete a comment.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "message": "Comment deleted"
  }
}
```

---

## Notifications

### List Notifications

**GET** `/notifications`

🔒 **Requires Authentication**

Get the current user's notifications.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": 1,
        "type": "like",
        "title": "New Like",
        "message": "johndoe liked your recipe 'Spaghetti Carbonara'",
        "read": false,
        "recipe_id": 1,
        "created_at": "2025-01-16T15:00:00Z"
      }
    ],
    "pagination": { ... },
    "unread_count": 5
  }
}
```

**Notification Types:**
- `like` - Someone liked your recipe
- `comment` - Someone commented on your recipe
- `follow` - Someone started following you
- `message` - Someone sent you a message

---

### Get Unread Count

**GET** `/notifications/unread_count`

🔒 **Requires Authentication**

Get the count of unread notifications.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "unread_count": 5
  }
}
```

---

### Mark as Read

**PATCH** `/notifications/:id/read`

🔒 **Requires Authentication**

Mark a notification as read.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "notification": { ... },
    "unread_count": 4
  }
}
```

---

### Mark All as Read

**POST** `/notifications/mark_all_read`

🔒 **Requires Authentication**

Mark all notifications as read.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "message": "All notifications marked as read",
    "unread_count": 0
  }
}
```

---

### Delete Notification

**DELETE** `/notifications/:id`

🔒 **Requires Authentication**

Delete a notification.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "message": "Notification deleted"
  }
}
```

---

## Conversations & Messages

### List Conversations

**GET** `/conversations`

🔒 **Requires Authentication**

Get all conversations for the current user.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "conversations": [
      {
        "id": 1,
        "other_user": {
          "id": 5,
          "username": "chef_mario",
          "avatar_url": "https://..."
        },
        "last_message": {
          "body": "Thanks for the recipe!",
          "created_at": "2025-01-16T16:00:00Z",
          "is_mine": false
        },
        "unread_count": 2,
        "updated_at": "2025-01-16T16:00:00Z"
      }
    ],
    "unread_count": 5
  }
}
```

---

### Get Conversation

**GET** `/conversations/:id`

🔒 **Requires Authentication**

Get a specific conversation with recent messages.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "conversation": {
      "id": 1,
      "other_user": { ... },
      "last_message": { ... },
      "unread_count": 0,
      "updated_at": "2025-01-16T16:00:00Z",
      "messages": [
        {
          "id": 1,
          "body": "Hi! I loved your recipe!",
          "read": true,
          "is_mine": false,
          "created_at": "2025-01-16T15:55:00Z",
          "user": { ... }
        },
        {
          "id": 2,
          "body": "Thanks! Let me know if you have questions.",
          "read": true,
          "is_mine": true,
          "created_at": "2025-01-16T16:00:00Z",
          "user": { ... }
        }
      ]
    }
  }
}
```

---

### Create Conversation

**POST** `/conversations`

🔒 **Requires Authentication**

Start a new conversation with a user (or get existing one).

**Request Body:**
```json
{
  "recipient_id": 5
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "conversation": { ... }
  }
}
```

---

### Get Messages

**GET** `/conversations/:id/messages`

🔒 **Requires Authentication**

Get paginated messages for a conversation.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "messages": [ ... ],
    "pagination": { ... }
  }
}
```

---

### Send Message

**POST** `/conversations/:id/messages`

🔒 **Requires Authentication**

Send a message in a conversation.

**Request Body:**
```json
{
  "body": "Hello! How are you?",
  "recipe_id": 1
}
```

Note: `recipe_id` is optional. Use it to share a recipe in the message.

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "message": {
      "id": 3,
      "body": "Hello! How are you?",
      "read": false,
      "is_mine": true,
      "created_at": "2025-01-16T17:00:00Z",
      "user": { ... },
      "shared_recipe": {
        "id": 1,
        "title": "Spaghetti Carbonara",
        "cover_photo_url": "https://..."
      }
    }
  }
}
```

---

## Categories & Taxonomies

### List Categories

**GET** `/categories`

Get all recipe categories.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "categories": [
      { "id": 1, "name": "Paste" },
      { "id": 2, "name": "Supe" },
      { "id": 3, "name": "Deserturi" }
    ]
  }
}
```

---

### List Cuisines

**GET** `/cuisines`

Get all cuisines (regions).

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "cuisines": [
      { "id": 1, "name": "Românească" },
      { "id": 2, "name": "Italiană" },
      { "id": 3, "name": "Asiatică" }
    ]
  }
}
```

---

### List Food Types

**GET** `/food_types`

Get all food types (meal types).

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "food_types": [
      { "id": 1, "name": "Mic dejun" },
      { "id": 2, "name": "Prânz" },
      { "id": 3, "name": "Cină" },
      { "id": 4, "name": "Gustare" }
    ]
  }
}
```

---

## Reports & Moderation

The reporting system allows users to report inappropriate content (recipes or users). Reports are reviewed by administrators.

### Get Report Reasons

**GET** `/reports/reasons`

Get all available report reason categories.

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "key": "inappropriate_content",
      "label_ro": "Conținut inadecvat",
      "label_en": "Inappropriate Content"
    },
    {
      "key": "spam",
      "label_ro": "Spam sau publicitate",
      "label_en": "Spam or Advertising"
    },
    {
      "key": "harassment",
      "label_ro": "Hărțuire sau bullying",
      "label_en": "Harassment or Bullying"
    },
    {
      "key": "hate_speech",
      "label_ro": "Discurs de ură",
      "label_en": "Hate Speech"
    },
    {
      "key": "violence",
      "label_ro": "Violență sau conținut periculos",
      "label_en": "Violence or Dangerous Content"
    },
    {
      "key": "copyright",
      "label_ro": "Încălcare drepturi de autor",
      "label_en": "Copyright Violation"
    },
    {
      "key": "misinformation",
      "label_ro": "Informații false",
      "label_en": "Misinformation"
    },
    {
      "key": "other",
      "label_ro": "Altele",
      "label_en": "Other"
    }
  ]
}
```

---

### Report a Recipe

**POST** `/recipes/:id/reports`

Report a recipe for inappropriate content.

**Request Body:**
```json
{
  "report": {
    "reason": "inappropriate_content",
    "description": "Optional detailed description of the issue"
  }
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Report submitted successfully",
  "data": {
    "id": 15,
    "reportable_type": "Recipe",
    "reportable_id": 42,
    "reason": "inappropriate_content",
    "status": "pending",
    "created_at": "2025-11-26T12:00:00Z"
  }
}
```

**Error Response (422 Unprocessable Entity) - Already Reported:**
```json
{
  "success": false,
  "error": "already_reported",
  "message": "You have already reported this content"
}
```

---

### Report a User

**POST** `/users/:id/reports`

Report a user for inappropriate behavior.

**Request Body:**
```json
{
  "report": {
    "reason": "harassment",
    "description": "Optional detailed description of the issue"
  }
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Report submitted successfully",
  "data": {
    "id": 16,
    "reportable_type": "User",
    "reportable_id": 25,
    "reason": "harassment",
    "status": "pending",
    "created_at": "2025-11-26T12:00:00Z"
  }
}
```

**Error Response (422 Unprocessable Entity) - Cannot Report Self:**
```json
{
  "success": false,
  "error": "You cannot report yourself"
}
```

---

### Get My Reports

**GET** `/reports/my_reports`

Get all reports submitted by the current user.

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": 15,
      "reportable_type": "Recipe",
      "reportable_id": 42,
      "reason": "inappropriate_content",
      "reason_label": "Conținut inadecvat",
      "description": "Contains offensive language",
      "status": "pending",
      "created_at": "2025-11-26T12:00:00Z",
      "reviewed_at": null
    },
    {
      "id": 14,
      "reportable_type": "User",
      "reportable_id": 25,
      "reason": "harassment",
      "reason_label": "Hărțuire sau bullying",
      "description": null,
      "status": "resolved_valid",
      "created_at": "2025-11-25T10:00:00Z",
      "reviewed_at": "2025-11-25T15:00:00Z"
    }
  ]
}
```

### Report Status Values

| Status | Description |
|--------|-------------|
| `pending` | Report submitted, awaiting review |
| `under_review` | Report is being reviewed by admin |
| `resolved_valid` | Report was valid, action taken |
| `resolved_invalid` | Report was invalid/spam |
| `dismissed` | Report was dismissed |

---

## Error Handling

All API errors follow this format:

```json
{
  "success": false,
  "error": "Error message describing what went wrong"
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request - Invalid parameters |
| 401 | Unauthorized - Invalid or missing token |
| 403 | Forbidden - Not authorized to perform action |
| 404 | Not Found - Resource doesn't exist |
| 422 | Unprocessable Entity - Validation failed |
| 500 | Internal Server Error |

### Common Error Messages

- `"Unauthorized"` - No valid token provided
- `"Token has expired"` - JWT token has expired, use refresh token
- `"Invalid token"` - Token is malformed or invalid
- `"Resource not found"` - The requested resource doesn't exist
- `"Not authorized"` - User doesn't have permission for this action

---

## Pagination

All list endpoints support pagination with these parameters:

| Parameter | Type | Default | Max | Description |
|-----------|------|---------|-----|-------------|
| `page` | integer | 1 | - | Page number |
| `per_page` | integer | 20 | 100 | Items per page |

Pagination response:

```json
{
  "pagination": {
    "current_page": 1,
    "per_page": 20,
    "total_items": 150,
    "total_pages": 8
  }
}
```

---

## Data Models

### User

```typescript
interface User {
  id: number;
  email: string;
  username: string;
  first_name: string | null;
  last_name: string | null;
  avatar_url: string | null;
  email_confirmed: boolean;
  created_at: string;
  followers_count: number;
  following_count: number;
  recipes_count: number;
  is_following?: boolean;    // Only when authenticated
  is_followed_by?: boolean;  // Only when authenticated
}
```

### Recipe

```typescript
interface Recipe {
  id: number;
  title: string;
  description: string | null;
  ingredients: string;        // Full details only
  preparation: string;        // Full details only
  difficulty: number;         // 1-5
  time_to_make: number;       // Minutes
  healthiness: number;        // 1-5
  likes_count: number;
  comments_count: number;
  nutrition: Nutrition | null;
  created_at: string;
  updated_at: string;
  user: UserSummary;
  category: Category | null;
  cuisine: Cuisine | null;
  food_type: FoodType | null;
  cover_photo_url: string | null;
  photos: Photo[];
  is_liked?: boolean;         // Full details only
  is_favorited?: boolean;     // Full details only
  average_rating?: number;    // Full details only
  comments?: Comment[];       // Full details only
}

interface Nutrition {
  calories: number;
  protein: number;
  fat: number;
  carbs: number;
  sugar: number;
}

interface Photo {
  id: number;
  url: string;
}
```

### Comment

```typescript
interface Comment {
  id: number;
  body: string;
  rating: number | null;  // 1-10
  created_at: string;
  user: UserSummary;
}
```

### Notification

```typescript
interface Notification {
  id: number;
  type: 'like' | 'comment' | 'follow' | 'message';
  title: string;
  message: string;
  read: boolean;
  recipe_id: number | null;
  created_at: string;
}
```

### Conversation

```typescript
interface Conversation {
  id: number;
  other_user: UserSummary;
  last_message: MessageSummary | null;
  unread_count: number;
  updated_at: string;
  messages?: Message[];  // Full details only
}

interface Message {
  id: number;
  body: string;
  read: boolean;
  is_mine: boolean;
  created_at: string;
  user: UserSummary;
  shared_recipe?: RecipeSummary;
}
```

### Category / Cuisine / FoodType

```typescript
interface Category {
  id: number;
  name: string;
}

interface Cuisine {
  id: number;
  name: string;
}

interface FoodType {
  id: number;
  name: string;
}
```

### Report

```typescript
interface Report {
  id: number;
  reportable_type: 'Recipe' | 'User';
  reportable_id: number;
  reason: ReportReason;
  reason_label: string;
  description: string | null;
  status: 'pending' | 'under_review' | 'resolved_valid' | 'resolved_invalid' | 'dismissed';
  created_at: string;
  reviewed_at: string | null;
}

type ReportReason = 
  | 'inappropriate_content'
  | 'spam'
  | 'harassment'
  | 'hate_speech'
  | 'violence'
  | 'copyright'
  | 'misinformation'
  | 'other';

interface ReportReasonOption {
  key: ReportReason;
  label_ro: string;
  label_en: string;
}
```

---

## Rate Limiting

The API implements rate limiting to prevent abuse:

- **General requests:** 300 requests per 5 minutes per IP
- **Login attempts:** 5 requests per 20 seconds per IP
- **Registration:** 3 requests per minute per IP
- **Password reset:** 5 requests per minute per IP

When rate limited, you'll receive a `429 Too Many Requests` response.

---

## Best Practices for Mobile Development

### Token Storage (Flutter)
- Use `flutter_secure_storage` package for secure token storage
- Store refresh token separately for token renewal
- Clear tokens on logout

### Token Refresh
- Check token expiration before making requests
- Implement automatic token refresh using the refresh token
- Handle 401 errors by attempting token refresh

### Offline Support
- Cache recipe data locally for offline viewing
- Queue actions (likes, comments) when offline
- Sync when connection is restored

### Image Handling
- Use appropriate image sizes for thumbnails vs full images
- Implement image caching
- Show placeholders while loading

### Error Handling
- Display user-friendly error messages
- Implement retry logic for network errors
- Log errors for debugging

---

## Flutter Integration Guide

### Recommended Packages

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP & API
  dio: ^5.4.0                    # HTTP client with interceptors
  retrofit: ^4.0.3               # Type-safe API client generator
  json_annotation: ^4.8.1        # JSON serialization
  
  # State Management
  flutter_riverpod: ^2.4.9       # State management
  # OR
  flutter_bloc: ^8.1.3           # Alternative state management
  
  # Storage
  flutter_secure_storage: ^9.0.0 # Secure token storage
  hive_flutter: ^1.1.0           # Local database for caching
  
  # Images & Media
  cached_network_image: ^3.3.1   # Image caching
  image_picker: ^1.0.7           # Photo/video selection
  video_player: ^2.8.2           # Video playback
  
  # UI
  shimmer: ^3.0.0                # Loading placeholders
  pull_to_refresh: ^2.0.0        # Pull to refresh
  infinite_scroll_pagination: ^4.0.0  # Pagination

dev_dependencies:
  build_runner: ^2.4.8
  retrofit_generator: ^8.0.6
  json_serializable: ^6.7.1
```

---

### API Service Setup

Create a base API service with Dio:

```dart
// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'https://your-domain.com/api/v1';
  
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  )) {
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(LogInterceptor(responseBody: true));
  }
  
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the request
            final opts = error.requestOptions;
            final token = await _storage.read(key: 'jwt_token');
            opts.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(opts);
            return handler.resolve(response);
          }
        }
        handler.next(error);
      },
    );
  }
  
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;
      
      final response = await _dio.post('/auth/refresh_token', data: {
        'refresh_token': refreshToken,
      });
      
      if (response.data['success'] == true) {
        await _storage.write(
          key: 'jwt_token', 
          value: response.data['data']['token']
        );
        await _storage.write(
          key: 'refresh_token', 
          value: response.data['data']['refresh_token']
        );
        return true;
      }
    } catch (e) {
      // Token refresh failed
    }
    return false;
  }
  
  Dio get dio => _dio;
}
```

---

### Models

Example model classes:

```dart
// lib/models/user.dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String email;
  final String username;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'followers_count')
  final int followersCount;
  @JsonKey(name: 'following_count')
  final int followingCount;
  @JsonKey(name: 'recipes_count')
  final int recipesCount;
  
  User({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.recipesCount = 0,
  });
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

```dart
// lib/models/recipe.dart
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'recipe.g.dart';

@JsonSerializable()
class Recipe {
  final int id;
  final String title;
  final String? description;
  final String? ingredients;
  final String? preparation;
  final int difficulty;
  final int healthiness;
  @JsonKey(name: 'time_to_make')
  final int? timeToMake;
  @JsonKey(name: 'cover_photo_url')
  final String? coverPhotoUrl;
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  @JsonKey(name: 'likes_count')
  final int likesCount;
  @JsonKey(name: 'comments_count')
  final int commentsCount;
  @JsonKey(name: 'is_liked')
  final bool isLiked;
  @JsonKey(name: 'is_favorited')
  final bool isFavorited;
  final User user;
  @JsonKey(name: 'created_at')
  final String createdAt;
  
  Recipe({
    required this.id,
    required this.title,
    this.description,
    this.ingredients,
    this.preparation,
    this.difficulty = 5,
    this.healthiness = 5,
    this.timeToMake,
    this.coverPhotoUrl,
    this.videoUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isFavorited = false,
    required this.user,
    required this.createdAt,
  });
  
  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeToJson(this);
}
```

```dart
// lib/models/report.dart
import 'package:json_annotation/json_annotation.dart';

part 'report.g.dart';

@JsonSerializable()
class Report {
  final int id;
  @JsonKey(name: 'reportable_type')
  final String reportableType;
  @JsonKey(name: 'reportable_id')
  final int reportableId;
  final String reason;
  @JsonKey(name: 'reason_label')
  final String? reasonLabel;
  final String? description;
  final String status;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'reviewed_at')
  final String? reviewedAt;
  
  Report({
    required this.id,
    required this.reportableType,
    required this.reportableId,
    required this.reason,
    this.reasonLabel,
    this.description,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
  });
  
  factory Report.fromJson(Map<String, dynamic> json) => _$ReportFromJson(json);
  Map<String, dynamic> toJson() => _$ReportToJson(this);
}

@JsonSerializable()
class ReportReason {
  final String key;
  @JsonKey(name: 'label_ro')
  final String labelRo;
  @JsonKey(name: 'label_en')
  final String labelEn;
  
  ReportReason({
    required this.key,
    required this.labelRo,
    required this.labelEn,
  });
  
  factory ReportReason.fromJson(Map<String, dynamic> json) => 
      _$ReportReasonFromJson(json);
}
```

---

### Repository Pattern

```dart
// lib/repositories/recipe_repository.dart
import '../models/recipe.dart';
import '../services/api_service.dart';

class RecipeRepository {
  final ApiService _api;
  
  RecipeRepository(this._api);
  
  Future<List<Recipe>> getFeed({int page = 1}) async {
    final response = await _api.dio.get('/recipes/feed', 
      queryParameters: {'page': page}
    );
    
    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Recipe.fromJson(json)).toList();
    }
    throw Exception(response.data['error'] ?? 'Failed to load feed');
  }
  
  Future<Recipe> getRecipe(int id) async {
    final response = await _api.dio.get('/recipes/$id');
    
    if (response.data['success'] == true) {
      return Recipe.fromJson(response.data['data']);
    }
    throw Exception(response.data['error'] ?? 'Recipe not found');
  }
  
  Future<void> likeRecipe(int id) async {
    await _api.dio.post('/recipes/$id/like');
  }
  
  Future<void> unlikeRecipe(int id) async {
    await _api.dio.delete('/recipes/$id/like');
  }
}
```

```dart
// lib/repositories/report_repository.dart
import '../models/report.dart';
import '../services/api_service.dart';

class ReportRepository {
  final ApiService _api;
  
  ReportRepository(this._api);
  
  Future<List<ReportReason>> getReasons() async {
    final response = await _api.dio.get('/reports/reasons');
    
    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'];
      return data.map((json) => ReportReason.fromJson(json)).toList();
    }
    throw Exception('Failed to load report reasons');
  }
  
  Future<Report> reportRecipe(int recipeId, String reason, {String? description}) async {
    final response = await _api.dio.post('/recipes/$recipeId/reports', data: {
      'report': {
        'reason': reason,
        if (description != null) 'description': description,
      }
    });
    
    if (response.data['success'] == true) {
      return Report.fromJson(response.data['data']);
    }
    
    if (response.data['error'] == 'already_reported') {
      throw AlreadyReportedException();
    }
    throw Exception(response.data['error'] ?? 'Failed to submit report');
  }
  
  Future<Report> reportUser(int userId, String reason, {String? description}) async {
    final response = await _api.dio.post('/users/$userId/reports', data: {
      'report': {
        'reason': reason,
        if (description != null) 'description': description,
      }
    });
    
    if (response.data['success'] == true) {
      return Report.fromJson(response.data['data']);
    }
    throw Exception(response.data['error'] ?? 'Failed to submit report');
  }
  
  Future<List<Report>> getMyReports() async {
    final response = await _api.dio.get('/reports/my_reports');
    
    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Report.fromJson(json)).toList();
    }
    throw Exception('Failed to load reports');
  }
}

class AlreadyReportedException implements Exception {
  final String message = 'You have already reported this content';
}
```

---

### Report Dialog Widget

```dart
// lib/widgets/report_dialog.dart
import 'package:flutter/material.dart';
import '../models/report.dart';
import '../repositories/report_repository.dart';

class ReportDialog extends StatefulWidget {
  final String reportableType; // 'recipe' or 'user'
  final int reportableId;
  final ReportRepository repository;
  
  const ReportDialog({
    Key? key,
    required this.reportableType,
    required this.reportableId,
    required this.repository,
  }) : super(key: key);
  
  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  List<ReportReason>? _reasons;
  String? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadReasons();
  }
  
  Future<void> _loadReasons() async {
    try {
      final reasons = await widget.repository.getReasons();
      setState(() => _reasons = reasons);
    } catch (e) {
      setState(() => _error = 'Failed to load reasons');
    }
  }
  
  Future<void> _submitReport() async {
    if (_selectedReason == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (widget.reportableType == 'recipe') {
        await widget.repository.reportRecipe(
          widget.reportableId,
          _selectedReason!,
          description: _descriptionController.text.isNotEmpty 
              ? _descriptionController.text 
              : null,
        );
      } else {
        await widget.repository.reportUser(
          widget.reportableId,
          _selectedReason!,
          description: _descriptionController.text.isNotEmpty 
              ? _descriptionController.text 
              : null,
        );
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
      }
    } on AlreadyReportedException {
      setState(() {
        _error = 'You have already reported this content';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to submit report';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    
    return AlertDialog(
      title: Text(widget.reportableType == 'recipe' 
          ? 'Report Recipe' 
          : 'Report User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!, style: TextStyle(color: Colors.red)),
              ),
            
            if (_reasons == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              const Text('Select a reason:'),
              const SizedBox(height: 8),
              ...(_reasons!.map((reason) => RadioListTile<String>(
                title: Text(locale == 'ro' ? reason.labelRo : reason.labelEn),
                value: reason.key,
                groupValue: _selectedReason,
                onChanged: (value) => setState(() => _selectedReason = value),
              ))),
              
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Additional details (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedReason != null && !_isLoading 
              ? _submitReport 
              : null,
          child: _isLoading 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
```

---

### Video Player Widget

```dart
// lib/widgets/recipe_video_player.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class RecipeVideoPlayer extends StatefulWidget {
  final String videoUrl;
  
  const RecipeVideoPlayer({Key? key, required this.videoUrl}) : super(key: key);
  
  @override
  State<RecipeVideoPlayer> createState() => _RecipeVideoPlayerState();
}

class _RecipeVideoPlayerState extends State<RecipeVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() => _isInitialized = true);
      });
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          IconButton(
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              size: 50,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

### Localization

The API supports both Romanian (ro) and English (en). Use Flutter's localization:

```dart
// lib/l10n/app_ro.arb
{
  "reportTitle": "Raportează",
  "reportRecipe": "Raportează rețeta",
  "reportUser": "Raportează utilizatorul",
  "reportSuccess": "Raportul a fost trimis cu succes",
  "reportAlreadyReported": "Ai raportat deja acest conținut",
  "reasonInappropriate": "Conținut inadecvat",
  "reasonSpam": "Spam sau publicitate",
  "reasonHarassment": "Hărțuire sau bullying",
  "reasonHateSpeech": "Discurs de ură",
  "reasonViolence": "Violență sau conținut periculos",
  "reasonCopyright": "Încălcare drepturi de autor",
  "reasonMisinformation": "Informații false",
  "reasonOther": "Altele"
}
```

---

## Support

For API support or to report issues, contact:
- Email: support@recipy.app
- GitHub: https://github.com/DragosAndrei1829/Recipy_Web

---

*Last updated: November 2025*

