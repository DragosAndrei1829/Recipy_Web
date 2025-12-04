# Fly.io Deployment Guide - Recipy Web App

## 🚀 De ce Fly.io?

- ✅ **Gratuit pentru start**: 3 shared-cpu VMs, 256MB RAM, 3GB storage
- ✅ **Mai rapid** decât Railway (edge computing)
- ✅ **PostgreSQL inclus** (free tier: 256MB RAM, 1GB storage)
- ✅ **Redis inclus** (evcc.fly.dev - free tier)
- ✅ **Certificat SSL automat**
- ✅ **Global deployment** (multiple regions)

---

## 📋 Pasul 1: Instalează Fly CLI

### **macOS** (cu Homebrew):
```bash
brew install flyctl
```

### **Sau direct:**
```bash
curl -L https://fly.io/install.sh | sh
```

### **Verifică instalarea:**
```bash
flyctl version
```

---

## 📋 Pasul 2: Autentificare Fly.io

```bash
# Login (deschide browser pentru autentificare)
flyctl auth login

# Sau signup dacă nu ai cont
flyctl auth signup
```

---

## 📋 Pasul 3: Inițializează App-ul

În directorul proiectului:

```bash
cd "/Users/dragosandrei/Documents/Ruby on Rails/Recipy"

# Inițializează Fly.io app
flyctl launch --no-deploy
```

**Întrebări interactive**:
1. **App name**: `recipy-web` (sau ce nume vrei, trebuie să fie unic global)
2. **Region**: `ams` (Amsterdam) sau `fra` (Frankfurt) - cel mai apropiat de România
3. **PostgreSQL**: ✅ **YES** → Selectează "Development" (256MB RAM, gratuit)
4. **Redis**: ✅ **YES** → Selectează "Eviction" (free tier)
5. **Deploy now**: ❌ **NO** (facem configurări mai întâi)

Acest command creează:
- `fly.toml` (configurare Fly.io)
- `.dockerignore` (ce să excludă din Docker image)

---

## 📋 Pasul 4: Configurează Secrets (Environment Variables)

```bash
# Rails Master Key (OBLIGATORIU)
flyctl secrets set RAILS_MASTER_KEY=$(cat config/master.key)

# Cloudflare R2 pentru imagini
flyctl secrets set \
  AWS_ACCESS_KEY_ID=your_r2_access_key \
  AWS_SECRET_ACCESS_KEY=your_r2_secret_key \
  AWS_REGION=auto \
  AWS_S3_BUCKET=recipy-production \
  AWS_ENDPOINT=https://your-account-id.r2.cloudflarestorage.com \
  ACTIVE_STORAGE_SERVICE=amazon

# Stripe (pentru subscripții)
flyctl secrets set \
  STRIPE_PUBLISHABLE_KEY=pk_test_... \
  STRIPE_SECRET_KEY=sk_test_... \
  STRIPE_WEBHOOK_SECRET=whsec_... \
  STRIPE_PRICE_ID_AI_CHAT=price_...

# Google OAuth
flyctl secrets set \
  GOOGLE_CLIENT_ID=your_google_client_id \
  GOOGLE_CLIENT_SECRET=your_google_client_secret

# Apple OAuth (dacă folosești)
flyctl secrets set \
  APPLE_CLIENT_ID=your_apple_client_id \
  APPLE_TEAM_ID=your_apple_team_id \
  APPLE_KEY_ID=your_apple_key_id \
  APPLE_PRIVATE_KEY="$(cat path/to/apple_key.p8)"

# OpenAI (pentru AI chat)
flyctl secrets set OPENAI_API_KEY=sk-...

# Vezi toate secretele
flyctl secrets list
```

---

## 📋 Pasul 5: Configurează `fly.toml`

Fly.io generează `fly.toml` automat, dar trebuie ajustat:

```toml
# fly.toml
app = "recipy-web"  # Numele tău unic
primary_region = "ams"  # Amsterdam (sau "fra" pentru Frankfurt)

# Dockerfile to use
[build]

[deploy]
  release_command = "bin/rails db:prepare"  # Rulează migrații automat

[env]
  PORT = "8080"
  RAILS_LOG_TO_STDOUT = "true"
  RAILS_SERVE_STATIC_FILES = "true"

# HTTP service
[[services]]
  internal_port = 8080
  protocol = "tcp"
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 0

  [[services.ports]]
    port = 80
    handlers = ["http"]
    force_https = true

  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]

  # Health checks
  [services.http_checks]
    interval = "10s"
    timeout = "2s"
    grace_period = "5s"
    method = "GET"
    path = "/up"

# Resources
[compute]
  cpu_kind = "shared"
  cpus = 1
  memory = "256mb"

# Persistent volumes (pentru tmp/cache)
[[mounts]]
  source = "recipy_data"
  destination = "/rails/storage"
  initial_size = "1gb"
```

