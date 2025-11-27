# 🤖 AI Recipe Assistant API Documentation

## Overview

Chef AI este un asistent culinar inteligent cu **sistem în 3 niveluri**:

1. **🔍 Local (GRATUIT)** - Caută în rețetele existente din comunitate
2. **🦙 Llama (GRATUIT)** - Generează rețete cu AI local (Ollama/Llama 3.1)
3. **✨ OpenAI (PREMIUM)** - Generare cu GPT-4 (opțional, necesită API key)

### Flux de funcționare:
```
User Message → Parse Local → Search Recipes → Found? 
                                              ├── YES → Return recommendations (FREE)
                                              └── NO → Generate with AI (Llama FREE / OpenAI PAID)
```

---

## API Endpoints

### Base URL
```
https://your-domain.com/api/v1/ai
```

### Headers necesare
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

---

## 1. Chat cu AI Assistant

### `POST /api/v1/ai/chat`

Trimite un mesaj către AI și primește răspunsul.

#### Request Body
```json
{
  "message": "Am pui, roșii și usturoi. Ce pot găti?",
  "provider": "local",
  "conversation_id": "optional-uuid"
}
```

#### Provider Options:
| Provider | Cost | Descriere |
|----------|------|-----------|
| `local` | Gratuit | Caută doar în rețete existente |
| `llama` | Gratuit | Generează cu Llama 3.1 (necesită Ollama) |
| `openai` | Plătit | Generează cu GPT-4 (necesită API key) |

#### Response - Recommendation (rețete găsite)
```json
{
  "success": true,
  "data": {
    "conversation_id": "uuid",
    "response": {
      "message": "🎉 Am găsit 3 rețete care se potrivesc...",
      "type": "recommendation",
      "ai_provider": "local",
      "recommended_recipe_id": 123,
      "alternatives": [124, 125],
      "matching_recipes": [
        {
          "id": 123,
          "title": "Pui cu roșii și usturoi",
          "match_percentage": 95,
          "matched_ingredients": ["pui", "roșii", "usturoi"],
          "missing_ingredients": ["ceapă"],
          "time_to_make": 45,
          "difficulty": 2,
          "likes_count": 156,
          "user": "chef_maria"
        }
      ]
    },
    "provider_used": "local",
    "timestamp": "2025-11-27T15:30:00Z"
  }
}
```

#### Response - No Match (oferă generare AI)
```json
{
  "success": true,
  "data": {
    "response": {
      "message": "😕 Nu am găsit rețete în baza noastră...",
      "type": "no_match",
      "ai_provider": "local",
      "ingredients": ["pui", "roșii", "usturoi"],
      "can_generate": true
    }
  }
}
```

#### Response - Generated Recipe (de la Llama/OpenAI)
```json
{
  "success": true,
  "data": {
    "response": {
      "message": "🍳 Am creat o rețetă specială pentru tine!",
      "type": "generated_recipe",
      "ai_provider": "llama",
      "recipe": {
        "title": "Pui aromat cu roșii și usturoi",
        "description": "O rețetă simplă și delicioasă...",
        "ingredients": "- 500g piept de pui\n- 4 roșii mari\n...",
        "preparation": "1. Tăiați puiul...\n2. Încălziți uleiul...",
        "time_to_make": 30,
        "difficulty": 2,
        "healthiness": 4,
        "tips": "Pentru mai mult gust, marinați 30 min"
      }
    }
  }
}
```

#### Response - Insufficient Ingredients
```json
{
  "success": true,
  "data": {
    "response": {
      "message": "📝 Ai doar 2 ingrediente...",
      "type": "insufficient_ingredients",
      "ai_provider": "local",
      "suggested_ingredients": ["ceapă", "ulei", "sare"],
      "possible_recipes_with_additions": ["Pui la tigaie", "Supă de pui"]
    }
  }
}
```

---

## 2. Lista Provideri Disponibili

### `GET /api/v1/ai/providers`

Returnează lista de provideri AI disponibili.

#### Response
```json
{
  "success": true,
  "data": {
    "providers": [
      {
        "id": "local",
        "name": "Căutare Locală",
        "description": "Caută în rețetele existente",
        "available": true,
        "cost": "Gratuit",
        "icon": "🔍"
      },
      {
        "id": "llama",
        "name": "Llama 3.1",
        "description": "Generează rețete cu AI local",
        "available": true,
        "cost": "Gratuit",
        "icon": "🦙",
        "setup_required": false
      },
      {
        "id": "openai",
        "name": "OpenAI GPT-4",
        "description": "Generare premium",
        "available": false,
        "cost": "Premium",
        "icon": "✨",
        "setup_required": true
      }
    ],
    "default": "local"
  }
}
```

