# Cache Setup pentru Scalabilitate

## Situația Actuală ✅

Am migrat istoricul AI chat de la **cookie sessions** (limită 4KB) la **Rails.cache**:

- ✅ **Development**: Folosește `MemoryStore` (suficient pentru testing)
- ✅ **Istoric per utilizator**: `ai_chat_#{user_id}`
- ✅ **Expirare automată**: 2 ore
- ✅ **Limită mesaje**: 20 (față de 8 în cookies)

## Pentru Producție (Opțional) 🚀

Când vei avea mulți utilizatori, migrează la **Redis**:

### 1. Instalează Redis gem

```ruby
# Gemfile
gem 'redis'
gem 'hiredis'
```

```bash
bundle install
```

### 2. Configurează Redis pentru cache

```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, {
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"),
  expires_in: 2.hours,
  namespace: "recipy_cache"
}
```

### 3. Instalează Redis pe server

**macOS (pentru testing local):**
```bash
brew install redis
brew services start redis
```

**Ubuntu/Debian (producție):**
```bash
sudo apt-get install redis-server
sudo systemctl enable redis-server
sudo systemctl start redis-server
```

### 4. Verifică Redis funcționează

```bash
redis-cli ping
# Ar trebui să răspundă: PONG
```

## Beneficii Redis vs MemoryStore

| Feature | MemoryStore | Redis |
|---------|------------|-------|
| Persistență | ❌ Se pierde la restart | ✅ Date persistente |
| Multi-server | ❌ Un singur server | ✅ Shared între servere |
| Scalabilitate | ❌ Limitată de RAM | ✅ Până la 512MB/key |
| Performanță | ⚡ Foarte rapid | ⚡ Foarte rapid |
| Cost | 🆓 Gratis | 💰 Mic (managed Redis ~$10-30/lună) |

## Când să migrezi la Redis?

- 📈 Când ai **>100 utilizatori activi simultan**
- 🔄 Când ai **multiple servere/instanțe**
- 💾 Când vrei **persistență** la restart
- ⏱️ Când ai nevoie de **rate limiting** avansat

## Alternative (pentru buget mic)

### 1. **Railway Redis** (cel mai ieftin)
- Free tier: 100MB, suficient pentru 1000+ utilizatori
- $5/lună pentru 256MB
- https://railway.app

### 2. **Render Redis** 
- Free tier: 25MB (suficient pentru ~250 utilizatori activi)
- $7/lună pentru 256MB
- https://render.com

### 3. **Redis Cloud** (Upstash)
- Free tier: 10K comenzi/zi
- Pay-as-you-go după
- https://upstash.com

## Testing Local

Pentru a testa cu Redis local:

```bash
# Pornește Redis
brew services start redis  # macOS
sudo systemctl start redis-server  # Linux

# Actualizează development.rb
# config/environments/development.rb
config.cache_store = :redis_cache_store, { url: "redis://localhost:6379/1" }

# Restart Rails
rails restart
```

## Monitorizare Cache

```ruby
# Rails console
Rails.cache.stats  # Vezi statistici
Rails.cache.read("ai_chat_1")  # Vezi istoricul unui user
Rails.cache.delete("ai_chat_1")  # Șterge istoricul
Rails.cache.clear  # Șterge tot cache-ul
```

## Notă Importantă ⚠️

**Nu este urgent să migrezi la Redis acum!** 
- MemoryStore este perfect pentru development și teste
- Migrează la Redis doar când deplii în producție cu trafic real
- Tranziția este foarte simplă (doar configurare, fără cod nou)

