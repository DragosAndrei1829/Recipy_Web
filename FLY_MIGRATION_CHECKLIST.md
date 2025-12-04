# Fly.io Migration Checklist - Recipy

## ✅ Status Migrare

- [x] Fly CLI instalat
- [x] Autentificat (andrei247dml@gmail.com)
- [ ] **Cont verificat** (adaugă card la https://fly.io/high-risk-unlock)
- [ ] App creat în Fly.io
- [ ] PostgreSQL creat
- [ ] Redis creat (sau Upstash)
- [ ] Database Railway backup făcut
- [ ] Database importat în Fly.io
- [ ] Secrets configurate (RAILS_MASTER_KEY, AWS R2, Stripe, etc.)
- [ ] Deploy realizat
- [ ] Test site funcțional
- [ ] Railway șters

---

## 📋 Comenzi care vor fi rulate (automat):

### **1. Backup Railway Database**
```bash
# Backup PostgreSQL din Railway
railway run pg_dump $DATABASE_URL > /tmp/recipy_railway_backup.sql

# Verificare backup
ls -lh /tmp/recipy_railway_backup.sql
```

### **2. Launch Fly.io App**
```bash
cd "/Users/dragosandrei/Documents/Ruby on Rails/Recipy"

# Inițializare cu PostgreSQL + Redis
flyctl launch \
  --name recipy-web \
  --region ams \
  --ha=false \
  --now
```

### **3. Configurare Secrets**
```bash
# Rails
flyctl secrets set RAILS_MASTER_KEY=$(cat config/master.key)

# Cloudflare R2
flyctl secrets set \
  AWS_ACCESS_KEY_ID=xxx \
  AWS_SECRET_ACCESS_KEY=xxx \
  AWS_REGION=auto \
  AWS_S3_BUCKET=recipy-production \
  AWS_ENDPOINT=https://xxx.r2.cloudflarestorage.com \
  ACTIVE_STORAGE_SERVICE=amazon

# Stripe
flyctl secrets set \
  STRIPE_PUBLISHABLE_KEY=pk_test_xxx \
  STRIPE_SECRET_KEY=sk_test_xxx \
  STRIPE_WEBHOOK_SECRET=whsec_xxx \
  STRIPE_PRICE_ID_AI_CHAT=price_xxx

# Google OAuth
flyctl secrets set \
  GOOGLE_CLIENT_ID=xxx \
  GOOGLE_CLIENT_SECRET=xxx

# OpenAI
flyctl secrets set OPENAI_API_KEY=sk-xxx
```

### **4. Import Database**
```bash
# Creează tunnel la Fly.io PostgreSQL
flyctl proxy 5432:5432 -a recipy-web-db &

# Import backup
psql "postgres://postgres:password@localhost:5432/recipy_web" < /tmp/recipy_railway_backup.sql

# Kill tunnel
pkill -f "flyctl proxy"
```

### **5. Deploy**
```bash
flyctl deploy
```

### **6. Test**
```bash
# Deschide în browser
flyctl open

# Vezi logs
flyctl logs
```

---

## 🗑️ Ștergere Railway (după ce Fly.io merge perfect)

### **Verificare înainte de ștergere:**
```bash
# 1. Test site Fly.io
open https://recipy-web.fly.dev

# 2. Verifică că database-ul are date
flyctl ssh console -C "bin/rails runner 'puts User.count'"
flyctl ssh console -C "bin/rails runner 'puts Recipe.count'"

# 3. Verifică că imagini apar (din R2)
# Browse site-ul și vezi dacă pozele apar
```

### **Ștergere Railway:**

#### **Opțiunea 1: Prin Dashboard** (recomandat)
1. Intră în **Railway Dashboard**: https://railway.app
2. Selectează project-ul **"beneficial-embrace"** (sau cum se numește)
3. Click pe **fiecare serviciu** (Recipy_Web, Rails, Postgres, Redis)
4. Settings → **"Delete Service"**
5. După ce ștergi toate serviciile → Project Settings → **"Delete Project"**

#### **Opțiunea 2: Prin CLI**
```bash
# 1. Listează toate project-urile
railway list

# 2. Link la project
railway link

# 3. Șterge serviciile
railway service delete Recipy_Web
railway service delete Rails
railway service delete Postgres
railway service delete Redis

# 4. Șterge project-ul
railway delete
```

### **Verificare finală:**
```bash
# Asigură-te că nu mai ai resurse active în Railway
railway status  # Ar trebui să dea eroare sau "No project linked"
```

---

## 💰 Comparație Costuri (după migrare)

### **Înainte (Railway):**
- **Cost lunar**: $5-10/month (după $5 credit gratuit)
- **Resurse**: Rails app + PostgreSQL + Redis
- **Region**: US-East (latency ~150ms din România)

### **După (Fly.io):**
- **Cost lunar**: $0/month (free tier)
- **Resurse**: Rails app + PostgreSQL + Redis
- **Region**: Amsterdam (latency ~30ms din România)
- **Bonus**: 160GB bandwidth gratuit

### **Economisire anuală: $60-120/an** 💰

---

## 🚨 Backup Final (important!)

Înainte de a șterge Railway, salvează un backup final:

```bash
# 1. Database backup
railway run pg_dump $DATABASE_URL > ~/Desktop/recipy_final_backup_$(date +%Y%m%d).sql

# 2. Verifică backup-ul
ls -lh ~/Desktop/recipy_final_backup_*.sql

# 3. (Opțional) Upload backup în Cloudflare R2 sau Google Drive
```

Păstrează acest backup cel puțin 30 de zile după ștergerea Railway!

---

## ✅ Timeline Estimat

1. **Tu**: Verificare cont Fly.io (2-3 min) ⏱️
2. **Eu (automat)**: 
   - Backup Railway DB (1 min)
   - Launch Fly.io app (2 min)
   - Configure secrets (1 min)
   - Import database (3 min)
   - Deploy (5 min)
   - **Total: ~12 minute**
3. **Test împreună**: Site funcțional (2 min)
4. **Tu**: Șterge Railway (1 min)

**Total timp: ~20 minute** 🚀

---

## 📞 Când ceva nu merge

### **Database connection error:**
```bash
flyctl secrets list | grep DATABASE
flyctl ssh console -C "bin/rails db:version"
```

### **Imagini nu apar:**
```bash
flyctl secrets list | grep AWS
flyctl ssh console -C "bin/rails runner 'puts ActiveStorage::Blob.service.name'"
```

### **App nu pornește:**
```bash
flyctl logs --tail 100
flyctl status
```

---

## 🎉 După migrare

Site-ul tău va fi disponibil la:
- 🌐 **Fly.io**: `https://recipy-web.fly.dev`
- 🚀 **Speed**: 30ms latency din România (vs 150ms Railway)
- 💰 **Cost**: $0/lună (vs $5-10/lună Railway)
- 📊 **Free tier**: 256MB RAM, 1GB PostgreSQL, 160GB bandwidth

**Vrei custom domain?** După ce merge perfect, adăugăm:
```bash
flyctl certs add recipy.ro
# Apoi configurezi DNS: A record → IP Fly.io
```

---

**Spune-mi când ai terminat verificarea contului și pornesc deployment-ul automat!** ⚡

