# 🔄 Import Database în Railway - Ghid Complet

## ⚠️ IMPORTANT: Railway folosește hostname-uri interne!

`postgres.railway.internal` **NU** este accesibil din local!  
Trebuie să rulăm comenzile **din Railway environment** sau să folosim **DATABASE_PUBLIC_URL**.

---

## ✅ Backup-uri Create:
- `recipy_backup_20251203_184614.dump` (164KB)
- `recipy_backup_20251203_184615.sql` (149KB)

---

## METODA 1: Deploy App → Run Migrations → Import (Recomandată)

### STEP 1: Add Environment Variables în Railway Dashboard

1. **Deschide Railway Dashboard:**
   ```
   https://railway.app/project/<your-project-id>
   ```

2. **Click pe Rails service (nu Postgres!)**

3. **Tab "Variables" → Add toate acestea:**

```bash
# ═══ RAILS CORE ═══
RAILS_MASTER_KEY=<din config/master.key - rulează: cat config/master.key>
RAILS_ENV=production
RACK_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true

# ═══ STORAGE (deocamdată local) ═══
ACTIVE_STORAGE_SERVICE=local

# ═══ STRIPE (din .env local) ═══
STRIPE_PUBLISHABLE_KEY=<din .env>
STRIPE_SECRET_KEY=<din .env>
STRIPE_PRICE_ID_AI_CHAT=price_1SZWUZ2NDBfcf2CayD1Q9Sau

# ═══ GOOGLE OAUTH (din .env local) ═══
GOOGLE_OAUTH_CLIENT_ID=<din .env>
GOOGLE_OAUTH_CLIENT_SECRET=<din .env>
```

**⚠️ DATABASE_URL și REDIS_URL sunt deja setate automat de Railway!**

### STEP 2: Commit & Push (Trigger Deploy)

```bash
cd "/Users/dragosandrei/Documents/Ruby on Rails/Recipy"

# Commit changes
git add .
git commit -m "Configure for Railway deployment with Redis"
git push origin main
```

### STEP 3: Wait for Deploy & Watch Logs

```bash
# Watch logs
railway logs

# Sau în browser:
# Railway dashboard → Service (Rails) → Deployments → Click pe build → View Logs
```

**Așteaptă până vezi:**
```
✓ Build successful
✓ Deployment successful
```

### STEP 4: Run Migrations în Railway

```bash
# Acum migrations vor merge (rulează în Railway environment)
railway run --service <rails-service-name> rails db:migrate

# Sau dacă ai un singur service Rails:
railway run rails db:migrate

# Verifică
railway run rails db:migrate:status
```

### STEP 5: Import Backup

#### **Opțiunea A: Upload backup la Railway și import**

```bash
# 1. Copy backup la Railway
railway run --service <rails-service-name> bash -c 'cat > /tmp/backup.dump' < recipy_backup_20251203_184614.dump

# 2. Import
railway run --service <rails-service-name> bash -c 'pg_restore --verbose --clean --no-acl --no-owner -d $DATABASE_URL /tmp/backup.dump'
```

#### **Opțiunea B: Import direct prin pipe**

```bash
# Import SQL prin pipe
railway run bash -c 'psql $DATABASE_URL' < recipy_backup_20251203_184615.sql
```

### STEP 6: Verificare

```bash
railway run rails runner "
  puts '═══════════════════════════════════════════'
  puts '✅ RAILWAY DATABASE - VERIFICARE'
  puts '═══════════════════════════════════════════'
  puts '👥 Users: ' + User.count.to_s
  puts '🍽️  Recipes: ' + Recipe.count.to_s
  puts '💬 Comments: ' + Comment.count.to_s
  puts '❤️  Likes: ' + Like.count.to_s
  puts '📁 Attachments: ' + ActiveStorage::Attachment.count.to_s
  puts '═══════════════════════════════════════════'
"
```

---

## METODA 2: Folosește DATABASE_PUBLIC_URL (mai simplu)

### STEP 1: Obține Public URL

```bash
# În Railway dashboard
→ Click pe "Postgres" service
→ Tab "Connect"
→ Scroll jos la "Public Networking"
→ Click "Enable Public Networking"
→ Copiază "Public URL"

Format: postgresql://postgres:password@public-host.railway.app:5432/railway
```

### STEP 2: Import Direct cu Public URL

```bash
# Set variabila
export RAILWAY_PUBLIC_DB="postgresql://postgres:KpSJwdYhVbOkxObPIBoYLOBEJAAJycQx@<public-host>.railway.app:5432/railway"

# Import
pg_restore --verbose --clean --no-acl --no-owner \
  -d "$RAILWAY_PUBLIC_DB" \
  recipy_backup_20251203_184614.dump

# Sau cu SQL
psql "$RAILWAY_PUBLIC_DB" < recipy_backup_20251203_184615.sql
```

### STEP 3: Verificare

```bash
# Direct cu psql
psql "$RAILWAY_PUBLIC_DB" -c "SELECT COUNT(*) FROM users;"
psql "$RAILWAY_PUBLIC_DB" -c "SELECT COUNT(*) FROM recipes;"
```

---

## METODA 3: Railway Shell (cel mai direct)

### STEP 1: Deschide Railway Shell

```bash
# Deschide shell în container-ul Rails
railway shell

# Acum ești în container-ul Railway!
```

### STEP 2: Upload Backup

```bash
# În alt terminal (local), upload backup
railway run bash -c 'cat > /tmp/backup.sql' < recipy_backup_20251203_184615.sql
```

### STEP 3: Import în Shell

```bash
# În Railway shell
psql $DATABASE_URL < /tmp/backup.sql

# Sau
pg_restore -d $DATABASE_URL /tmp/backup.dump
```

---

## 🎯 RECOMANDAREA MEA (cel mai simplu):

### **Folosește Railway Dashboard pentru Public URL:**

1. **Enable Public Networking:**
   ```
   Railway → Postgres service → Connect → Enable Public Networking
   ```

2. **Copiază Public URL** (va arăta ca: `postgresql://postgres:pass@monorail.proxy.rlwy.net:12345/railway`)

3. **Import direct:**
   ```bash
   pg_restore --verbose --clean --no-acl --no-owner \
     -d "postgresql://postgres:KpSJwdYhVbOkxObPIBoYLOBEJAAJycQx@<public-host>:port/railway" \
     recipy_backup_20251203_184614.dump
   ```

4. **Disable Public Networking** (după import, pentru securitate)

---

## 🔒 Security Note

**După ce termini import-ul:**
- ☑️ **Disable "Public Networking"** în Railway Postgres settings
- ☑️ Database-ul va fi accesibil doar din Railway services (mai sigur)

---

## 📊 Verificare Finală

După import, verifică în Railway:

```bash
railway run rails runner "
  puts 'Users: ' + User.count.to_s
  puts 'Recipes: ' + Recipe.count.to_s
  puts 'First user: ' + User.first&.username.to_s
"
```

---

## 🆘 Dacă nimic nu merge:

### **Plan B: Seed data manual**

```bash
# 1. Deploy app pe Railway
git push origin main

# 2. Create admin user
railway run rails runner "
  User.create!(
    username: 'admin',
    email: 'admin@recipy.ro',
    password: 'TempPassword123!',
    admin: true
  )
"

# 3. Login în production și recreează datele manual
# (nu ideal, dar funcționează pentru testing)
```

---

Spune-mi ce metodă preferi și continuăm! 🚀

