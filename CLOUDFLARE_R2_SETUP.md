# ☁️ Cloudflare R2 Setup - Ghid Simplu

## 🎯 Ce trebuie să faci:

1. Creezi un bucket R2 în Cloudflare
2. Generezi un API token
3. Îmi trimiți 4 valori
4. Le adăugăm în Railway
5. Sincronizăm imaginile vechi

---

## STEP 1: Login Cloudflare

```
https://dash.cloudflare.com
→ Login cu contul tău
```

---

## STEP 2: Activează R2

```
→ Sidebar stânga → "R2 Object Storage"
→ Dacă e prima dată: Click "Purchase R2"
   (Nu plătești nimic, doar activezi serviciul)
→ "Begin setup"
```

---

## STEP 3: Creează Bucket

```
→ Click "Create bucket"

Completează:
  Bucket name: recipy-production
  Location: Eastern Europe (WEUR)  ← Important pentru GDPR!
  
→ Click "Create bucket"
```

---

## STEP 4: Creează API Token

```
→ În R2 dashboard, sus-dreapta: "Manage R2 API Tokens"
→ Click "Create API token"

Configurare:
  Token name: recipy-railway-production
  Permissions: ☑️ Object Read & Write
  TTL: Forever
  Bucket: ☑️ Apply to specific buckets only
    → Bifează: recipy-production
  
→ Click "Create API Token"
```

---

## STEP 5: ⚠️ SALVEAZĂ CREDENTIALS (SE AFIȘEAZĂ O SINGURĂ DATĂ!)

Vei vedea un ecran cu 3 valori:

```
✅ Access Key ID: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
✅ Secret Access Key: abc123xyz789def456ghi789jkl012mno345pqr678stu901vwx234
✅ Endpoint for S3 clients: https://1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p.r2.cloudflarestorage.com
```

**📋 COPIAZĂ TOATE 3 ACUM într-un notepad!**

După ce închizi ecranul, **NU mai poți vedea Secret Access Key**!

---

## STEP 6: Obține Account ID

```
→ În Cloudflare dashboard, orice pagină
→ Sus-dreapta sau sidebar stânga → vezi "Account ID"
→ Sau în R2 dashboard, sus-dreapta

Example: abc123def456
```

---

## ✅ TRIMITE-MI ACESTE 4 VALORI:

```
1. R2_ACCESS_KEY_ID=___________________________________________

2. R2_SECRET_ACCESS_KEY=___________________________________________

3. R2_ENDPOINT=https://___________________________________________

4. CLOUDFLARE_ACCOUNT_ID=___________________________________________
```

---

## 🔒 Security Note:

- ✅ Bucket-ul e **PRIVATE** by default (bine!)
- ✅ API Token-ul funcționează doar pentru bucket-ul specificat
- ✅ Poți revoca token-ul oricând din dashboard

---

## 💰 Costuri R2:

```
Storage:
  10 GB/lună: 🆓 GRATIS
  100 GB/lună: $1.50
  1 TB/lună: $15

Bandwidth: 🆓 GRATIS (nelimitat!)

Operations:
  Class A (upload): $4.50/million
  Class B (download): $0.36/million
  
Pentru 1000 useri activi: ~$0-2/lună
```

---

## 📝 După ce am credentials:

1. Le adăugăm în Railway Variables
2. Redeploy automat
3. Sincronizăm imaginile vechi (din S3 sau local)
4. Testăm că imaginile se încarcă
5. ✅ Done!

---

**Trimite-mi cele 4 valori când le ai!** 🚀




