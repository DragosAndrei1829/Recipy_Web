# 🔧 Configurare Variabile de Mediu - Fly.io

## ⚠️ Variabile Necesare pentru Funcționalități Complete

Pentru ca aplicația să funcționeze complet, trebuie să setezi următoarele variabile de mediu în Fly.io:

---

## 📧 Email Configuration (Pentru Password Reset)

Pentru ca funcționalitatea de resetare parolă să funcționeze, trebuie să configurezi Gmail SMTP:

### Pași:

1. **Creează un App Password în Gmail:**
   - Mergi la: https://myaccount.google.com/apppasswords
   - Selectează "Mail" și "Other (Custom name)"
   - Introdu "Recipy App" ca nume
   - Copiază parola generată (16 caractere, fără spații)

2. **Setează variabilele în Fly.io:**
   ```bash
   flyctl secrets set GMAIL_USERNAME="your-email@gmail.com"
   flyctl secrets set GMAIL_APP_PASSWORD="xxxx xxxx xxxx xxxx"
   ```

   **Notă:** Poți include sau exclude spațiile în App Password - codul le va elimina automat.

3. **Verifică:**
   ```bash
   flyctl secrets list | grep GMAIL
   ```

---

## 🔐 Google OAuth Configuration

Pentru ca autentificarea cu Google să funcționeze:

### Pași:

1. **Creează OAuth Credentials în Google Cloud Console:**
   - Mergi la: https://console.cloud.google.com/apis/credentials
   - Creează un proiect nou sau selectează unul existent
   - Click pe "Create Credentials" → "OAuth client ID"
   - Selectează "Web application"
   - Adaugă în "Authorized redirect URIs":
     ```
     https://recipy-web.fly.dev/users/auth/google_oauth2/callback
     ```
   - Copiază **Client ID** și **Client Secret**

2. **Setează variabilele în Fly.io:**
   ```bash
   flyctl secrets set GOOGLE_CLIENT_ID="your-client-id.apps.googleusercontent.com"
   flyctl secrets set GOOGLE_CLIENT_SECRET="your-client-secret"
   ```

3. **Verifică:**
   ```bash
   flyctl secrets list | grep GOOGLE
   ```

---

## 🌐 APP_HOST (Opțional)

Pentru link-urile din email-uri să fie corecte:

```bash
flyctl secrets set APP_HOST="recipy-web.fly.dev"
```

**Notă:** Dacă nu este setat, se folosește default-ul `recipy-web.fly.dev`.

---

## ✅ Verificare Completă

După ce ai setat toate variabilele, verifică:

```bash
flyctl secrets list
```

Ar trebui să vezi:
- ✅ `GMAIL_USERNAME`
- ✅ `GMAIL_APP_PASSWORD`
- ✅ `GOOGLE_CLIENT_ID`
- ✅ `GOOGLE_CLIENT_SECRET`
- ✅ `APP_HOST` (opțional)

---

## 🔄 Restart Aplicație

După setarea variabilelor, restart aplicația:

```bash
flyctl apps restart recipy-web
```

Sau așteaptă următorul deploy - variabilele vor fi disponibile automat.

---

## 🧪 Testare

### Test Password Reset:
1. Mergi la: `https://recipy-web.fly.dev/en/users/password/new`
2. Introdu un email valid
3. Ar trebui să primești un email cu link-ul de resetare

### Test Google OAuth:
1. Mergi la: `https://recipy-web.fly.dev/en/users/sign_in`
2. Click pe "Continue with Google"
3. Ar trebui să fii redirecționat către Google pentru autentificare

---

## ⚠️ Probleme Comune

### Password Reset nu funcționează:
- Verifică că `GMAIL_USERNAME` și `GMAIL_APP_PASSWORD` sunt setate
- Verifică că App Password este valid (nu parola contului Gmail)
- Verifică logs-urile: `flyctl logs`

### Google OAuth dă eroare "Provider neconfigurat":
- Verifică că `GOOGLE_CLIENT_ID` și `GOOGLE_CLIENT_SECRET` sunt setate
- Verifică că redirect URI este corect în Google Cloud Console
- Verifică că aplicația a fost restartată după setarea variabilelor

### Redirect loop la Google OAuth:
- Verifică că provider-ul este configurat corect
- Verifică logs-urile pentru erori
- Asigură-te că redirect URI-ul din Google Cloud Console se potrivește exact cu cel din aplicație

---

## 📝 Notă Importantă

**Nu seta aceste variabile în fișiere locale sau în Git!** 
Folosește întotdeauna `flyctl secrets set` pentru variabile sensibile.

---

**Last Updated:** January 2025

