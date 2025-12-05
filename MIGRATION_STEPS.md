# 🚀 Pași Exacti pentru Migrare la Railway

## ✅ Backup-uri Create cu Succes!

```
✅ recipy_backup_20251203_184614.dump (164KB) - Format PostgreSQL
✅ recipy_backup_20251203_184615.sql (149KB) - Format SQL
```

**⚠️ Aceste backup-uri conțin toate datele tale! Păstrează-le în siguranță!**

---

## STEP 1: Login Railway (manual în terminal)

```bash
# Deschide un terminal NORMAL (nu în Cursor)
# Navighează la project
cd "/Users/dragosandrei/Documents/Ruby on Rails/Recipy"

# Login Railway (va deschide browser)
railway login

# Vei fi redirecționat la browser pentru autentificare
# După login, revino în terminal
```

---

## STEP 2: Link Project Railway

```bash
# Link la project-ul tău
railway link

# Vei fi întrebat:
# "Select a project" → Alege project-ul tău (ex: "Recipy_Web")
# "Select an environment" → Alege "production"

# Verifică că s-a linked corect
railway status
```

---

## STEP 3: Verifică Conexiunea la Railway Database

```bash
# Test conexiune
railway run rails db:version

# Ar trebui să vezi: "Current version: 0" (database goală)
```

---

## STEP 4: Run Migrations în Railway

```bash
# Rulează toate migrations
railway run rails db:migrate

# Verifică status
railway run rails db:migrate:status

# Ar trebui să vezi lista de migrations cu "up" status
```

---

## STEP 5: Import Date din Backup

### **Opțiunea A: Import cu pg_restore (Recomandată)**

```bash
# Import din dump (format comprimat)
railway run pg_restore --verbose --clean --no-acl --no-owner \
  -d postgresql://postgres:KpSJwdYhVbOkxObPIBoYLOBEJAAJycQx@postgres.railway.internal:5432/railway \
  recipy_backup_20251203_184614.dump

# Sau mai simplu (Railway setează automat DATABASE_URL)
railway run bash -c 'pg_restore --verbose --clean --no-acl --no-owner -d $DATABASE_URL recipy_backup_20251203_184614.dump'
```

### **Opțiunea B: Import cu psql (SQL simplu)**

```bash
# Import din SQL
railway run bash -c 'psql $DATABASE_URL < recipy_backup_20251203_184615.sql'
```

**⚠️ Dacă vezi erori de tipul "already exists" - e normal! Continuă.**

---

## STEP 6: Verificare Date Importate

```bash
# Verifică numărul de înregistrări
railway run rails runner "
  puts '═══════════════════════════════════'
  puts '📊 VERIFICARE DATE IMPORTATE'
  puts '═══════════════════════════════════'
  puts '👥 Users: ' + User.count.to_s
  puts '🍽️  Recipes: ' + Recipe.count.to_s
  puts '💬 Comments: ' + Comment.count.to_s
  puts '❤️  Likes: ' + Like.count.to_s
  puts '⭐ Favorites: ' + Favorite.count.to_s
  puts '📁 Attachments: ' + ActiveStorage::Attachment.count.to_s
  puts '🖼️  Blobs: ' + ActiveStorage::Blob.count.to_s
  puts '═══════════════════════════════════'
"

# Verifică un user specific
railway run rails runner "
  user = User.first
  if user
    puts 'First user: ' + user.username.to_s
    puts 'Email: ' + user.email.to_s
    puts 'Recipes: ' + user.recipes.count.to_s
  else
    puts '⚠️  No users found!'
  end
"
```

---

## STEP 7: Test Conexiune Redis

```bash
# Test Redis cache
railway run rails runner "
  Rails.cache.write('test_key', 'Railway Redis OK!')
  result = Rails.cache.read('test_key')
  puts '✅ Redis: ' + result.to_s
"
```

---

## STEP 8: Add Environment Variables în Railway

### **În Railway Dashboard:**

1. **Navighează la Rails service:**
   ```
   Railway dashboard → Click pe service-ul Rails
   → Tab "Variables"
   ```

2. **Add variabilele (click "+ New Variable"):**

```bash
# ═══ RAILS CORE ═══
RAILS_MASTER_KEY=<copiază din config/master.key>
RAILS_ENV=production
RACK_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true

# ═══ STRIPE ═══
STRIPE_PUBLISHABLE_KEY=<din Stripe dashboard>
STRIPE_SECRET_KEY=<din Stripe dashboard>
STRIPE_PRICE_ID_AI_CHAT=price_1SZWUZ2NDBfcf2CayD1Q9Sau

# ═══ GOOGLE OAUTH ═══
GOOGLE_OAUTH_CLIENT_ID=<din .env local>
GOOGLE_OAUTH_CLIENT_SECRET=<din .env local>

# ═══ ACTIVE STORAGE (deocamdată local, apoi R2) ═══
ACTIVE_STORAGE_SERVICE=local
```

