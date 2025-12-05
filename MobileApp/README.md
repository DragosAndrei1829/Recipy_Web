# Recipy Mobile App

This folder is prepared for the Recipy mobile application development.

## API Documentation

The complete API documentation is available in the WebApp folder:
- **Location:** `../WebApp/documentation/API_DOCUMENTATION.md`

## Quick Start for Mobile Development

### API Base URL
- **Development:** `http://localhost:3000/api/v1`
- **Production:** `https://your-domain.com/api/v1`

### Authentication
The API uses JWT (JSON Web Tokens) for authentication.

1. **Login** to get tokens:
   ```
   POST /api/v1/auth/login
   Body: { "login": "email_or_username", "password": "password" }
   ```

2. **Use token** in all authenticated requests:
   ```
   Authorization: Bearer <your_jwt_token>
   ```

3. **Refresh token** before expiration:
   ```
   POST /api/v1/auth/refresh_token
   Authorization: Bearer <refresh_token>
   ```

### Key Endpoints

| Feature | Endpoint | Method |
|---------|----------|--------|
| Login | `/auth/login` | POST |
| Register | `/auth/register` | POST |
| Get Recipes | `/recipes` | GET |
| Recipe Feed | `/recipes/feed` | GET |
| Search Recipes | `/recipes/search?q=query` | GET |
| Get Recipe | `/recipes/:id` | GET |
| Like Recipe | `/recipes/:id/like` | POST |
| Favorite Recipe | `/recipes/:id/favorite` | POST |
| User Profile | `/users/:id` | GET |
| Follow User | `/users/:id/follow` | POST |
| Notifications | `/notifications` | GET |
| Conversations | `/conversations` | GET |
| Send Message | `/conversations/:id/messages` | POST |

### Response Format

All responses follow this format:

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

## Recommended Tech Stack

### iOS
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Networking:** URLSession / Alamofire
- **Image Loading:** SDWebImage / Kingfisher
- **Storage:** CoreData / Realm

### Android
- **Language:** Kotlin
- **UI Framework:** Jetpack Compose
- **Networking:** Retrofit + OkHttp
- **Image Loading:** Coil / Glide
- **Storage:** Room Database

### Cross-Platform
- **React Native** with TypeScript
- **Flutter** with Dart

## Features to Implement

### Core Features
- [ ] User authentication (login, register, logout)
- [ ] Recipe browsing with filters
- [ ] Recipe details view
- [ ] Recipe search
- [ ] User profiles
- [ ] Follow/unfollow users
- [ ] Like recipes
- [ ] Save to favorites
- [ ] Comments with ratings

### Social Features
- [ ] Personalized feed
- [ ] Notifications
- [ ] Direct messaging
- [ ] Share recipes in chat

### Advanced Features
- [ ] Create/edit recipes
- [ ] Photo upload
- [ ] Offline mode
- [ ] Push notifications
- [ ] Dark mode

## Design Assets

The web app uses these design tokens that should be matched in the mobile app:

### Colors (Light Theme)
- **Primary:** `#10b981` (Emerald)
- **Secondary:** `#14b8a6` (Teal)
- **Background:** `#f0fdf4`
- **Card Background:** `#ffffff`
- **Text Primary:** `#111827`
- **Text Secondary:** `#6b7280`
- **Success:** `#10b981`
- **Error:** `#ef4444`
- **Warning:** `#f59e0b`

### Typography
- Use system fonts for best performance
- Headings: Bold weight
- Body: Regular weight

### Spacing
- Base unit: 4px
- Common spacing: 8px, 12px, 16px, 24px, 32px

## Development Notes

1. **Token expiration:** Access tokens expire in 7 days, refresh tokens in 30 days
2. **Rate limiting:** Be mindful of API rate limits (300 req/5min)
3. **Image optimization:** Use appropriate image sizes for mobile
4. **Pagination:** All list endpoints support `page` and `per_page` parameters

## Contact

For API questions or issues:
- Check the full documentation: `../WebApp/documentation/API_DOCUMENTATION.md`
- Backend repository: https://github.com/DragosAndrei1829/Recipy_Web




