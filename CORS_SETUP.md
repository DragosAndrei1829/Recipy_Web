# 🔧 Configurare CORS pentru Rails Backend

## ✅ Status: Configurat

CORS-ul a fost configurat pentru a permite request-uri de la aplicația Flutter Web și aplicațiile mobile.

---

## 📋 Ce s-a configurat

### 1. Gem-ul `rack-cors`
- ✅ Adăugat în `Gemfile`
- ✅ Instalat cu `bundle install`

### 2. Initializer CORS
- ✅ Creat `config/initializers/cors.rb`
- ✅ Configurat pentru development și production

### 3. BaseController
- ✅ Adăugate metodele `cors_preflight_check` și `cors_set_access_control_headers`
- ✅ Gestionare automată pentru OPTIONS requests

---

## 🔍 Configurație detaliată

### Development
- **Origins:** `*` (toate origin-urile sunt permise)
- **Credentials:** `false`
- **Max Age:** 86400 secunde (24 ore)

### Production
- **Origins permise:**
  - `https://recipy-web.fly.dev`
  - `https://www.recipy-web.fly.dev`
  - `http://localhost:*` (pentru testare)
  - `http://127.0.0.1:*` (pentru testare)
- **Credentials:** `false`
- **Max Age:** 86400 secunde (24 ore)

### Headers permise
- `X-Requested-With`
- `X-Prototype-Version`
- `Token`
- `Authorization`
- `Content-Type`
- `Accept`

### Headers expuse
- `Authorization`
- `X-RateLimit-Limit`
- `X-RateLimit-Remaining`
- `X-RateLimit-Reset`

### Metode HTTP permise
- GET
- POST
- PUT
- PATCH
- DELETE
- OPTIONS
- HEAD

---

## 🧪 Testare

### Test local (dacă server-ul rulează)

```bash
curl -X OPTIONS http://localhost:3000/api/v1/auth/login \
  -H "Origin: http://localhost:62478" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type,Authorization" \
  -v
```

### Test production

```bash
curl -X OPTIONS https://recipy-web.fly.dev/api/v1/auth/login \
  -H "Origin: http://localhost:62478" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type,Authorization" \
  -v
```

### Răspuns așteptat

Ar trebui să vezi în headers:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: POST, GET, PUT, PATCH, DELETE, OPTIONS, HEAD
Access-Control-Allow-Headers: X-Requested-With, X-Prototype-Version, Token, Authorization, Content-Type, Accept
Access-Control-Expose-Headers: Authorization, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset
Access-Control-Max-Age: 86400
```

---

## 📝 Fișiere modificate

1. **Gemfile**
   - Adăugat `gem "rack-cors"`

2. **config/initializers/cors.rb** (nou)
   - Configurație CORS pentru development și production

3. **app/controllers/api/v1/base_controller.rb**
   - Adăugate metodele `cors_preflight_check` și `cors_set_access_control_headers`
   - Adăugată metoda `cors_allowed_origin` pentru gestionarea origin-urilor

---

## 🚀 Deploy

După modificări, pentru a aplica configurația:

1. **Local:**
   ```bash
   # Restart server-ul Rails
   rails server
   ```

2. **Production (fly.io):**
   ```bash
   flyctl deploy
   ```

---

## 🔒 Securitate

### Development
- Permite toate origin-urile (`*`) pentru flexibilitate maximă în dezvoltare

### Production
- Doar origin-urile specificate sunt permise
- Localhost este permis doar pentru testare
- Credentials sunt setate pe `false` pentru securitate

### Recomandări pentru viitor
Dacă ai nevoie de origin-uri suplimentare în production, adaugă-le în:
- `config/initializers/cors.rb` - lista `origins`
- `app/controllers/api/v1/base_controller.rb` - metoda `cors_allowed_origin`

---

## ✅ Verificare

După deploy, verifică că:

1. ✅ Request-urile OPTIONS returnează status 200
2. ✅ Headers CORS sunt prezente în răspunsuri
3. ✅ Aplicația Flutter Web poate face request-uri fără erori CORS
4. ✅ Browser-ul nu arată erori CORS în console

---

## 📞 Suport

Dacă întâmpini probleme cu CORS:

1. Verifică că server-ul Rails a fost restartat după modificări
2. Verifică că gem-ul `rack-cors` este instalat: `bundle list | grep rack-cors`
3. Verifică logs-urile Rails pentru erori
4. Testează cu `curl` pentru a vedea headers-urile returnate

---

**Last Updated:** January 2025  
**Status:** ✅ Configured and Ready