**⚠️ DATABASE_URL și REDIS_URL sunt deja setate automat!**

---

## STEP 9: Trigger Deploy

```bash
# Commit și push (trigger auto-deploy)
git add .
git commit -m "Configure for Railway deployment"
git push origin main

# Sau trigger manual
railway up
```

---

## STEP 10: Watch Deployment

```bash
# Watch logs în timp real
railway logs

# Sau în browser:
# Railway dashboard → Service → "Deployments" → Click pe build → "View Logs"
```

---

## STEP 11: Test Production App

```bash
# Obține URL-ul production
railway domain

# Sau vezi în dashboard → Service → Settings → "Domains"
# Ex: recipy-web-production.up.railway.app

# Test în browser
open https://recipy-web-production.up.railway.app

# Sau cu curl
curl -I https://recipy-web-production.up.railway.app
```

---

## STEP 12: Test Login & Funcționalități

1. **Deschide app în browser**
2. **Încearcă să te loghezi** cu un user existent
3. **Verifică că datele sunt acolo:**
   - Vezi rețetele
   - Vezi profile-ul
   - Vezi conversații

---

## 🔧 Troubleshooting

### **Dacă import-ul eșuează:**

```bash
# Verifică conexiunea
railway run psql $DATABASE_URL -c "SELECT version();"

# Verifică că database e goală înainte de import
railway run rails runner "puts User.count"

# Dacă ai deja date și vrei să le ștergi:
railway run rails db:drop db:create db:migrate

# Apoi re-import
railway run bash -c 'pg_restore --verbose --clean --no-acl --no-owner -d $DATABASE_URL recipy_backup_20251203_184614.dump'
```

### **Dacă vezi erori "relation already exists":**

```bash
# Normal! Migrations au creat tabelele deja
# pg_restore va încerca să le creeze din nou
# Ignoră aceste erori și continuă

# Verifică că datele s-au importat:
railway run rails runner "puts User.count"
```

### **Dacă Railway build eșuează:**

```bash
# Verifică logs
railway logs --deployment

# Verifică că Gemfile.lock e commitat
git add Gemfile.lock
git commit -m "Add Gemfile.lock"
git push

# Verifică Ruby version în Gemfile
# Ar trebui să fie: ruby "3.2.2"
```

---

## 📊 Verificare Finală

După ce totul merge, rulează:

```bash
railway run rails runner "
  puts '═══════════════════════════════════════════'
  puts '✅ RAILWAY PRODUCTION - STATUS CHECK'
  puts '═══════════════════════════════════════════'
  puts 'Environment: ' + Rails.env
  puts 'Database: ' + ActiveRecord::Base.connection.adapter_name
  puts 'Cache store: ' + Rails.cache.class.name
  puts '─────────────────────────────────────────'
  puts '👥 Users: ' + User.count.to_s
  puts '🍽️  Recipes: ' + Recipe.count.to_s
  puts '💬 Comments: ' + Comment.count.to_s
  puts '❤️  Likes: ' + Like.count.to_s
  puts '📁 Attachments: ' + ActiveStorage::Attachment.count.to_s
  puts '🎨 Themes: ' + Theme.count.to_s
  puts '👥 Subscriptions: ' + Subscription.count.to_s
  puts '═══════════════════════════════════════════'
  
  # Test Redis
  Rails.cache.write('test', Time.now.to_s)
  puts '✅ Redis: ' + Rails.cache.read('test').to_s
  puts '═══════════════════════════════════════════'
"
```

---

## 🎯 Quick Commands Reference

```bash
# Login Railway
railway login

# Link project
railway link

# View logs
railway logs

# Run Rails console
railway run rails console

# Run any command
railway run <command>

# View variables
railway variables

# Open dashboard
railway open

# Deploy
railway up
```

---

## ⚠️ IMPORTANT - Înainte de a face switch complet:

1. ✅ **Backup-urile sunt salvate** (recipy_backup_*.dump și *.sql)
2. ⏸️ **Nu șterge database-ul local** până nu verifici că totul merge pe Railway
3. ⏸️ **Păstrează .env local** cu conexiunea la database local
4. ✅ **Test pe Railway** înainte de a face switch complet

---

## 📝 Next Steps După Migrare:

1. **Test complet în production**
2. **Migrare files la Cloudflare R2** (când ești gata)
3. **Update Stripe webhooks** cu URL production
4. **Update Google OAuth** redirect URIs
5. **Add custom domain** (opțional)

---

Succes! Urmează pașii și spune-mi dacă întâmpini probleme! 🚀




