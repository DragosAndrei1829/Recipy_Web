# Cloudflare R2 - Quick Setup Guide

## 🚨 Problema Actuală

Railway încearcă să acceseze imagini din AWS S3, dar primești erori:
```
Error retrieving instance profile credentials: Aws::InstanceProfileCredentials::Non200Response
ArgumentError (missing required option :name)
```

**Cauza**: `config/storage.yml` este configurat pentru AWS S3, dar nu ai credențiale AWS.

---

## ✅ Soluție: Cloudflare R2 (S3-Compatible, GRATUIT)

### **Pasul 1: Creează Bucket R2**

1. Intră în **Cloudflare Dashboard** → **R2 Object Storage**
2. Click **"Create bucket"**
3. Nume bucket: `recipy-production` (sau orice nume vrei)
4. Region: **Automatic** (cel mai apropiat)
5. Click **"Create bucket"**

---

### **Pasul 2: Generează API Token**

1. În R2 Dashboard → **"Manage R2 API Tokens"**
2. Click **"Create API token"**
3. Setări:
   - **Token name**: `recipy-production-token`
   - **Permissions**: ✅ **Object Read & Write**
   - **TTL**: Leave blank (no expiration)
   - **Specific buckets**: ✅ Select `recipy-production`
4. Click **"Create API Token"**

5. **Salvează aceste valori** (nu le mai poți vedea după):
   ```
   Access Key ID: <COPIAZĂ AICI>
   Secret Access Key: <COPIAZĂ AICI>
   ```

---

### **Pasul 3: Obține Endpoint URL**

1. În R2 Dashboard → Click pe bucket-ul tău (`recipy-production`)
2. Tab **"Settings"**
3. Găsește **"S3 API"** section
4. Copiază **"Endpoint for S3 clients"**:
   ```
   https://<account-id>.r2.cloudflarestorage.com
   ```

---

### **Pasul 4: Configurează Railway Environment Variables**

În **Railway Dashboard** → **Recipy_Web** → **Variables**:

```bash
# Cloudflare R2 Configuration
AWS_ACCESS_KEY_ID=<Access Key ID from Step 2>
AWS_SECRET_ACCESS_KEY=<Secret Access Key from Step 2>
AWS_REGION=auto
AWS_S3_BUCKET=recipy-production
AWS_ENDPOINT=https://<account-id>.r2.cloudflarestorage.com

# Active Storage
ACTIVE_STORAGE_SERVICE=amazon
```

**Important**: 
- `AWS_REGION=auto` (R2 folosește "auto" pentru region)
- `AWS_ENDPOINT` trebuie să fie endpoint-ul tău R2 (nu AWS)

---

### **Pasul 5: Redeploy Railway**

După ce ai adăugat variabilele:

1. În Railway → **Recipy_Web** → Click **"Redeploy"**
2. Sau push un commit nou:
   ```bash
   git commit --allow-empty -m "Trigger Railway redeploy with R2 config"
   git push
   ```

---

## 📦 Migrare Imagini din Local → R2

### **Opțiunea 1: Upload Manual (Simplu)**

1. În Cloudflare R2 Dashboard → Click pe bucket
2. Click **"Upload"**
3. Drag & drop fișierele din `storage/` local

### **Opțiunea 2: AWS CLI (Automat)**

```bash
# 1. Instalează AWS CLI
brew install awscli

# 2. Configurează pentru R2
aws configure --profile r2
# AWS Access Key ID: <R2 Access Key>
# AWS Secret Access Key: <R2 Secret Key>
# Default region name: auto
# Default output format: json

# 3. Sync local storage → R2
aws s3 sync storage/ s3://recipy-production/storage/ \
  --endpoint-url https://<account-id>.r2.cloudflarestorage.com \
  --profile r2
```

---

## 🧪 Testare

După redeploy, verifică:

1. **Imagini noi**: Upload o poză de profil → Ar trebui să apară
2. **Logs Railway**: Nu mai vezi erori `ArgumentError` sau `Aws::InstanceProfileCredentials`
3. **R2 Dashboard**: Vezi fișierele în bucket

---

## 💰 Costuri R2

- **Gratuit**:
  - 10 GB storage
  - 1 million Class A operations/month (uploads)
  - 10 million Class B operations/month (downloads)
- **După limită**:
  - $0.015/GB storage
  - $4.50/million Class A ops
  - $0.36/million Class B ops

**Pentru un site mic-mediu, vei rămâne în tier-ul gratuit.**

---

## 🔧 Troubleshooting

### **Eroare: "The bucket you are attempting to access must be addressed using the specified endpoint"**

**Fix**: Verifică că `AWS_ENDPOINT` este corect în Railway Variables.

### **Eroare: "SignatureDoesNotMatch"**

**Fix**: 
1. Regenerează API Token în R2
2. Actualizează `AWS_ACCESS_KEY_ID` și `AWS_SECRET_ACCESS_KEY` în Railway
3. Redeploy

### **Imagini vechi nu apar**

**Fix**: Migrează fișierele din local/S3 → R2 (vezi "Migrare Imagini" mai sus).

---

## ✅ Checklist Final

- [ ] Bucket R2 creat (`recipy-production`)
- [ ] API Token generat (Access Key + Secret Key)
- [ ] Endpoint URL copiat
- [ ] Railway Variables configurate (6 variabile)
- [ ] Railway redeploy-at
- [ ] Imagini migrate (opțional, dacă ai deja conținut)
- [ ] Test upload imagine → Success

---

**După ce finalizezi, spune-mi și verific logs-urile Railway pentru erori!** 🚀