---

## 📋 Pasul 6: Creează Volume pentru Storage

```bash
# Creează volume persistent pentru tmp/cache/storage
flyctl volumes create recipy_data \
  --region ams \
  --size 1
```

---

## 📋 Pasul 7: Configurează PostgreSQL

```bash
# Vezi detalii database
flyctl postgres list

# Connect la PostgreSQL (pentru debug)
flyctl postgres connect -a recipy-web-db

# Obține connection string
flyctl postgres db list -a recipy-web-db

# Connection string e deja setat automat ca DATABASE_URL
# Verifică:
flyctl secrets list | grep DATABASE
```

---

## 📋 Pasul 8: Configurează Redis

Fly.io creează automat un Redis instance. Connection string e setat automat ca `REDIS_URL`.

```bash
# Verifică Redis
flyctl redis list

# Vezi detalii Redis
flyctl redis status recipy-web-redis

# Connection string (deja setat automat)
flyctl secrets list | grep REDIS
```

---

## 📋 Pasul 9: Deploy! 🚀

```bash
# Deploy app-ul
flyctl deploy

# Monitorizează deployment-ul
flyctl logs

# Verifică status
flyctl status

# Deschide app-ul în browser
flyctl open
```

**URL-ul tău**: `https://recipy-web.fly.dev` (sau numele ales de tine)

---

## 📋 Pasul 10: Rulează Migrații (dacă e nevoie)

```bash
# Rulează migrații manual
flyctl ssh console
> cd /rails
> bin/rails db:migrate
> exit

# Sau direct:
flyctl ssh console -C "bin/rails db:migrate"
```

---

## 📋 Pasul 11: Import Date din Local → Fly.io PostgreSQL

### **Opțiunea 1: Prin SSH Tunnel**

```bash
# 1. Creează backup local
pg_dump backend_development > recipy_backup.sql

# 2. Deschide SSH tunnel către Fly.io PostgreSQL
flyctl proxy 5432:5432 -a recipy-web-db

# 3. În alt terminal, restaurează backup
psql "postgres://postgres:password@localhost:5432/recipy_web_production" < recipy_backup.sql
```

### **Opțiunea 2: Prin Console**

```bash
# 1. Upload backup pe Fly.io
flyctl ssh console
> cat > /tmp/backup.sql
# (paste conținutul backup-ului aici și Ctrl+D)

# 2. Restaurează
> cd /rails
> bin/rails db:drop db:create
> psql $DATABASE_URL < /tmp/backup.sql
> bin/rails db:migrate
```

---

## 🔧 Comenzi Utile

### **Logs**
```bash
# Vezi logs live
flyctl logs

# Ultimele 200 linii
flyctl logs --tail 200

# Logs de la un serviciu specific
flyctl logs --app recipy-web
```

### **Console/SSH**
```bash
# Deschide Rails console
flyctl ssh console -C "bin/rails console"

# SSH direct
flyctl ssh console

# Rulează comenzi
flyctl ssh console -C "bin/rake db:seed"
```

### **Scaling**
```bash
# Vezi resurse
flyctl scale show

# Mărește RAM (dacă depășești free tier)
flyctl scale memory 512

# Mărește CPU
flyctl scale count 2

# Resetează la free tier
flyctl scale memory 256
flyctl scale count 1
```

### **Redeploy**
```bash
# Redeploy rapid (fără rebuild)
flyctl deploy --strategy immediate

# Rebuild complet
flyctl deploy --no-cache
```

### **Destroy/Restart**
```bash
# Restart app
flyctl apps restart

# Destroy app (ATENȚIE: șterge tot!)
flyctl apps destroy recipy-web
```

---

## 🌍 Custom Domain

### **Adaugă domeniul tău**

```bash
# Adaugă domeniu
flyctl certs add recipy.ro

# Verifică status certificat
flyctl certs show recipy.ro

# Configurează DNS (în Cloudflare/GoDaddy/etc):
# A record:    recipy.ro → <IP Fly.io>
# AAAA record: recipy.ro → <IPv6 Fly.io>
# CNAME:       www.recipy.ro → recipy-web.fly.dev
```

