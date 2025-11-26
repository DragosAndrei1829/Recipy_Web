# Active Storage Configuration

## Setup pentru AWS S3

Pentru a folosi S3 în loc de storage local și a nu pierde fișierele la fiecare commit:

### 1. Creează un bucket S3 pe AWS

1. Mergi la [AWS Console](https://console.aws.amazon.com/s3/)
2. Creează un bucket nou (ex: `recipy-development`, `recipy-production`)
3. Notează numele bucket-ului și regiunea

### 2. Creează un IAM user cu permisiuni S3

1. Mergi la [IAM Console](https://console.aws.amazon.com/iam/)
2. Creează un user nou
3. Atașează policy-ul `AmazonS3FullAccess` sau un policy custom cu permisiuni doar pentru bucket-ul tău
4. Creează Access Keys (Access Key ID și Secret Access Key)

### 3. Configurează variabilele de mediu

Adaugă în `.env` (sau în variabilele de mediu ale serverului):

```bash
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key
AWS_REGION=us-east-1
AWS_S3_BUCKET=recipy-development
```

### 4. Activează S3 în aplicație

Pentru **development**, editează `config/environments/development.rb`:
```ruby
config.active_storage.service = :amazon
```

Pentru **production**, editează `config/environments/production.rb`:
```ruby
config.active_storage.service = :amazon
```

### 5. Instalează gem-ul

Rulează:
```bash
bundle install
```

### 6. Migrează fișierele existente (opțional)

Dacă ai fișiere în storage local și vrei să le muți pe S3:
```bash
rails active_storage:update
```

## Alternativă: Backup local

Dacă nu vrei să folosești S3, poți face backup-uri manuale:

```bash
# Backup
tar -czf storage_backup_$(date +%Y%m%d).tar.gz backend/storage/

# Restore
tar -xzf storage_backup_YYYYMMDD.tar.gz -C backend/
```

## Notă

- Fișierele vor fi salvate pe S3 și nu se vor pierde la commit-uri
- Costurile S3 sunt foarte mici pentru development (primi 5GB sunt gratuite)
- Pentru producție, S3 este recomandat pentru scalabilitate și performanță



