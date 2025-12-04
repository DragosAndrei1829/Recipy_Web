# 🔗 Update OAuth & Stripe URLs pentru Fly.io

## Noul URL Fly.io:
```
https://recipy-web.fly.dev
```

---

## 1️⃣ Google OAuth - Actualizare Redirect URIs

### **Pasul 1: Deschide Google Cloud Console**
```
https://console.cloud.google.com/apis/credentials
```

### **Pasul 2: Editează OAuth 2.0 Client ID**
1. Click pe client-ul tău OAuth 2.0 (ex: "Web client" sau "Recipy Web")
2. Scroll la **"Authorized redirect URIs"**

### **Pasul 3: Adaugă URL-urile Fly.io**

**Șterge URL-urile vechi Railway:**
```
❌ https://recipyweb-production.up.railway.app/auth/google_oauth2/callback
❌ https://recipyweb-production.up.railway.app/users/auth/google_oauth2/callback
```

**Adaugă URL-urile noi Fly.io:**
```
✅ https://recipy-web.fly.dev/auth/google_oauth2/callback
✅ https://recipy-web.fly.dev/users/auth/google_oauth2/callback
```

**Pentru ambele limbi:**
```
✅ https://recipy-web.fly.dev/ro/users/auth/google_oauth2/callback
✅ https://recipy-web.fly.dev/en/users/auth/google_oauth2/callback
```

### **Pasul 4: Salvează**
Click **"Save"** jos la pagină

---

## 2️⃣ Apple OAuth - Actualizare Return URLs

### **Pasul 1: Deschide Apple Developer**
```
https://developer.apple.com/account/resources/identifiers/list/serviceId
```

### **Pasul 2: Editează Service ID**
1. Click pe Service ID-ul tău (ex: "Recipy Sign In with Apple")
2. Click **"Configure"** lângă "Sign In with Apple"

### **Pasul 3: Actualizează Domains and Return URLs**

**Primary Domain:**
```
recipy-web.fly.dev
```

**Return URLs:**
```
https://recipy-web.fly.dev/users/auth/apple/callback
https://recipy-web.fly.dev/ro/users/auth/apple/callback
https://recipy-web.fly.dev/en/users/auth/apple/callback
```

### **Pasul 4: Salvează și Continue**
Click **"Continue"** → **"Save"**

---

## 3️⃣ Stripe - Actualizare Webhook Endpoints

### **Pasul 1: Deschide Stripe Dashboard**
```
https://dashboard.stripe.com/test/webhooks
```

### **Pasul 2: Editează Webhook (sau creează nou)**

**Șterge webhook-ul vechi Railway (dacă există):**
```
❌ https://recipyweb-production.up.railway.app/stripe/webhook
```

**Creează/Actualizează webhook Fly.io:**
1. Click **"Add endpoint"** (sau click pe webhook existent)
2. **Endpoint URL:**
   ```
   https://recipy-web.fly.dev/stripe/webhook
   ```
3. **Events to send:** Selectează
   - ✅ `checkout.session.completed`
   - ✅ `checkout.session.async_payment_succeeded`
   - ✅ `checkout.session.async_payment_failed`
4. Click **"Add endpoint"**

### **Pasul 3: Copiază Signing Secret**

După crearea webhook-ului:
1. Click pe webhook-ul nou creat
2. Click **"Reveal"** lângă "Signing secret"
3. Copiază secret-ul (începe cu `whsec_...`)

### **Pasul 4: Actualizează în Fly.io**

```bash
flyctl secrets set STRIPE_WEBHOOK_SECRET=whsec_your_new_secret --app recipy-web
```

---

## 4️⃣ Verificare Configurări Locale (Devise)

### **În `config/initializers/devise.rb`:**

Verifică că `config.omniauth` folosește variabile de environment, NU URL-uri hardcodate:

```ruby
# Good ✅
config.omniauth :google_oauth2, 
  ENV['GOOGLE_CLIENT_ID'], 
  ENV['GOOGLE_CLIENT_SECRET']

# Bad ❌
config.omniauth :google_oauth2, 
  ENV['GOOGLE_CLIENT_ID'], 
  ENV['GOOGLE_CLIENT_SECRET'],
  callback_url: 'https://recipyweb-production.up.railway.app/...'
```

**Dacă ai callback_url hardcodat, șterge-l!** Rails va genera automat URL-ul corect.

---

## 5️⃣ Content Security Policy (CSP)

### **În `config/initializers/content_security_policy.rb`:**

Dacă ai whitelist-uri pentru domenii, adaugă Fly.io:

```ruby
Rails.application.config.content_security_policy do |policy|
  # ... existing policies ...
  
  policy.connect_src :self, :https, 
    "https://recipy-web.fly.dev",
    "wss://recipy-web.fly.dev"
end
```

---

## ✅ Checklist Final:

- [ ] Google OAuth Redirect URIs actualizate
- [ ] Apple OAuth Return URLs actualizate (dacă folosești)
- [ ] Stripe Webhook URL actualizat
- [ ] `STRIPE_WEBHOOK_SECRET` actualizat în Fly.io
- [ ] Devise config verificat (fără URL-uri hardcodate)
- [ ] Test Google Login pe Fly.io
- [ ] Test Stripe Checkout pe Fly.io

---

## 🧪 Test OAuth:

### **Google:**
```
https://recipy-web.fly.dev/ro/users/auth/google_oauth2
```

Ar trebui să:
1. Redirecționeze la Google
2. După login → redirecționează înapoi la Fly.io
3. User logat cu succes

### **Stripe:**
```
https://recipy-web.fly.dev/ro/chef-ai
```

Click "Subscribe" → Ar trebui să meargă la Stripe Checkout

---

**După ce actualizezi URL-urile, testează și spune-mi dacă merge!** 🚀

