# 🚨 ACȚIUNE NECESARĂ - Credențiale Railway

## Trebuie să-mi dai credențialele Railway PostgreSQL:

### **Opțiunea 1: Railway Dashboard** (Recomandat)

1. Intră în **Railway Dashboard**: https://railway.app
2. Selectează project-ul tău (beneficial-embrace)
3. Click pe serviciul **"Postgres"**
4. Tab **"Variables"** sau **"Connect"**
5. Copiază URL-ul complet: `postgresql://user:pass@host:port/database`

### **Opțiunea 2: Railway CLI**

```bash
railway login
railway link
railway variables | grep DATABASE_URL
```

---

## 📋 Ce am nevoie:

**DATABASE_URL complet de forma:**
```
postgresql://postgres:KpSJwdYhVbOkxObPIBoYLOBEJAAJycQx@postgres.railway.internal:5432/railway
```

**SAU separat:**
- **Host**: `postgres.railway.internal` (sau yamabiko.proxy.rlwy.net:32675)
- **Port**: `5432` (sau 32675)
- **User**: `postgres`
- **Password**: `KpSJwdYhVbOkxObPIBoYLOBEJAAJycQx`
- **Database**: `railway`

---

## 🔄 Ce se întâmplă după:

1. ✅ **Eu fac backup**: Export Railway DB → `recipy_backup.sql`
2. ✅ **Eu import în Fly.io**: Import backup → Fly.io PostgreSQL
3. ✅ **Eu configurez R2**: Setez Cloudflare R2 pentru imagini
4. ✅ **Eu deploy**: Deploy app-ul pe Fly.io
5. ✅ **Testăm împreună**: Verificăm că totul merge
6. ✅ **Tu ștergi Railway**: Ștergi serviciile Railway din dashboard

---

## ⏱️ Timp estimat după ce primesc credențialele:

- Backup: 1-2 min
- Import: 2-3 min  
- Configure: 1 min
- Deploy: 5-7 min
- **Total: ~10-15 minute**

---

**Paste-uiește DATABASE_URL aici când îl ai!** 🚀