---

## 3. Salvare Rețetă Generată

### `POST /api/v1/ai/save_recipe`

Salvează o rețetă generată de AI în profilul utilizatorului.

#### Request Body
```json
{
  "recipe": {
    "title": "Pui aromat cu roșii",
    "description": "O rețetă delicioasă...",
    "ingredients": "- 500g pui\n- 4 roșii...",
    "preparation": "1. Tăiați puiul...",
    "time_to_make": 30,
    "difficulty": 2,
    "healthiness": 4
  }
}
```

#### Success Response
```json
{
  "success": true,
  "data": {
    "message": "Recipe saved successfully",
    "recipe": {
      "id": 456,
      "title": "Pui aromat cu roșii",
      "created_at": "2025-11-27T15:35:00Z"
    }
  }
}
```

---

## Flutter Implementation

### Service Class

```dart
class AiAssistantService {
  final String baseUrl;
  final String authToken;

  AiAssistantService({required this.baseUrl, required this.authToken});

  /// Chat with AI - uses 3-tier system
  /// provider: "local" (free), "llama" (free), "openai" (paid)
  Future<Map<String, dynamic>> chat(
    String message, {
    String provider = 'local',
    String? conversationId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/ai/chat'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': message,
        'provider': provider,
        if (conversationId != null) 'conversation_id': conversationId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('AI chat failed: ${response.body}');
    }
  }

  /// Get available AI providers
  Future<List<Map<String, dynamic>>> getProviders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/ai/providers'),
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']['providers']);
    }
    return [];
  }

  /// Save AI-generated recipe
  Future<Map<String, dynamic>> saveRecipe(Map<String, dynamic> recipe) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/ai/save_recipe'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'recipe': recipe}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Save failed: ${response.body}');
  }
}
```

### Usage Example

```dart
final aiService = AiAssistantService(
  baseUrl: 'https://api.recipy.com',
  authToken: userToken,
);

// Step 1: Try local search first (FREE)
var result = await aiService.chat(
  'Am pui, roșii și usturoi',
  provider: 'local',
);

if (result['data']['response']['type'] == 'no_match') {
  // Step 2: Generate with Llama (FREE)
  result = await aiService.chat(
    'Am pui, roșii și usturoi',
    provider: 'llama',
  );
}

// Display result
if (result['data']['response']['type'] == 'recommendation') {
  // Show matching recipes
  final recipes = result['data']['response']['matching_recipes'];
  // ...
} else if (result['data']['response']['type'] == 'generated_recipe') {
  // Show generated recipe
  final recipe = result['data']['response']['recipe'];
  // ...
}
```

---

## Response Types Summary

| Type | Provider | Când apare |
|------|----------|------------|
| `recommendation` | local | Rețete găsite în DB |
| `no_match` | local | Nu s-au găsit rețete |
| `generated_recipe` | llama/openai | Rețetă generată de AI |
| `insufficient_ingredients` | local | Prea puține ingrediente (<3) |
| `need_clarification` | local | Nu s-au identificat ingrediente |
| `error` | any | Eroare la procesare |

---

## Setup Ollama (pentru Llama gratuit)

### Instalare Ollama
```bash
# macOS
brew install ollama

# Linux
curl -fsSL https://ollama.com/install.sh | sh
```

### Descarcă Llama 3.1
```bash
ollama pull llama3.1:8b
```

### Pornește serverul
```bash
ollama serve
```

### Configurare în .env
```env
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=llama3.1:8b
```

---

## Costuri Estimate

| Provider | Cost per request | Recomandare |
|----------|-----------------|-------------|
| Local | $0 | ✅ Folosește mereu primul |
| Llama | $0 (self-hosted) | ✅ Pentru generare gratuită |
| OpenAI | ~$0.002 | ⚠️ Doar când e necesar |

**Strategie recomandată:**
1. Întotdeauna caută local mai întâi
2. Oferă Llama ca opțiune de generare gratuită
3. OpenAI doar pentru utilizatori premium sau când Llama nu e disponibil
