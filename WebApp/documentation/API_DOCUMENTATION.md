# Recipy Mobile API Documentation

## Overview

This document provides complete API documentation for the Recipy mobile application. The API is RESTful and uses JSON for request and response bodies.

**Base URL:** `https://your-domain.com/api/v1`

**API Version:** v1

---

## Table of Contents

1. [Authentication](#authentication)
2. [Recipes](#recipes)
3. [Users](#users)
4. [Social Features](#social-features)
5. [Notifications](#notifications)
6. [Conversations & Messages](#conversations--messages)
7. [Categories & Taxonomies](#categories--taxonomies)
8. [Error Handling](#error-handling)
9. [Pagination](#pagination)
10. [Data Models](#data-models)

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

### Token Storage
- Store JWT token securely (Keychain on iOS, EncryptedSharedPreferences on Android)
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

## Support

For API support or to report issues, contact:
- Email: support@recipy.app
- GitHub: https://github.com/DragosAndrei1829/Recipy_Web

---

*Last updated: November 2025*