**Obține IP-urile Fly.io:**
```bash
flyctl ips list
```

---

## 💰 Costuri Fly.io

### **Free Tier** (suficient pentru start):
- 3 shared-cpu VMs (256MB RAM each)
- 3GB persistent volumes
- 160GB outbound transfer
- PostgreSQL: 256MB RAM, 1GB storage
- Redis: Eviction cache (256MB)

### **Dacă depășești**:
- **Compute**: ~$2/month per 256MB VM
- **PostgreSQL**: $3/month pentru 512MB
- **Volumes**: $0.15/GB/month
- **Bandwidth**: $0.02/GB după 160GB

**Pentru o aplicație mică-medie, vei rămâne în free tier.**

---

## 🔒 Securitate

### **Firewall (restrict SSH)**
```bash
# Permite SSH doar din IP-ul tău
flyctl ips allocate-v4 --region ams
# Apoi configurează firewall în Fly.io Dashboard
```

### **Backup Database**
```bash
# Backup automat PostgreSQL (daily snapshots incluse în free tier)
flyctl postgres db backup -a recipy-web-db

# Restore din snapshot
flyctl postgres db restore -a recipy-web-db
```

---

## 🐛 Troubleshooting

### **Eroare: "Could not find database"**
```bash
flyctl ssh console -C "bin/rails db:create db:migrate"
```

### **Eroare: "ActiveRecord::ConnectionNotEstablished"**
```bash
# Verifică DATABASE_URL
flyctl secrets list | grep DATABASE

# Testează conexiune
flyctl ssh console -C "bin/rails db:version"
```

### **Imagini nu apar (Cloudflare R2)**
```bash
# Verifică R2 credentials
flyctl secrets list | grep AWS

# Testează Active Storage
flyctl ssh console -C "bin/rails runner 'puts ActiveStorage::Blob.service.name'"
```

### **App nu pornește**
```bash
# Vezi logs detaliate
flyctl logs --tail 500

# Verifică health check
flyctl checks list

# SSH și debug
flyctl ssh console
> cd /rails
> bin/rails console
```

---

## ✅ Checklist Final

- [ ] Fly CLI instalat (`flyctl version`)
- [ ] Autentificat (`flyctl auth login`)
- [ ] App inițializat (`flyctl launch --no-deploy`)
- [ ] PostgreSQL creat (Development tier)
- [ ] Redis creat (Eviction tier)
- [ ] Secrets configurate (RAILS_MASTER_KEY, AWS, Stripe, etc.)
- [ ] `fly.toml` ajustat (CPU, RAM, region)
- [ ] Volume creat (`recipy_data`)
- [ ] Deploy realizat (`flyctl deploy`)
- [ ] Migrații rulate (`db:prepare` în release_command)
- [ ] Date importate (opțional, din local)
- [ ] Test în browser (`flyctl open`)
- [ ] Logs verificate (`flyctl logs`)

---

## 🔄 Workflow: Update & Deploy

După ce ai făcut modificări în cod:

```bash
# 1. Commit changes
git add .
git commit -m "Update feature X"
git push

# 2. Deploy la Fly.io
flyctl deploy

# 3. Monitorizează
flyctl logs

# 4. Test
flyctl open
```

**Fly.io face rebuild automat când rulezi `flyctl deploy`!**

---

## 🆚 Fly.io vs Railway

| Feature | Fly.io | Railway |
|---------|--------|---------|
| **Free Tier** | 3 VMs, 256MB RAM | $5 credit/month |
| **Database** | PostgreSQL inclus | PostgreSQL inclus |
| **Redis** | Inclus (free) | Inclus (paid) |
| **Deployment** | CLI (`flyctl deploy`) | Git push auto |
| **Custom Domain** | Gratuit + SSL | Gratuit + SSL |
| **Regions** | 30+ global | 5 regions |
| **Speed** | 🚀 Foarte rapid | Rapid |
| **Complexitate** | Medie | Simplă |

**Recomandare**: 
- **Fly.io** pentru **production** (mai scalabil, mai rapid)
- **Railway** pentru **development** (mai simplu, git push auto)

---

**Spune-mi când ești gata să faci primul deploy pe Fly.io! Pot să te ajut la fiecare pas.** 🚀

