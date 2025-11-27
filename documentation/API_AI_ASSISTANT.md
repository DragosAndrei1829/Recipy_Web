# 🤖 AI Recipe Assistant API Documentation

## Overview

Chef AI este un asistent culinar inteligent care ajută utilizatorii să găsească sau să creeze rețete bazate pe ingredientele disponibile.

### Funcționalități principale:
- **Parsare ingrediente** - Extrage ingredientele din mesajul utilizatorului
- **Matching rețete** - Găsește rețete existente care se potrivesc cu ingredientele
- **Generare rețete** - Creează rețete noi când nu există match-uri
- **Sugestii ingrediente** - Recomandă ingrediente suplimentare dacă sunt prea puține

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
  "conversation_id": "optional-uuid-for-context"
}
```

#### Response - Recommendation (când există rețete potrivite)
```json
{
  "success": true,
  "data": {
    "conversation_id": "uuid-string",
    "response": {
      "message": "Am găsit câteva rețete perfecte pentru ingredientele tale! Îți recomand...",
      "type": "recommendation",
      "recommended_recipe_id": 123,
      "alternatives": [124, 125],
      "missing_ingredients_suggestions": [
        "Poți înlocui roșiile proaspete cu roșii din conservă"
      ],
      "matching_recipes": [
        {
          "id": 123,
          "title": "Pui cu roșii și usturoi la cuptor",
          "description": "O rețetă delicioasă...",
          "difficulty": 2,
          "time_to_make": 45,
          "healthiness": 4,
          "likes_count": 156,
          "user": "chef_maria",
          "category": "Feluri principale",
          "cuisine": "Românească",
          "match_percentage": 95,
          "matched_ingredients": ["pui", "roșii", "usturoi"],
          "missing_ingredients": ["ceapă", "ardei"]
        }
      ]
    },
    "timestamp": "2025-11-27T15:30:00Z"
  }
}
```

#### Response - Generated Recipe (când nu există match-uri)
```json
{
  "success": true,
  "data": {
    "conversation_id": "uuid-string",
    "response": {
      "message": "Nu am găsit rețete existente, dar am creat una specială pentru tine!",
      "type": "generated_recipe",
      "recipe": {
        "title": "Pui aromat cu roșii și usturoi",
        "description": "O rețetă simplă și delicioasă...",
        "ingredients": "- 500g piept de pui\n- 4 roșii mari\n- 6 căței de usturoi\n- 2 linguri ulei de măsline\n- Sare și piper după gust",
        "preparation": "1. Tăiați pieptul de pui în cuburi\n2. Încălziți uleiul într-o tigaie\n3. ...",
        "time_to_make": 30,
        "difficulty": 2,
        "healthiness": 4,
        "tips": "Pentru mai mult gust, marinați puiul 30 de minute înainte"
      },
      "additional_ingredients_needed": ["ulei de măsline", "sare", "piper"]
    },
    "timestamp": "2025-11-27T15:30:00Z"
  }
}
```

#### Response - Insufficient Ingredients
```json
{
  "success": true,
  "data": {
    "conversation_id": "uuid-string",
    "response": {
      "message": "Ai doar 2 ingrediente. Pentru o rețetă completă ai nevoie de cel puțin 3-4.",
      "type": "insufficient_ingredients",
      "suggested_ingredients": ["ceapă", "morcovi", "cartofi", "ulei"],
      "possible_recipes_with_additions": [
        "Tocăniță de pui cu legume",
        "Supă de pui"
      ]
    },
    "timestamp": "2025-11-27T15:30:00Z"
  }
}
```

#### Error Response
```json
{
  "success": false,
  "error": "Message is required"
}
```

---

## 2. Salvare Rețetă Generată

### `POST /api/v1/ai/save_recipe`

Salvează o rețetă generată de AI în profilul utilizatorului.

#### Request Body
```json
{
  "recipe": {
    "title": "Pui aromat cu roșii și usturoi",
    "description": "O rețetă simplă și delicioasă...",
    "ingredients": "- 500g piept de pui\n- 4 roșii mari\n...",
    "preparation": "1. Tăiați pieptul de pui...",
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
      "title": "Pui aromat cu roșii și usturoi",
      "created_at": "2025-11-27T15:35:00Z"
    }
  }
}
```

---

## 3. Lista Conversații

### `GET /api/v1/ai/conversations`

Returnează istoricul conversațiilor utilizatorului cu AI.

#### Response
```json
{
  "success": true,
  "data": {
    "conversations": [
      {
        "id": "uuid-1",
        "title": "Rețete cu pui",
        "last_message": "Am găsit câteva rețete perfecte...",
        "updated_at": "2025-11-27T15:30:00Z",
        "message_count": 5
      }
    ]
  }
}
```

---

## 4. Detalii Conversație

### `GET /api/v1/ai/conversations/:id`

Returnează o conversație specifică cu toate mesajele.

#### Response
```json
{
  "success": true,
  "data": {
    "id": "uuid-1",
    "title": "Rețete cu pui",
    "messages": [
      {
        "role": "user",
        "content": "Am pui, roșii și usturoi",
        "timestamp": "2025-11-27T15:28:00Z"
      },
      {
        "role": "assistant",
        "content": { /* response object */ },
        "timestamp": "2025-11-27T15:28:05Z"
      }
    ],
    "created_at": "2025-11-27T15:28:00Z"
  }
}
```

---

## 5. Ștergere Conversație

### `DELETE /api/v1/ai/conversations/:id`

Șterge o conversație.

#### Response
```json
{
  "success": true,
  "data": {
    "message": "Conversation deleted"
  }
}
```

---

## Flutter Implementation Example

### Service Class

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiAssistantService {
  final String baseUrl;
  final String authToken;

  AiAssistantService({required this.baseUrl, required this.authToken});

  Future<Map<String, dynamic>> chat(String message, {String? conversationId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/ai/chat'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': message,
        if (conversationId != null) 'conversation_id': conversationId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get AI response: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> saveRecipe(Map<String, dynamic> recipeData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/ai/save_recipe'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'recipe': recipeData}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to save recipe: ${response.body}');
    }
  }
}
```

