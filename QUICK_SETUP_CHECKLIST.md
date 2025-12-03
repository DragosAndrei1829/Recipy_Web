# ✅ Quick Setup Checklist - Railway + Cloudflare R2

## 📝 Acest ghid te ajută să obții toate key-urile necesare

---

## STEP 1: Railway Setup (10 minute)

### ☐ 1.1 Creează cont Railway
```
https://railway.app/new
→ Sign up with GitHub
```

### ☐ 1.2 Creează Project
```
→ "New Project"
→ "Deploy from GitHub repo"
→ Selectează: DragosAndrei1829/Recipy_Web
→ Așteaptă build (va eșua - normal, lipsesc variables)
```

### ☐ 1.3 Adaugă PostgreSQL
```
→ Click "+ New" în project
→ "Database" → "PostgreSQL"
→ Așteaptă 30s să se creeze
```

### ☐ 1.4 Copiază PostgreSQL URL
```
→ Click pe "PostgreSQL" service
→ Tab "Variables"
→ COPIAZĂ: DATABASE_URL
   Format: postgresql://postgres:pass@host.railway.internal:5432/railway

📋 Salvează în notepad:
DATABASE_URL=___________________________________________
```

### ☐ 1.5 Adaugă Redis
```
→ Click "+ New"
→ "Database" → "Redis"
→ Așteaptă 20s
```

### ☐ 1.6 Copiază Redis URL
```
→ Click pe "Redis" service
→ Tab "Variables"
→ COPIAZĂ: REDIS_URL
   Format: redis://default:pass@host.railway.internal:6379

📋 Salvează în notepad:
REDIS_URL=___________________________________________
```

### ☐ 1.7 Obține RAILS_MASTER_KEY
```bash
# În terminal local:
cat config/master.key

📋 Salvează în notepad:
RAILS_MASTER_KEY=___________________________________________
```

---

## STEP 2: Cloudflare R2 Setup (5 minute)

### ☐ 2.1 Login Cloudflare
```
https://dash.cloudflare.com
→ Login cu contul tău
```

### ☐ 2.2 Navighează la R2
```
→ Sidebar stânga → "R2 Object Storage"
→ Dacă e prima dată, click "Purchase R2"
   (Nu plătești nimic, doar activezi serviciul)
```

### ☐ 2.3 Creează Bucket
```
→ Click "Create bucket"
→ Bucket name: recipy-production
→ Location: "Eastern Europe (WEUR)" (pentru GDPR + viteză)
→ Click "Create bucket"
```

### ☐ 2.4 Creează API Token
```
→ În R2 dashboard, click "Manage R2 API Tokens" (sus-dreapta)
→ Click "Create API token"

Configurare:
  Token name: recipy-app-production
  Permissions: ☑️ "Object Read & Write"
  TTL: "Forever"
  Bucket: ☑️ "Apply to specific buckets only"
    → Selectează: recipy-production
  
→ Click "Create API Token"
```

### ☐ 2.5 Salvează Credentials (⚠️ SE AFIȘEAZĂ O SINGURĂ DATĂ!)
```
Vei vedea un ecran cu:

✅ Access Key ID: a1b2c3d4e5f6g7h8i9j0
✅ Secret Access Key: abc123xyz789def456ghi789jkl012mno345pqr678
✅ Endpoint for S3 clients: https://1a2b3c4d5e6f7g8h.r2.cloudflarestorage.com

📋 COPIAZĂ ACUM în notepad (nu mai poți vedea Secret Key după!):
AWS_ACCESS_KEY_ID=___________________________________________
AWS_SECRET_ACCESS_KEY=___________________________________________
R2_ENDPOINT=___________________________________________
```

### ☐ 2.6 Obține Account ID
```
→ În Cloudflare dashboard, sidebar → "R2"
→ În partea dreaptă sus vezi: "Account ID: abc123def456"

📋 Salvează în notepad:
CLOUDFLARE_ACCOUNT_ID=___________________________________________

Endpoint complet va fi:
AWS_ENDPOINT=https://<ACCOUNT_ID>.r2.cloudflarestorage.com
```

---

## STEP 3: Stripe Keys (2 minute)

### ☐ 3.1 Login Stripe
```
https://dashboard.stripe.com
```

### ☐ 3.2 Obține API Keys
```
→ Developers → "API keys"

📋 Copiază:
STRIPE_PUBLISHABLE_KEY=pk_test_... (sau pk_live_... pentru production)
STRIPE_SECRET_KEY=sk_test_... (sau sk_live_...)
```

### ☐ 3.3 Obține Price ID
```
→ Products → Click pe "AI Chat Premium"
→ Pricing → Copiază Price ID

📋 Salvează:
STRIPE_PRICE_ID_AI_CHAT=price_1SZWUZ2NDBfcf2CayD1Q9Sau
```

### ☐ 3.4 Setup Webhook (după deploy)
```
⏸️ SKIP DEOCAMDATĂ - vei face după ce ai URL-ul de production
```

---

## STEP 4: Google OAuth Keys (2 minute)

### ☐ 4.1 Login Google Cloud Console
```
https://console.cloud.google.com/apis/credentials
```

### ☐ 4.2 Selectează Project
```
→ Selectează project-ul "Recipy" (sau cum l-ai numit)
```

### ☐ 4.3 Copiază Credentials
```
→ Click pe OAuth 2.0 Client ID-ul tău (Web client)

📋 Copiază:
GOOGLE_OAUTH_CLIENT_ID=___________________________________________
GOOGLE_OAUTH_CLIENT_SECRET=___________________________________________

Dacă ai iOS client:
GOOGLE_OAUTH_IOS_CLIENT_ID=___________________________________________
```

