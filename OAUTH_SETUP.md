# Ghid de Configurare OAuth

Acest ghid te va ajuta să configurezi autentificarea OAuth cu Google și Apple pentru aplicația Recipy.

## 📋 Pași Generali

### 1. Instalează dotenv-rails (pentru gestionarea variabilelor de mediu)

Adaugă în `Gemfile`:

```ruby
gem 'dotenv-rails', groups: [:development, :test]
```

Apoi rulează:
```bash
bundle install
```

### 2. Creează fișierul .env

Copiază `.env.example` în `.env`:
```bash
cp .env.example .env
```

**IMPORTANT:** Fișierul `.env` este în `.gitignore` și nu va fi commitat în Git. Nu partaja niciodată acest fișier!

---

## 🔵 Configurare Google OAuth

### Pasul 1: Creează un proiect în Google Cloud Console

1. Mergi la [Google Cloud Console](https://console.cloud.google.com/)
2. Creează un proiect nou sau selectează unul existent
3. Activează **Google+ API** pentru proiect

### Pasul 2: Creează OAuth 2.0 Credentials

1. Mergi la **APIs & Services** → **Credentials**
2. Click pe **Create Credentials** → **OAuth client ID**
3. Dacă e prima dată, configurează **OAuth consent screen**:
   - Alege **External** (sau Internal dacă ai Google Workspace)
   - Completează informațiile despre aplicație:
     - **App name**: Recipy
     - **User support email**: email-ul tău
     - **Developer contact**: email-ul tău
   - Adaugă **scopes**: `email`, `profile`
   - Salvează

4. Creează **OAuth client ID**:
   - **Application type**: Web application
   - **Name**: Recipy Web Client
   - **Authorized JavaScript origins**: 
     - `http://localhost:3000` (pentru development)
     - `https://yourdomain.com` (pentru production)
   - **Authorized redirect URIs**:
     - `http://localhost:3000/users/auth/google_oauth2/callback` (development)
     - `https://yourdomain.com/users/auth/google_oauth2/callback` (production)

5. După creare, vei primi:
   - **Client ID** → copiază în `GOOGLE_CLIENT_ID`
   - **Client secret** → copiază în `GOOGLE_CLIENT_SECRET`

### Pasul 3: Adaugă în .env

```env
GOOGLE_CLIENT_ID=123456789-abcdefghijklmnop.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-abcdefghijklmnopqrstuvwxyz
```

---

## 📱 Configurare Google OAuth pentru Mobile (Flutter)

### Pasul 1: Creează iOS Client ID

1. În Google Cloud Console → **Credentials**
2. Click **Create Credentials** → **OAuth client ID**
3. **Application type**: iOS
4. **Name**: `Recipy iOS`
5. **Bundle ID**: `com.recipy.app` (sau Bundle ID-ul tău din Flutter)
6. Click **Create**

**iOS Client ID generat:**
```
163361667480-5lksujehv7cpj50f2v1rdrr98g7cbkp6.apps.googleusercontent.com
```

### Pasul 2: Creează Android Client ID

1. În Google Cloud Console → **Credentials**
2. Click **Create Credentials** → **OAuth client ID**
3. **Application type**: Android
4. **Name**: `Recipy Android`
5. **Package name**: `com.recipy.app`
6. **SHA-1 certificate fingerprint**: 
   - Pentru debug: rulează în terminal:
     ```bash
     cd android && ./gradlew signingReport
     ```
   - Copiază SHA-1 din output

### Pasul 3: Adaugă iOS Client ID în .env (backend)

```env
# Google OAuth iOS Client ID (pentru validarea token-urilor de pe mobile)
GOOGLE_IOS_CLIENT_ID=163361667480-5lksujehv7cpj50f2v1rdrr98g7cbkp6.apps.googleusercontent.com
```

### Pasul 4: Configurare Flutter

1. **Adaugă `google_sign_in` în `pubspec.yaml`:**
   ```yaml
   dependencies:
     google_sign_in: ^6.1.6
   ```

2. **Configurare iOS (`ios/Runner/Info.plist`):**
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key>
       <string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.163361667480-5lksujehv7cpj50f2v1rdrr98g7cbkp6</string>
       </array>
     </dict>
   </array>
   <key>GIDClientID</key>
   <string>163361667480-5lksujehv7cpj50f2v1rdrr98g7cbkp6.apps.googleusercontent.com</string>
   ```

3. **Configurare Android (`android/app/build.gradle`):**
   - Asigură-te că `applicationId` este `com.recipy.app`

4. **Cod Flutter pentru Google Sign-In:**
   ```dart
   import 'package:google_sign_in/google_sign_in.dart';
   
   final GoogleSignIn _googleSignIn = GoogleSignIn(
     scopes: ['email', 'profile'],
     // Pentru iOS, folosește iOS Client ID
     clientId: '163361667480-5lksujehv7cpj50f2v1rdrr98g7cbkp6.apps.googleusercontent.com',
   );
   
   Future<void> signInWithGoogle() async {
     try {
       final GoogleSignInAccount? account = await _googleSignIn.signIn();
       if (account != null) {
         final GoogleSignInAuthentication auth = await account.authentication;
         final String? idToken = auth.idToken;
         
         // Trimite idToken la backend
         final response = await http.post(
           Uri.parse('$baseUrl/api/v1/auth/google'),
           headers: {'Content-Type': 'application/json'},
           body: jsonEncode({'id_token': idToken}),
         );
         
         // Procesează răspunsul...
       }
     } catch (error) {
       print('Google Sign-In error: $error');
     }
   }
   ```

### Fișiere de descărcat din Google Cloud Console:

După ce creezi iOS Client ID, descarcă fișierul `.plist`:
- **Nume fișier:** `client_163361667480-5lksujehv7cpj50f2v1rdrr98g7cbkp6.apps.googleusercontent.com.plist`
- **Locație în Flutter:** `ios/Runner/GoogleService-Info.plist` (redenumește-l)

---

## 🍎 Configurare Apple OAuth

### Pasul 1: Creează un App ID în Apple Developer

1. Mergi la [Apple Developer Portal](https://developer.apple.com/account/)
2. Mergi la **Certificates, Identifiers & Profiles**
3. Click pe **Identifiers** → **+** (butonul plus)
4. Selectează **App IDs** → **Continue**
5. Selectează **App** → **Continue**
6. Completează:
   - **Description**: Recipy
   - **Bundle ID**: `com.yourcompany.recipy` (trebuie să fie unic)
7. Bifează **Sign in with Apple** → **Configure**
   - **Primary App ID**: selectează Bundle ID-ul creat
   - **Domains and Subdomains**: `yourdomain.com`
   - **Return URLs**: 
     - `http://localhost:3000/users/auth/apple/callback` (development)
     - `https://yourdomain.com/users/auth/apple/callback` (production)
8. Salvează și continuă

### Pasul 2: Creează o Service ID

1. În **Identifiers**, click **+** → **Services IDs** → **Continue**
2. Completează:
   - **Description**: Recipy Web Service
   - **Identifier**: `com.yourcompany.recipy.service` (unic)
3. Bifează **Sign in with Apple** → **Configure**
   - **Primary App ID**: selectează App ID-ul creat anterior
   - **Website URLs**:
     - `http://localhost:3000` (development)
     - `https://yourdomain.com` (production)
   - **Return URLs**: aceleași ca mai sus
4. Salvează

### Pasul 3: Creează o Key pentru Sign in with Apple

1. Mergi la **Keys** → **+** (butonul plus)
2. Completează:
   - **Key Name**: Recipy Sign In Key
   - Bifează **Sign in with Apple**
3. Click **Configure** → selectează **Primary App ID** creat anterior
4. **Continue** → **Register**
5. **Download** key-ul (`.p8` file) - **IMPORTANT**: poți descărca o singură dată!
6. Notează **Key ID** (apare în listă)

### Pasul 4: Obține Team ID

1. În Apple Developer Portal, sus în dreapta, vezi **Team ID**
2. Copiază acest ID

### Pasul 5: Generează Client Secret (JWT)

Pentru Apple, trebuie să generezi un JWT token ca Client Secret. Creează un script Ruby:

```ruby
# script/generate_apple_secret.rb
require 'jwt'
require 'openssl'

team_id = 'YOUR_TEAM_ID'
key_id = 'YOUR_KEY_ID'
client_id = 'com.yourcompany.recipy.service' # Service ID
private_key_path = 'path/to/AuthKey_XXXXXXXXXX.p8'

private_key = OpenSSL::PKey::EC.new(File.read(private_key_path))

headers = {
  'kid' => key_id
}

payload = {
  'iss' => team_id,
  'iat' => Time.now.to_i,
  'exp' => Time.now.to_i + 15777000, # 6 luni
  'aud' => 'https://appleid.apple.com',
  'sub' => client_id
}

token = JWT.encode(payload, private_key, 'ES256', headers)
puts token
```

Sau folosește un serviciu online sau gem-ul `jwt` pentru a genera token-ul.

### Pasul 6: Adaugă în .env

```env
APPLE_CLIENT_ID=com.yourcompany.recipy.service
APPLE_CLIENT_SECRET=eyJraWQiOiJ... (JWT token generat)
APPLE_TEAM_ID=ABC123DEF4
APPLE_KEY_ID=XYZ987ABC6
APPLE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
-----END PRIVATE KEY-----
```

**NOTĂ:** Pentru `APPLE_PRIVATE_KEY`, poți păstra conținutul fișierului `.p8` sau poți folosi path-ul către fișier (dacă modifici codul).

---

## ✅ Verificare Configurare

După ce ai completat toate variabilele în `.env`:

1. Restart serverul Rails:
   ```bash
   bin/rails server
   ```

2. Mergi la pagina de login/signup
3. Ar trebui să vezi butoanele "Sign in with Google" și "Sign in with Apple"
4. Click pe ele pentru a testa autentificarea

---

## 🚨 Troubleshooting

### Google OAuth nu funcționează:
- Verifică că redirect URI-urile sunt exacte (inclusiv `/callback`)
- Verifică că ai activat Google+ API
- Verifică că Client ID și Secret sunt corecte

### Apple OAuth nu funcționează:
- Verifică că Service ID-ul este corect în `APPLE_CLIENT_ID`
- Verifică că JWT token-ul este valid (nu a expirat)
- Verifică că Return URLs sunt exacte
- Verifică că key-ul `.p8` este corect

### Eroare "Invalid credentials":
- Verifică că toate variabilele din `.env` sunt completate
- Verifică că nu ai spații în plus în `.env`
- Restart serverul după modificări în `.env`

---

## 📝 Note Importante

1. **Nu commită niciodată `.env` în Git!** (deja este în `.gitignore`)
2. Pentru production, folosește variabile de mediu ale serverului (Heroku, AWS, etc.)
3. JWT token-ul pentru Apple expiră după 6 luni - va trebui să-l regenerezi
4. Pentru development local, poți testa fără OAuth (folosind email/password normal)

---

## 🔗 Link-uri Utile

- [Google OAuth Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Apple Sign In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [OmniAuth Google Strategy](https://github.com/zquestz/omniauth-google-oauth2)
- [OmniAuth Apple Strategy](https://github.com/nhosoya/omniauth-apple)

