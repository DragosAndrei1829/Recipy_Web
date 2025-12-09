# 📱 Recipy Mobile App - Development Guide

**Last Updated:** January 2025  
**API Version:** v1  
**Base URL:** `https://recipy-web.fly.dev/api/v1`

---

## 📋 Table of Contents

1. [API Overview](#api-overview)
2. [Design System](#design-system)
3. [Localization (RO/EN)](#localization-roen)
4. [Authentication](#authentication)
5. [Key Endpoints](#key-endpoints)
6. [Design Guidelines](#design-guidelines)
7. [Implementation Checklist](#implementation-checklist)

---

## 🌐 API Overview

### Base URL
```
Production: https://recipy-web.fly.dev/api/v1
```

### API Documentation
The complete API documentation is available in:
- **Main API Docs:** `../MOBILE_APP_API_DOCUMENTATION.md`
- **Flutter-Specific Docs:** `../documentation/API_DOCUMENTATION.md`

### Response Format
All API responses follow this structure:

**Success:**
```json
{
  "success": true,
  "data": { ... }
}
```

**Error:**
```json
{
  "success": false,
  "error": "Error message"
}
```

---

## 🎨 Design System

### Color Palette

The mobile app **MUST** match the website's color scheme exactly:

#### Primary Colors (Light Theme)
- **Primary (Emerald):** `#10b981` (RGB: 16, 185, 129)
- **Secondary (Teal):** `#14b8a6` (RGB: 20, 184, 166)
- **Accent:** `#059669` (RGB: 5, 150, 105)

#### Background Colors (Light Theme)
- **Background:** `#f0fdf4` (Very light green tint)
- **Card Background:** `#ffffff` (White)
- **Surface:** `#ffffff` (White)

#### Text Colors (Light Theme)
- **Primary Text:** `#111827` (Dark gray)
- **Secondary Text:** `#6b7280` (Medium gray)
- **Muted Text:** `#9ca3af` (Light gray)

#### Status Colors
- **Success:** `#10b981` (Emerald)
- **Error:** `#ef4444` (Red)
- **Warning:** `#f59e0b` (Amber)
- **Info:** `#3b82f6` (Blue)

#### Dark Theme Colors
- **Background:** `#0f0f19` (Very dark blue-gray)
- **Card Background:** `#1a1a2e` (Dark blue-gray)
- **Primary Text:** `#ffffff` (White)
- **Secondary Text:** `#a0a0a0` (Light gray)
- **Primary (Emerald):** `#10b981` (Same as light theme)
- **Secondary (Teal):** `#14b8a6` (Same as light theme)

### Theme Support

The mobile app **MUST** support:
1. **Light Theme** - Default theme matching website
2. **Dark Theme** - Dark mode matching website
3. **System Theme** - Follow device system preference

### Typography

- **Font Family:** Use system fonts for best performance
  - iOS: San Francisco (SF Pro)
  - Android: Roboto
  - Fallback: System default
- **Headings:** Bold weight
- **Body:** Regular weight
- **Font Sizes:**
  - H1: 32px (2rem)
  - H2: 24px (1.5rem)
  - H3: 20px (1.25rem)
  - Body: 16px (1rem)
  - Small: 14px (0.875rem)
  - Caption: 12px (0.75rem)

### Spacing System

Base unit: **4px**

Common spacing values:
- `4px` (0.25rem) - xs
- `8px` (0.5rem) - sm
- `12px` (0.75rem) - md
- `16px` (1rem) - base
- `24px` (1.5rem) - lg
- `32px` (2rem) - xl
- `48px` (3rem) - 2xl

### Border Radius

- **Small:** 8px (0.5rem)
- **Medium:** 12px (0.75rem)
- **Large:** 16px (1rem)
- **XLarge:** 20px (1.25rem)
- **Full:** 9999px (for pills/circles)

### Shadows

**Light Theme:**
- Small: `0 1px 2px rgba(0, 0, 0, 0.05)`
- Medium: `0 4px 6px rgba(0, 0, 0, 0.1)`
- Large: `0 10px 15px rgba(0, 0, 0, 0.1)`

**Dark Theme:**
- Small: `0 1px 2px rgba(0, 0, 0, 0.3)`
- Medium: `0 4px 6px rgba(0, 0, 0, 0.4)`
- Large: `0 10px 15px rgba(0, 0, 0, 0.5)`

### Gradients

Primary gradient (used for buttons, highlights):
```css
linear-gradient(135deg, #10b981 0%, #14b8a6 100%)
```

Full gradient (for special elements):
```css
linear-gradient(135deg, #10b981 0%, #14b8a6 50%, #059669 100%)
```

---

## 🌍 Localization (RO/EN)

### Language Support

The mobile app **MUST** support both Romanian and English, matching the website exactly.

### API Locale Handling

All API requests should include locale in the path:
- Romanian: `/ro/...`
- English: `/en/...`

**Note:** The API v1 endpoints (`/api/v1/...`) don't require locale prefix, but the web routes do. For consistency with the website, use locale-aware endpoints when available.

### Language Switching

1. **Initial Language:** Detect from device settings
   - If device language is Romanian → Use `ro`
   - Otherwise → Use `en` (default)

2. **User Preference:** Allow users to change language in app settings
   - Store preference locally
   - Update API requests to use selected locale
   - Update all UI text immediately

3. **API Locale Header:** Some endpoints may accept `Accept-Language` header:
   ```
   Accept-Language: ro
   ```

### Translation Keys

The website uses these translation namespaces (match these in mobile app):
- `recipes.*` - Recipe-related translations
- `users.*` - User-related translations
- `comments.*` - Comment-related translations
- `notifications.*` - Notification translations
- `common.*` - Common UI elements
- `errors.*` - Error messages

### Example Translations

**Romanian (ro):**
- "Retete" = Recipes
- "Utilizatori" = Users
- "Comentarii" = Comments
- "Notificari" = Notifications
- "Salveaza" = Save
- "Anuleaza" = Cancel

**English (en):**
- "Recipes" = Recipes
- "Users" = Users
- "Comments" = Comments
- "Notifications" = Notifications
- "Save" = Save
- "Cancel" = Cancel

---

## 🔐 Authentication

### JWT Token Authentication

All authenticated requests require:
```
Authorization: Bearer <jwt_token>
```

### Authentication Flow

1. **Login:**
   ```
   POST /api/v1/auth/login
   Body: { "login": "email_or_username", "password": "password" }
   ```

2. **Response:**
   ```json
   {
     "success": true,
     "data": {
       "token": "eyJhbGciOiJIUzI1NiJ9...",
       "refresh_token": "eyJhbGciOiJIUzI1NiJ9...",
       "expires_in": 604800,
       "user": { ... }
     }
   }
   ```

3. **Token Storage:**
   - Store tokens securely (use `flutter_secure_storage` or equivalent)
   - Access token expires in 7 days
   - Refresh token expires in 30 days

4. **Token Refresh:**
   ```
   POST /api/v1/auth/refresh_token
   Authorization: Bearer <refresh_token>
   ```

### OAuth (Google & Apple)

**Google OAuth:**
```
POST /api/v1/auth/google
Body: { "id_token": "<google_id_token>" }
```

**Apple OAuth:**
```
POST /api/v1/auth/apple
Body: { 
  "id_token": "<apple_id_token>",
  "full_name": "John Doe",
  "given_name": "John",
  "family_name": "Doe"
}
```

---

## 🔑 Key Endpoints

### Recipes

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/recipes` | GET | List recipes (with filters) |
| `/recipes/feed` | GET | Personalized feed (authenticated) |
| `/recipes/top` | GET | Top recipes by period (day/week/month/year) |
| `/recipes/search` | GET | Search recipes |
| `/recipes/:id` | GET | Get recipe details |
| `/recipes/:id/like` | POST/DELETE | Like/unlike recipe |
| `/recipes/:id/favorite` | POST/DELETE | Favorite/unfavorite recipe |
| `/recipes/:id/comments` | GET | Get recipe comments |
| `/recipes/:id/comments` | POST | Add comment |

### Users

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/users/search` | GET | Search users |
| `/users/:id` | GET | Get user profile |
| `/users/:id/follow` | POST/DELETE | Follow/unfollow user |
| `/users/:id/recipes` | GET | Get user's recipes |
| `/users/:id/followers` | GET | Get user's followers |
| `/users/:id/following` | GET | Get user's following |
| `/users/profile` | PUT | Update profile |
| `/users/avatar` | POST/DELETE | Update/delete avatar |

### Notifications

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/notifications` | GET | Get notifications |
| `/notifications/unread_count` | GET | Get unread count |
| `/notifications/:id/read` | PATCH | Mark as read |
| `/notifications/mark_all_read` | POST | Mark all as read |

### Conversations & Messages

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/conversations` | GET | List conversations |
| `/conversations/:id` | GET | Get conversation |
| `/conversations/:id/messages` | GET | Get messages |
| `/conversations/:id/messages` | POST | Send message |

### Categories & Taxonomies

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/categories` | GET | List categories |
| `/cuisines` | GET | List cuisines |
| `/food_types` | GET | List food types |

### Reports

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/reports/reasons` | GET | Get report reasons |
| `/recipes/:id/reports` | POST | Report recipe |
| `/users/:id/reports` | POST | Report user |
| `/reports/my_reports` | GET | Get my reports |

---

## 📐 Design Guidelines

### UI Components

All UI components should match the website's design:

1. **Buttons:**
   - Primary: Emerald gradient background (#10b981 → #14b8a6)
   - Border radius: 12px
   - Padding: 12px 24px
   - Text: White, bold

2. **Cards:**
   - Background: White (light) / #1a1a2e (dark)
   - Border radius: 16px
   - Shadow: Medium shadow
   - Padding: 16px

3. **Input Fields:**
   - Border: 2px solid #e5e7eb (light) / #374151 (dark)
   - Border radius: 12px
   - Focus: Border color changes to primary (#10b981)
   - Padding: 12px 16px

4. **Recipe Cards:**
   - Image aspect ratio: 16:9
   - Title: Bold, 18px
   - Meta info: Secondary text color, 14px
   - Like/Favorite buttons: Icon with count

5. **Navigation:**
   - Bottom tab bar (iOS/Android standard)
   - Active tab: Primary color (#10b981)
   - Inactive tab: Secondary text color

### Image Handling

- **Recipe Images:**
  - Cover photo: 1200x800px recommended
  - Thumbnail: 400x300px for lists
  - Use appropriate image caching

- **Avatar Images:**
  - Size: 400x400px recommended
  - Display: Circular, 40-60px diameter

### Loading States

- Use shimmer/skeleton loaders matching website
- Show loading indicators for async operations
- Implement pull-to-refresh for lists

### Error States

- Display user-friendly error messages
- Match website's error styling
- Provide retry options

---

## ✅ Implementation Checklist

### Core Features
- [ ] User authentication (login, register, logout)
- [ ] OAuth (Google & Apple)
- [ ] Token management (storage, refresh)
- [ ] Recipe browsing with filters
- [ ] Recipe details view
- [ ] Recipe search
- [ ] Like/unlike recipes
- [ ] Favorite/unfavorite recipes
- [ ] Comments with ratings
- [ ] User profiles
- [ ] Follow/unfollow users
- [ ] Notifications
- [ ] Direct messaging
- [ ] Share recipes

### Design Implementation
- [ ] Light theme (matching website)
- [ ] Dark theme (matching website)
- [ ] System theme detection
- [ ] Primary colors (#10b981, #14b8a6)
- [ ] Typography system
- [ ] Spacing system
- [ ] Border radius
- [ ] Shadows
- [ ] Gradients

### Localization
- [ ] Romanian (ro) support
- [ ] English (en) support
- [ ] Language detection from device
- [ ] Language switching in settings
- [ ] All UI text translated
- [ ] API locale handling

### Advanced Features
- [ ] Create/edit recipes
- [ ] Photo upload
- [ ] Video playback (if recipes have videos)
- [ ] Offline mode (caching)
- [ ] Push notifications
- [ ] Report content/users
- [ ] Collections
- [ ] Groups
- [ ] Meal planner
- [ ] Shopping lists

### Technical Requirements
- [ ] Secure token storage
- [ ] Automatic token refresh
- [ ] Image caching
- [ ] Error handling
- [ ] Retry logic
- [ ] Pagination support
- [ ] Pull-to-refresh
- [ ] Infinite scroll

---

## 🛠 Recommended Tech Stack

### Flutter (Recommended)
- **Language:** Dart
- **State Management:** Riverpod or Bloc
- **HTTP Client:** Dio
- **Storage:** flutter_secure_storage
- **Image Loading:** cached_network_image
- **Localization:** flutter_localizations

### iOS (Native)
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Networking:** URLSession
- **Image Loading:** SDWebImage
- **Storage:** Keychain

### Android (Native)
- **Language:** Kotlin
- **UI Framework:** Jetpack Compose
- **Networking:** Retrofit + OkHttp
- **Image Loading:** Coil
- **Storage:** EncryptedSharedPreferences

---

## 📱 Mobile-Specific Considerations

### Performance
- Implement image lazy loading
- Use pagination for all lists
- Cache frequently accessed data
- Optimize API calls (batch when possible)

### Offline Support
- Cache recipe data locally
- Queue actions (likes, comments) when offline
- Sync when connection is restored
- Show offline indicator

### Push Notifications
- Register device for push notifications
- Handle notification taps
- Update badge counts
- Support notification categories

### Platform Guidelines
- Follow iOS Human Interface Guidelines
- Follow Material Design (Android)
- Use platform-specific navigation patterns
- Respect safe areas

---

## 🔄 API Rate Limiting

**Limits:**
- **Authenticated:** 1000 requests/hour
- **Unauthenticated:** 100 requests/hour
- **Login attempts:** 5 requests per 20 seconds
- **Registration:** 3 requests per minute

**Headers:**
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 995
X-RateLimit-Reset: 1638748800
```

---

## 📞 Support & Resources

### Documentation
- **Full API Docs:** `../MOBILE_APP_API_DOCUMENTATION.md`
- **Flutter API Docs:** `../documentation/API_DOCUMENTATION.md`
- **Website:** https://recipy-web.fly.dev

### Contact
- **Email:** support@recipy.app
- **GitHub:** https://github.com/DragosAndrei1829/Recipy_Web

### Testing
- **Test Account:**
  - Email: test@recipy.app
  - Password: Test123!

---

## 🚀 Getting Started

1. **Set up your development environment**
   - Choose your platform (Flutter/iOS/Android)
   - Install required tools

2. **Configure API base URL**
   ```
   Production: https://recipy-web.fly.dev/api/v1
   ```

3. **Implement authentication**
   - Set up JWT token handling
   - Implement login/register flows
   - Add OAuth support (Google/Apple)

4. **Apply design system**
   - Set up color palette
   - Implement theme support (light/dark)
   - Create reusable UI components

5. **Add localization**
   - Set up RO/EN translations
   - Implement language switching
   - Test with both languages

6. **Build core features**
   - Recipe browsing
   - Recipe details
   - User interactions (like, favorite, comment)
   - User profiles

7. **Test thoroughly**
   - Test on both iOS and Android
   - Test with both languages
   - Test light and dark themes
   - Test offline functionality

---

## 📝 Notes

- **Image URLs:** All images are served from Cloudflare R2
- **Video Support:** Some recipes may have video URLs
- **Real-time Updates:** Consider WebSocket for real-time notifications
- **Analytics:** Track user engagement (respect privacy)
- **Crash Reporting:** Implement crash reporting (Sentry, Firebase Crashlytics)

---

**Last Updated:** January 2025  
**API Version:** v1  
**Status:** Production Ready

**Remember:** The mobile app should feel like a native extension of the website, with the same design language, colors, and user experience!