### Usage in Flutter Widget

```dart
class AiChatScreen extends StatefulWidget {
  @override
  _AiChatScreenState createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  String? _conversationId;
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _isLoading = true;
    });
    _messageController.clear();

    try {
      final response = await AiAssistantService(
        baseUrl: 'https://your-api.com',
        authToken: 'your-jwt-token',
      ).chat(message, conversationId: _conversationId);

      if (response['success']) {
        final data = response['data'];
        _conversationId = data['conversation_id'];
        
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': data['response'],
          });
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chef AI')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (_isLoading) LinearProgressIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    // Build UI based on message type
    // ...
  }

  Widget _buildInputArea() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ce ingrediente ai?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
```

---

## Response Types Summary

| Type | Când apare | Ce conține |
|------|------------|------------|
| `recommendation` | Există rețete potrivite | Lista de rețete cu scor de potrivire |
| `generated_recipe` | Nu există match-uri, suficiente ingrediente | Rețetă nouă generată de AI |
| `insufficient_ingredients` | Prea puține ingrediente (<3) | Sugestii de ingrediente și idei |
| `error` | Eroare la procesare | Mesaj de eroare |

---

## Rate Limiting

- **Limită:** 20 requests/minut per utilizator
- **Headers în răspuns:**
  - `X-RateLimit-Limit`: 20
  - `X-RateLimit-Remaining`: requests rămase
  - `X-RateLimit-Reset`: timestamp reset

---

## Configurare OpenAI

Pentru a funcționa, backend-ul necesită:

```env
OPENAI_API_KEY=sk-your-openai-api-key
```

Model folosit: `gpt-4o-mini` (cost-effective și rapid)

