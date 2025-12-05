# 🚀 Railway + Cloudflare R2 - Ghid Complet de Deploy

## 📋 Cuprins
1. [Pregătire Locală](#pregătire-locală)
2. [Setup Railway](#setup-railway)
3. [Setup Cloudflare R2](#setup-cloudflare-r2)
4. [Configurare Environment Variables](#configurare-environment-variables)
5. [Migrare Database](#migrare-database)
6. [Migrare Files](#migrare-files)
7. [Deploy & Testing](#deploy--testing)
8. [Post-Deploy](#post-deploy)

---

## 1. Pregătire Locală

### A. Install Railway CLI

```bash
# macOS
brew install railway

# Sau cu npm
npm install -g @railway/cli

# Verifică instalarea
railway --version
```

### B. Install AWS CLI (pentru migrare files)

```bash
# macOS
brew install awscli

# Verifică instalarea
aws --version
```

### C. Backup Local Database

```bash
# Navighează în folder-ul proiectului
cd /Users/dragosandrei/Documents/Ruby\ on\ Rails/Recipy

# Creează backup PostgreSQL
pg_dump -Fc --no-acl --no-owner \
  -h localhost \
  -U dragosandrei \
  backend_development > recipy_backup_$(date +%Y%m%d).dump

# Sau export ca SQL simplu
pg_dump -h localhost -U dragosandrei \
  backend_development > recipy_backup_$(date +%Y%m%d).sql

# Verifică că backup-ul s-a creat
ls -lh recipy_backup_*.dump
```

**⚠️ IMPORTANT:** Salvează acest fișier într-un loc sigur!

---

## 2. Setup Railway

### A. Creează Project în Railway

1. **Login în Railway:**
   ```
   https://railway.app/new
   ```

2. **Deploy from GitHub:**
   - Click "Deploy from GitHub"
   - Selectează repository-ul: `DragosAndrei1829/Recipy_Web`
   - Railway va detecta automat că este Rails și va configura build

3. **Așteaptă build-ul inițial:**
   - Va eșua prima dată (normal, lipsesc variabilele)
   - Continuăm cu setup-ul

### B. Adaugă PostgreSQL Database

1. **În Railway dashboard:**
   - Click butonul **"+ New"**
   - Selectează **"Database"**
   - Alege **"Add PostgreSQL"**
   - Așteaptă ~30 secunde să se provisioneze

2. **Obține connection details:**
   - Click pe **PostgreSQL service**
   - Tab **"Variables"**
   - Vei vedea variabilele automate:
     ```
     DATABASE_URL=postgresql://postgres:password@host.railway.internal:5432/railway
     PGHOST=host.railway.internal
     PGPORT=5432
     PGUSER=postgres
     PGPASSWORD=generated_password
     PGDATABASE=railway
     ```
   - **COPIAZĂ DATABASE_URL** - îl vei folosi pentru migrare

3. **Link database la app:**
   - Railway face asta automat
   - Verifică că în service-ul Rails vezi `DATABASE_URL` în Variables

### C. Adaugă Redis

1. **În Railway dashboard:**
   - Click butonul **"+ New"**
   - Selectează **"Database"**
   - Alege **"Add Redis"**
   - Așteaptă ~20 secunde

2. **Obține Redis URL:**
   - Click pe **Redis service**
   - Tab **"Variables"**
   - **COPIAZĂ REDIS_URL**: `redis://default:password@host:6379`

3. **Link Redis la app:**
   - Automat linked de Railway

---

## 3. Setup Cloudflare R2

### A. Creează R2 Bucket

1. **Login în Cloudflare:**
   ```
   https://dash.cloudflare.com
   ```

2. **Navighează la R2:**
   - Sidebar → **"R2 Object Storage"**
   - Click **"Create bucket"**

3. **Configurează bucket-ul:**
   - **Bucket name**: `recipy-production`
   - **Location**: `Eastern Europe (WEUR)` (pentru GDPR + latență mică)
   - Click **"Create bucket"**

### B. Creează API Token

1. **Manage R2 API Tokens:**
   - În R2 dashboard → **"Manage R2 API Tokens"** (sus-dreapta)
   - Click **"Create API token"**

2. **Configurează token:**
   - **Token name**: `recipy-app-production`
   - **Permissions**: ☑️ **"Object Read & Write"**
   - **TTL**: `Forever`
   - **Bucket**: ☑️ **"Apply to specific buckets only"**
     - Selectează: `recipy-production`
   - Click **"Create API Token"**

3. **⚠️ SALVEAZĂ CREDENTIALS (se afișează O SINGURĂ DATĂ!):**
   ```
   ✅ Access Key ID: a1b2c3d4e5f6g7h8i9j0
   ✅ Secret Access Key: abc123xyz789def456ghi789jkl012mno345pqr678
   ✅ Endpoint for S3 clients: https://1a2b3c4d5e6f7g8h.r2.cloudflarestorage.com
   ```
   
   **Copiază-le într-un fișier text ACUM!**

### C. Obține Account ID (pentru endpoint)

1. În Cloudflare dashboard:
   - Sidebar → **"R2"**
   - În partea dreaptă sus vezi: **"Account ID: abc123def456"**
   - **COPIAZĂ Account ID**

2. **Endpoint-ul complet va fi:**
   ```
   https://<ACCOUNT_ID>.r2.cloudflarestorage.com
   ```

---

## 4. Configurare Environment Variables

### A. În Railway Dashboard

1. **Navighează la Rails service:**
   - Click pe aplicația ta Rails
   - Tab **"Variables"**

2. **Adaugă toate variabilele (click "+ New Variable" pentru fiecare):**

#### **Database & Redis (automate, verifică că există):**
```bash
DATABASE_URL=postgresql://...  # Generat automat
REDIS_URL=redis://...          # Generat automat
```

#### **Rails Core:**
```bash
RAILS_MASTER_KEY=<copiază din config/master.key>
RAILS_ENV=production
RACK_ENV=production
SECRET_KEY_BASE=<generat automat de Railway sau rulează: rails secret>
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true
```

#### **Cloudflare R2 (File Storage):**
```bash
AWS_ACCESS_KEY_ID=<R2 Access Key ID>
AWS_SECRET_ACCESS_KEY=<R2 Secret Access Key>
AWS_REGION=auto
AWS_S3_BUCKET=recipy-production
AWS_ENDPOINT=https://<ACCOUNT_ID>.r2.cloudflarestorage.com
AWS_FORCE_PATH_STYLE=true
ACTIVE_STORAGE_SERVICE=amazon
```

#### **Stripe:**
```bash
STRIPE_PUBLISHABLE_KEY=pk_live_... (sau pk_test_... pentru testing)
STRIPE_SECRET_KEY=sk_live_... (sau sk_test_...)
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PRICE_ID_AI_CHAT=price_1SZWUZ2NDBfcf2CayD1Q9Sau
```

#### **Google OAuth:**
```bash
GOOGLE_OAUTH_CLIENT_ID=<din .env local>
GOOGLE_OAUTH_CLIENT_SECRET=<din .env local>
GOOGLE_OAUTH_IOS_CLIENT_ID=<din .env local, dacă ai>
```

#### **OpenAI (opțional):**
```bash
OPENAI_API_KEY=sk-... (dacă vrei să oferi OpenAI)
```

#### **Ollama (opțional, dacă vrei AI local pe server):**
```bash
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=llama3.1:8b
```

### B. Configurare `config/master.key`

**Găsește-l local:**
```bash
cat config/master.key
# Ex: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

**⚠️ NU face commit la acest fișier! Este deja în `.gitignore`**

---

## 5. Migrare Database

### A. Link Railway Project Local

```bash
# Login în Railway CLI
railway login

# Link la project-ul tău
cd /Users/dragosandrei/Documents/Ruby\ on\ Rails/Recipy
railway link

# Selectează project-ul și environment-ul (production)
```

### B. Run Migrations în Railway

```bash
# Verifică conexiunea
railway run rails db:version

# Rulează toate migrations
railway run rails db:migrate

# Verifică status
railway run rails db:migrate:status
```

### C. Import Date din Backup

#### **Opțiunea 1: Import cu railway CLI (Recomandată)**

```bash
# Import din dump
railway run pg_restore --verbose --clean --no-acl --no-owner \
  -d $DATABASE_URL recipy_backup_20251203.dump

# Sau din SQL
railway run psql $DATABASE_URL < recipy_backup_20251203.sql
```

#### **Opțiunea 2: Import direct (necesită DATABASE_URL)**

```bash
# Obține DATABASE_URL din Railway
railway variables

# Export local
RAILWAY_DB_URL="postgresql://postgres:pass@host:5432/railway"

# Import
pg_restore --verbose --clean --no-acl --no-owner \
  -d $RAILWAY_DB_URL recipy_backup_20251203.dump
```

### D. Verificare după Import

```bash
# Verifică numărul de înregistrări
railway run rails runner "
  puts '👥 Users: ' + User.count.to_s
  puts '🍽️  Recipes: ' + Recipe.count.to_s
  puts '💬 Comments: ' + Comment.count.to_s
  puts '❤️  Likes: ' + Like.count.to_s
  puts '📁 Attachments: ' + ActiveStorage::Attachment.count.to_s
"
```

---

## 6. Migrare Files (Storage)

### A. Setup AWS CLI pentru R2

```bash
# Configurează profil pentru R2
aws configure --profile r2

# Va cere:
AWS Access Key ID: <R2_ACCESS_KEY_ID>
AWS Secret Access Key: <R2_SECRET_ACCESS_KEY>
Default region name: auto
Default output format: json
```

### B. Test Conexiune R2

```bash
# Setează endpoint-ul R2
export R2_ENDPOINT=https://<ACCOUNT_ID>.r2.cloudflarestorage.com

# Testează listarea bucket-ului
aws s3 ls s3://recipy-production/ \
  --endpoint-url=$R2_ENDPOINT \
  --profile r2

# Ar trebui să returneze: (empty) sau lista de fișiere dacă există
```

### C. Migrare din Local Storage

```bash
# Navighează la folder-ul proiectului
cd /Users/dragosandrei/Documents/Ruby\ on\ Rails/Recipy

# Verifică ce fișiere ai local
ls -lh storage/
du -sh storage/

# Sync toate fișierele la R2
aws s3 sync storage/ s3://recipy-production/storage/ \
  --endpoint-url=$R2_ENDPOINT \
  --profile r2 \
  --exclude "*.DS_Store" \
  --exclude ".gitkeep" \
  --no-progress

# Verifică upload
aws s3 ls s3://recipy-production/storage/ \
  --endpoint-url=$R2_ENDPOINT \
  --profile r2 \
  --recursive | wc -l
```

### D. Migrare din AWS S3 (dacă ai files pe S3)

```bash
# Dacă ai AWS_ACCESS_KEY_ID și AWS_SECRET_ACCESS_KEY pentru S3 vechi
export OLD_S3_BUCKET="your-old-bucket"
export OLD_S3_REGION="eu-north-1"

# Sync direct S3 → R2 (fără download local!)
aws s3 sync s3://$OLD_S3_BUCKET/ s3://recipy-production/ \
  --source-region $OLD_S3_REGION \
  --endpoint-url=$R2_ENDPOINT \
  --profile r2 \
  --exclude "*.DS_Store"

# Verifică
aws s3 ls s3://recipy-production/ \
  --endpoint-url=$R2_ENDPOINT \
  --profile r2 \
  --recursive | head -20
```

---

## 7. Deploy & Testing

### A. Trigger Deploy în Railway

```bash
# Deploy automat la push
git push origin main

# Sau deploy manual via CLI
railway up

# Sau trigger redeploy în dashboard
# Railway dashboard → Service → Settings → "Restart"
```

### B. Watch Logs în Timp Real

```bash
# Via CLI
railway logs

# Sau în browser
# Railway dashboard → Service → "Deployments" → Click pe build → "View Logs"
```

### C. Verificare Deployment

```bash
# Obține URL-ul aplicației
railway domain

# Sau vezi în dashboard → Service → Settings → "Domains"
# Ex: recipy-web-production.up.railway.app

# Test homepage
curl -I https://recipy-web-production.up.railway.app

# Test database connection
railway run rails runner "puts 'DB OK: ' + User.count.to_s"

# Test Redis
railway run rails runner "Rails.cache.write('test', 'ok'); puts Rails.cache.read('test')"

# Test file upload (în browser)
# Mergi la: https://your-app.railway.app/ro/recipes/new
# Upload o poză → verifică că merge
```

---

## 8. Post-Deploy

### A. Setup Custom Domain (opțional)

1. **În Railway dashboard:**
   - Service → Settings → **"Domains"**
   - Click **"+ Custom Domain"**
   - Introdu: `recipy.ro` (sau domeniul tău)

2. **Update DNS Records (la provider-ul de domeniu):**
   ```
   Type: CNAME
   Name: @ (sau www)
   Value: <railway-provided-cname>
   TTL: 3600
   ```

3. **Așteaptă propagare DNS** (~5-30 minute)

4. **Railway generează automat SSL certificate** (Let's Encrypt)

### B. Setup Stripe Webhooks pentru Production

1. **În Stripe Dashboard:**
   ```
   https://dashboard.stripe.com/webhooks
   → "Add endpoint"
   ```

2. **Configurează webhook:**
   - **Endpoint URL**: `https://your-app.railway.app/stripe/webhook`
   - **Events to send**:
     - `checkout.session.completed`
     - `customer.subscription.created`
     - `customer.subscription.updated`
     - `customer.subscription.deleted`
     - `invoice.payment_succeeded`
     - `invoice.payment_failed`
   - Click **"Add endpoint"**

3. **Obține Signing Secret:**
   - Click pe webhook-ul nou creat
   - **Copiază "Signing secret"**: `whsec_...`
   - **Adaugă în Railway Variables**: `STRIPE_WEBHOOK_SECRET=whsec_...`

### C. Update Google OAuth Redirect URIs

1. **Google Cloud Console:**
   ```
   https://console.cloud.google.com/apis/credentials
   ```

2. **Selectează OAuth 2.0 Client ID:**
   - Click pe client ID-ul tău

3. **Add Authorized redirect URIs:**
   ```
   https://your-app.railway.app/users/auth/google_oauth2/callback
   https://recipy.ro/users/auth/google_oauth2/callback  (dacă ai custom domain)
   ```

4. **Save**

### D. Setup Monitoring & Alerts

1. **În Railway dashboard:**
   - Service → **"Observability"**
   - Vezi: CPU, RAM, Network usage

2. **Setup Email Alerts:**
   - Account Settings → **"Notifications"**
   - ☑️ "Deployment failures"
   - ☑️ "Resource usage warnings"

### E. Backup Automat

**Railway face backup PostgreSQL automat:**
- Daily backups (păstrate 7 zile)
- Restore din: Database service → "Backups" tab

**Pentru R2 (Cloudflare):**
- R2 are **durability 99.999999999%** (11 nines)
- Nu necesită backup suplimentar
- Poți activa **Object Versioning** pentru extra siguranță:
  - R2 bucket → Settings → Enable versioning

---

## 9. Costuri Estimate

### **Railway (App + Database + Redis):**
```
PostgreSQL 512MB:     $5/lună
Redis 256MB:          $5/lună  
App deployment:       $5/lună (base) + CPU usage
CPU usage (~500 req/day): ~$3-5/lună
─────────────────────────────────
TOTAL Railway:        ~$18-20/lună
```

### **Cloudflare R2 (Files):**
```
Storage (10GB):       🆓 GRATIS (inclus)
Storage (100GB):      $1.50/lună ($0.015/GB)
Bandwidth:            🆓 GRATIS (nelimitat!)
Class A operations:   $4.50/million (upload)
Class B operations:   $0.36/million (download)
─────────────────────────────────
TOTAL R2 (1000 useri): ~$0-2/lună
```

### **COST TOTAL LUNAR:**
```
100 useri:            $18-20/lună
1,000 useri:          $22-25/lună
5,000 useri:          $40-50/lună
10,000 useri:         $80-100/lună
```

---

## 10. Environment Variables - Checklist Complet

### **📝 Copiază acest template în Railway Variables:**

```bash
# ═══════════════════════════════════════
# DATABASE & CACHE (generat automat)
# ═══════════════════════════════════════
DATABASE_URL=postgresql://postgres:...@...railway.internal:5432/railway
REDIS_URL=redis://default:...@...railway.internal:6379

# ═══════════════════════════════════════
# RAILS CONFIGURATION
# ═══════════════════════════════════════
RAILS_MASTER_KEY=<din config/master.key>
RAILS_ENV=production
RACK_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true

# ═══════════════════════════════════════
# CLOUDFLARE R2 (FILE STORAGE)
# ═══════════════════════════════════════
AWS_ACCESS_KEY_ID=<R2 Access Key ID>
AWS_SECRET_ACCESS_KEY=<R2 Secret Access Key>
AWS_REGION=auto
AWS_S3_BUCKET=recipy-production
AWS_ENDPOINT=https://<ACCOUNT_ID>.r2.cloudflarestorage.com
AWS_FORCE_PATH_STYLE=true
ACTIVE_STORAGE_SERVICE=amazon

# ═══════════════════════════════════════
# STRIPE PAYMENTS
# ═══════════════════════════════════════
STRIPE_PUBLISHABLE_KEY=pk_live_...  # sau pk_test_... pentru testing
STRIPE_SECRET_KEY=sk_live_...       # sau sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PRICE_ID_AI_CHAT=price_1SZWUZ2NDBfcf2CayD1Q9Sau

# ═══════════════════════════════════════
# GOOGLE OAUTH
# ═══════════════════════════════════════
GOOGLE_OAUTH_CLIENT_ID=<din .env local>
GOOGLE_OAUTH_CLIENT_SECRET=<din .env local>
GOOGLE_OAUTH_IOS_CLIENT_ID=<dacă ai iOS app>

# ═══════════════════════════════════════
# OPENAI (optional)
# ═══════════════════════════════════════
OPENAI_API_KEY=sk-...  # Dacă oferi OpenAI premium

# ═══════════════════════════════════════
# OLLAMA (optional - pentru AI local pe server)
# ═══════════════════════════════════════
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=llama3.1:8b
```

---

## 11. Quick Commands Reference

### **Railway CLI:**
```bash
# Login
railway login

# Link project
railway link

# View logs
railway logs

# Run command
railway run rails console

# View variables
railway variables

# Open dashboard
railway open

# Deploy
railway up
```

### **Database Management:**
```bash
# Rails console în production
railway run rails console

# Run migration
railway run rails db:migrate

# Rollback migration
railway run rails db:rollback

# Seed data
railway run rails db:seed

# Database console
railway run psql $DATABASE_URL
```

### **R2 File Management:**
```bash
# List all files
aws s3 ls s3://recipy-production/ \
  --endpoint-url=https://<ACCOUNT_ID>.r2.cloudflarestorage.com \
  --profile r2 \
  --recursive

# Check storage size
aws s3 ls s3://recipy-production/ \
  --endpoint-url=https://<ACCOUNT_ID>.r2.cloudflarestorage.com \
  --profile r2 \
  --recursive \
  --summarize \
  --human-readable

# Download a file
aws s3 cp s3://recipy-production/path/to/file.jpg ./local.jpg \
  --endpoint-url=https://<ACCOUNT_ID>.r2.cloudflarestorage.com \
  --profile r2
```

---

## 12. Troubleshooting

### **Eroare: "PG::ConnectionBad"**
```bash
# Verifică DATABASE_URL
railway variables | grep DATABASE_URL

# Test conexiune
railway run rails db:version
```

### **Eroare: "Aws::S3::Errors::InvalidAccessKeyId"**
```bash
# Verifică R2 credentials
railway variables | grep AWS_

# Test manual
aws s3 ls s3://recipy-production/ \
  --endpoint-url=<AWS_ENDPOINT> \
  --profile r2
```

### **Eroare: "Redis connection refused"**
```bash
# Verifică REDIS_URL
railway variables | grep REDIS_URL

# Test Redis
railway run rails runner "Rails.cache.write('test', Time.now); puts Rails.cache.read('test')"
```

### **Images nu se încarcă:**
```bash
# Verifică Active Storage în production
railway run rails runner "
  puts 'Service: ' + ActiveStorage::Blob.service.class.name
  puts 'Attachments: ' + ActiveStorage::Attachment.count.to_s
  attachment = ActiveStorage::Attachment.first
  if attachment
    puts 'First attachment URL: ' + Rails.application.routes.url_helpers.rails_blob_url(attachment.blob, host: 'https://your-app.railway.app')
  end
"
```

### **Build failure în Railway:**
```bash
# Verifică logs
railway logs --deployment

# Verifică Gemfile.lock este commitat
git add Gemfile.lock
git commit -m "Add Gemfile.lock"
git push
```

---

## 13. Security Checklist

### **Înainte de Go-Live:**

```bash
✅ RAILS_MASTER_KEY setat în Railway (nu în repo!)
✅ Toate secretele în environment variables (nu hardcodate)
✅ SSL activat (Railway face automat)
✅ Stripe webhook signature verificată
✅ Content Security Policy activată (vezi config/initializers/content_security_policy.rb)
✅ Rack::Attack activat pentru rate limiting
✅ Google OAuth redirect URIs actualizate pentru production
✅ Backup database testat (export + import)
✅ R2 bucket setat ca PRIVATE (nu public)
✅ CORS configurat corect pe R2 (dacă e nevoie)
```

---

## 14. Scaling Strategy

### **Când ai 100-500 useri:**
- ✅ Railway Basic ($18-25/lună)
- ✅ PostgreSQL 512MB
- ✅ Redis 256MB
- ✅ R2 10-50GB

### **Când ai 1,000-5,000 useri:**
- ✅ Railway Pro ($40-60/lună)
- ✅ PostgreSQL 2GB ($15/lună)
- ✅ Redis 1GB ($10/lună)
- ✅ R2 100-500GB ($1-8/lună)

### **Când ai 10,000+ useri:**
- 🚀 Consideră **AWS/GCP managed services**
- 🚀 Multi-region deployment
- 🚀 CDN dedicat (Cloudflare Pro)
- 🚀 Dedicated Redis cluster

---

## 15. Monitorizare & Maintenance

### **Railway Monitoring:**
```
Dashboard → Service → "Metrics"
- CPU usage
- Memory usage
- Network I/O
- Request latency
```

### **Setup Error Tracking (Sentry - recomandat):**

1. **Creează cont gratuit:** https://sentry.io
2. **Adaugă în Gemfile:**
   ```ruby
   gem "sentry-ruby"
   gem "sentry-rails"
   ```
3. **Configurează:**
   ```bash
   # În Railway variables
   SENTRY_DSN=https://...@sentry.io/...
   ```

### **Health Checks:**
```bash
# Adaugă în Railway
# Settings → "Health Check Path": /up

# Railway va verifica /up la fiecare 30s
# Rails 7.1+ include /up endpoint by default
```

---

## 16. Rollback Strategy

### **Dacă deploy-ul merge prost:**

```bash
# În Railway dashboard
→ Service → "Deployments"
→ Click pe deployment-ul anterior (care mergea)
→ Click "Redeploy"

# Sau via CLI
railway rollback
```

### **Dacă trebuie rollback database:**
```bash
# Restore din backup Railway
# Dashboard → PostgreSQL → "Backups" → Select backup → "Restore"

# Sau import backup local
railway run pg_restore -d $DATABASE_URL recipy_backup_good.dump
```

---

## 17. Cost Optimization Tips

### **💰 Reduci costurile cu:**

1. **Image optimization:**
   ```ruby
   # Compress images before upload
   gem 'image_processing'
   
   # În model:
   variant(resize_to_limit: [1200, nil], saver: { quality: 85 })
   ```

2. **Cleanup unused attachments:**
   ```bash
   # Periodic cleanup (rulează lunar)
   railway run rails runner "
     ActiveStorage::Blob.unattached.where('created_at < ?', 7.days.ago).find_each(&:purge)
   "
   ```

3. **Use Redis pentru cache agresiv:**
   ```ruby
   # Cache expensive queries
   Rails.cache.fetch('top_recipes_week', expires_in: 1.hour) do
     Recipe.top_this_week.to_a
   end
   ```

4. **Lazy load images:**
   ```html
   <%= image_tag url, loading: "lazy" %>
   ```

---

## 📞 Support & Help

### **Railway:**
- Discord: https://discord.gg/railway
- Docs: https://docs.railway.app
- Status: https://status.railway.app

### **Cloudflare R2:**
- Docs: https://developers.cloudflare.com/r2/
- Community: https://community.cloudflare.com
- Support: https://dash.cloudflare.com → Support

### **Debugging:**
```bash
# Check all environment variables
railway variables

# Interactive Rails console
railway run rails console

# Run any Rails command
railway run rails <command>

# SSH into container (dacă e nevoie)
railway shell
```

---

## ✅ Final Checklist

```
PRE-DEPLOY:
☐ Railway account creat
☐ PostgreSQL provisionat
☐ Redis provisionat
☐ R2 bucket creat
☐ R2 API token generat
☐ Toate environment variables setate în Railway
☐ Backup local database creat
☐ config/master.key copiat în Railway

DEPLOYMENT:
☐ Code pushed la GitHub
☐ Railway build successful
☐ Database migrated
☐ Data importată din backup
☐ Files migrated la R2
☐ Test homepage funcționează
☐ Test login funcționează
☐ Test upload poză funcționează

POST-DEPLOY:
☐ Custom domain configurat (opțional)
☐ SSL activat (automat de Railway)
☐ Stripe webhooks actualizate
☐ Google OAuth URIs actualizate
☐ Monitoring activ
☐ Backup strategy în loc
```

---

## 🎯 Quick Start (când ai toate key-urile)

```bash
# 1. Login Railway
railway login
railway link

# 2. Add toate variabilele în Railway dashboard

# 3. Deploy
git push origin main

# 4. Migrate database
railway run rails db:migrate

# 5. Import data
railway run pg_restore -d $DATABASE_URL recipy_backup.dump

# 6. Sync files la R2
aws s3 sync storage/ s3://recipy-production/storage/ \
  --endpoint-url=$R2_ENDPOINT --profile r2

# 7. Verifică
railway open

# ✅ DONE!
```

---

## 📚 Next Steps

După deployment, poți:
1. **Add custom domain** (recipy.ro)
2. **Enable CDN** prin Cloudflare (gratuit)
3. **Setup error tracking** (Sentry)
4. **Add uptime monitoring** (UptimeRobot - gratuit)
5. **Configure email** (SendGrid/Postmark pentru production emails)

---

Succes la deployment! 🚀 Când ai toate key-urile, revino și facem migrarea împreună!