---

## STEP 5: Add Variables în Railway (5 minute)

### ☐ 5.1 Navighează la Rails Service
```
Railway dashboard → Click pe service-ul Rails
→ Tab "Variables"
```

### ☐ 5.2 Add Toate Variabilele

**Click "+ New Variable" și adaugă fiecare:**

```bash
# ═══ RAILS CORE ═══
RAILS_MASTER_KEY=<din config/master.key>
RAILS_ENV=production
RACK_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true

# ═══ CLOUDFLARE R2 ═══
AWS_ACCESS_KEY_ID=<R2 Access Key ID>
AWS_SECRET_ACCESS_KEY=<R2 Secret Access Key>
AWS_REGION=auto
AWS_S3_BUCKET=recipy-production
AWS_ENDPOINT=https://<ACCOUNT_ID>.r2.cloudflarestorage.com
AWS_FORCE_PATH_STYLE=true
ACTIVE_STORAGE_SERVICE=amazon

# ═══ STRIPE ═══
STRIPE_PUBLISHABLE_KEY=<din Stripe>
STRIPE_SECRET_KEY=<din Stripe>
STRIPE_PRICE_ID_AI_CHAT=price_1SZWUZ2NDBfcf2CayD1Q9Sau

# ═══ GOOGLE OAUTH ═══
GOOGLE_OAUTH_CLIENT_ID=<din Google Console>
GOOGLE_OAUTH_CLIENT_SECRET=<din Google Console>
```

**⚠️ DATABASE_URL și REDIS_URL sunt deja setate automat de Railway!**

### ☐ 5.3 Verifică Variables
```
→ Tab "Variables"
→ Ar trebui să vezi ~15-20 variabile
→ Verifică că toate sunt completate (nu "undefined")
```

---

## STEP 6: Deploy (1 minut)

### ☐ 6.1 Trigger Redeploy
```
Railway dashboard → Service → Settings
→ Click "Restart" sau "Redeploy"

Sau push un commit:
git commit --allow-empty -m "Trigger deploy"
git push origin main
```

### ☐ 6.2 Watch Build Logs
```
→ Tab "Deployments"
→ Click pe build-ul activ
→ "View Logs"

Așteaptă ~3-5 minute
Ar trebui să vezi: "✓ Build successful"
```

### ☐ 6.3 Obține URL Production
```
→ Tab "Settings" → "Domains"
→ Vei vedea: https://recipy-web-production.up.railway.app

📋 Salvează URL-ul:
PRODUCTION_URL=___________________________________________
```

---

## STEP 7: Verificare Rapidă (2 minute)

### ☐ 7.1 Test Homepage
```
Deschide în browser:
https://your-app.railway.app

Ar trebui să vezi pagina de login/home
```

### ☐ 7.2 Test Database Connection
```bash
# În terminal local:
railway login
railway link  # Selectează project-ul tău

# Test
railway run rails runner "puts 'Users: ' + User.count.to_s"

Ar trebui să returneze: Users: 0 (normal, database e goală)
```

### ☐ 7.3 Test Redis
```bash
railway run rails runner "
  Rails.cache.write('test', 'OK')
  puts 'Redis: ' + Rails.cache.read('test').to_s
"

Ar trebui să returneze: Redis: OK
```

---

## 🎯 GATA CU SETUP-UL INIȚIAL!

**Ai terminat configurarea! Acum ai:**
- ✅ Railway project cu PostgreSQL + Redis
- ✅ Cloudflare R2 bucket pentru files
- ✅ Toate environment variables setate
- ✅ App deployed și funcțional (fără date încă)

---

## 📦 NEXT STEPS (când ești gata să migrezi datele):

### **Migrare Database:**
```bash
# 1. Export local
pg_dump -Fc --no-acl --no-owner backend_development > backup.dump

# 2. Import în Railway
railway run pg_restore -d $DATABASE_URL backup.dump

# 3. Verifică
railway run rails runner "puts User.count"
```

### **Migrare Files:**
```bash
# 1. Setup AWS CLI
aws configure --profile r2

# 2. Sync la R2
aws s3 sync storage/ s3://recipy-production/storage/ \
  --endpoint-url=https://<ACCOUNT_ID>.r2.cloudflarestorage.com \
  --profile r2
```

### **Post-Deploy:**
1. ☐ Update Stripe webhook URL
2. ☐ Update Google OAuth redirect URIs
3. ☐ Add custom domain (opțional)
4. ☐ Test complete flow (signup, login, upload, etc.)

---

## 💰 Cost Tracking

**Verifică costurile în:**
- Railway: Dashboard → "Usage" (vezi CPU/RAM/Network)
- Cloudflare R2: Dashboard → R2 → "Usage & Billing"

**Estimate pentru început:**
- Railway: ~$15-20/lună (500-1000 useri)
- R2: 🆓 GRATIS până la 10GB storage

---

## 🆘 Dacă ceva nu merge:

1. **Check logs:** `railway logs`
2. **Check variables:** `railway variables`
3. **Check build:** Railway dashboard → Deployments → View Logs
4. **Discord support:** https://discord.gg/railway

---

## 📞 Contact Info pentru Support:

- **Railway Discord**: https://discord.gg/railway
- **Cloudflare Community**: https://community.cloudflare.com
- **Stripe Support**: https://support.stripe.com

---

**🎉 Succes la deployment!**

Când ai toate key-urile și ești gata să migrezi datele, revino și continuăm cu migrarea! 🚀

