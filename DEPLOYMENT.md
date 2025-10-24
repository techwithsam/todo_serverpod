# Serverpod Deployment Guide

This guide covers deploying your Serverpod Todo app to Railway (recommended) and Heroku.

## Prerequisites

- Docker installed locally
- Railway account or Heroku account
- Git repository pushed to GitHub

---

## Option 1: Railway (Recommended - Easiest)

Railway offers $5/month free credit and simple PostgreSQL/Redis provisioning.

### 1. Prepare your server for deployment

**Create a Dockerfile** in `todo_server/`:

```dockerfile
FROM dart:3.5.4 AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/main.dart -o bin/server

FROM alpine:latest
RUN apk add --no-cache libc6-compat
COPY --from=build /app/bin/server /app/bin/server
COPY --from=build /app/config/ /app/config/
COPY --from=build /app/web/ /app/web/
COPY --from=build /app/migrations/ /app/migrations/

EXPOSE 8080 8081 8082
CMD ["/app/bin/server"]
```

**Update `config/production.yaml`** (set the correct runMode and external host):

```yaml
runMode: production
serverpod:
  logLevel: info
  
apiServer:
  port: 8080
  publicHost: your-app.railway.app  # Replace after deployment
  publicPort: 443
  publicScheme: https

insightsServer:
  port: 8081
  publicHost: your-app.railway.app
  publicPort: 443
  publicScheme: https

webServer:
  port: 8082
  publicHost: your-app.railway.app
  publicPort: 443
  publicScheme: https

database:
  host: $DATABASE_HOST
  port: $DATABASE_PORT
  name: $DATABASE_NAME
  user: $DATABASE_USER
  password: $DATABASE_PASSWORD
  requireSsl: true

redis:
  enabled: true
  host: $REDIS_HOST
  port: $REDIS_PORT
  user: $REDIS_USER
  password: $REDIS_PASSWORD
```

### 2. Deploy to Railway

1. **Go to [Railway](https://railway.app)** and create a new project
2. **Add PostgreSQL**: Click "+ New" → Database → PostgreSQL
3. **Add Redis**: Click "+ New" → Database → Redis
4. **Add your server**:
   - Click "+ New" → GitHub Repo → Select your repository
   - Set root directory: `todo_server`
   - Railway auto-detects Dockerfile

5. **Configure environment variables** in your server service:
   ```
   DATABASE_HOST=${{Postgres.PGHOST}}
   DATABASE_PORT=${{Postgres.PGPORT}}
   DATABASE_NAME=${{Postgres.PGDATABASE}}
   DATABASE_USER=${{Postgres.PGUSER}}
   DATABASE_PASSWORD=${{Postgres.PGPASSWORD}}
   REDIS_HOST=${{Redis.REDIS_HOST}}
   REDIS_PORT=${{Redis.REDIS_PORT}}
   REDIS_USER=${{Redis.REDIS_USER}}
   REDIS_PASSWORD=${{Redis.REDIS_PASSWORD}}
   ```

6. **Configure ports**:
   - In Settings → Networking, expose port **8080** (API server)
   - Railway will generate a public URL like `your-app.railway.app`

7. **Update config/production.yaml** with your Railway domain and redeploy

8. **Run migrations**:
   - Open Railway service shell or run locally:
   ```bash
   DATABASE_URL=postgres://user:pass@host:port/db dart run bin/main.dart --apply-migrations
   ```

### 3. Update Flutter client

Update `todo_flutter/lib/main.dart` with your Railway URL:

```dart
const String serverUrl = String.fromEnvironment(
  'SERVER_URL',
  defaultValue: 'https://your-app.railway.app',
);
```

Or pass it at build time:
```bash
flutter build web --dart-define=SERVER_URL=https://your-app.railway.app
```

---

## Option 2: Heroku

Heroku's free tier has been discontinued, but you can use the $5/month Eco plan.

### 1. Prepare Heroku deployment files

**Create `Procfile`** in `todo_server/`:
```
web: ./bin/server --mode=production
```

**Create `heroku.yml`** in `todo_server/`:
```yaml
build:
  docker:
    web: Dockerfile
run:
  web: /app/bin/server --mode=production
```

Use the same **Dockerfile** from the Railway section above.

### 2. Deploy to Heroku

```bash
# Login and create app
heroku login
heroku create your-app-name

# Set stack to container
heroku stack:set container -a your-app-name

# Add PostgreSQL and Redis
heroku addons:create heroku-postgresql:mini -a your-app-name
heroku addons:create heroku-redis:mini -a your-app-name

# Configure environment variables (Heroku auto-sets DATABASE_URL and REDIS_URL)
# You'll need to parse DATABASE_URL into separate vars or modify your config

# Push and deploy
git push heroku main

# Run migrations
heroku run dart run bin/main.dart --apply-migrations -a your-app-name
```

**Update `config/production.yaml`** to use Heroku's `$PORT` and parse connection strings.

---

## Common Issues & Fixes

### 1. **Connection refused / Port issues**

**Problem**: Server not responding or "connection refused"

**Fix**:
- Railway: Ensure port **8080** is exposed in Settings → Networking
- Heroku: Bind to `0.0.0.0` not `localhost`; use `$PORT` environment variable
- Check `publicHost` in `config/production.yaml` matches your deployed domain

### 2. **Database connection failed**

**Problem**: `SocketException` or "could not connect to database"

**Fix**:
- Verify environment variables are set correctly (check Railway/Heroku dashboard)
- Ensure `requireSsl: true` in production.yaml for managed databases
- Check database is in the same region/network as your server
- Railway: Reference Postgres variables using `${{Postgres.PGHOST}}`
- Heroku: Parse `DATABASE_URL` or set individual vars from connection info

### 3. **Migrations not applied**

**Problem**: Tables don't exist or schema is outdated

**Fix**:
```bash
# Railway shell or local with prod DB connection string:
dart run bin/main.dart --apply-migrations

# Heroku:
heroku run dart run bin/main.dart --apply-migrations -a your-app-name
```

### 4. **WebSocket/Streaming not working**

**Problem**: Real-time updates don't work; streaming connection fails

**Fix**:
- Ensure WebSocket protocol is enabled on your hosting platform (Railway supports it by default)
- Check `publicScheme: https` in production.yaml (wss:// for WebSockets over HTTPS)
- In Flutter client, use `wss://your-app.railway.app` not `ws://`
- Verify firewall/proxy isn't blocking WebSocket upgrades

### 5. **Flutter client can't reach server**

**Problem**: Network errors, timeout, or CORS issues

**Fix**:
- Update `SERVER_URL` in Flutter app to your deployed domain (https://your-app.railway.app)
- For web: Configure CORS in server if needed (Serverpod handles this by default)
- Check server logs for incoming requests (Railway Logs tab)
- Test server endpoint directly in browser: `https://your-app.railway.app/api/health`

### 6. **Server crashes on startup**

**Problem**: Server exits immediately or shows "Unhandled exception"

**Fix**:
- Check Railway logs for stack traces
- Verify all config files are copied in Dockerfile (config/, web/, migrations/)
- Ensure config/production.yaml exists and has correct syntax
- Test locally with production config: `dart run bin/main.dart --mode=production`

### 7. **Environment variable substitution not working**

**Problem**: `$DATABASE_HOST` appears literally instead of being replaced

**Fix**:
- Serverpod reads env vars at runtime, not build time
- Railway: Use `${{Postgres.PGHOST}}` syntax in Railway env vars (Railway substitutes these)
- Heroku: Set vars explicitly or use `envsubst` in startup script
- Alternative: Use Dart's `Platform.environment` in server code

### 8. **Redis connection errors**

**Problem**: "Redis connection failed" or timeout

**Fix**:
- Verify Redis addon is provisioned and running (Railway/Heroku dashboard)
- Check `REDIS_HOST`, `REDIS_PORT`, and `REDIS_PASSWORD` are set
- Railway: Redis might not have TLS; set `enabled: true` but don't require SSL
- Test connection: `redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD`

---

## Testing Your Deployment

1. **Check server health**:
   ```bash
   curl https://your-app.railway.app/
   ```

2. **Test API endpoint**:
   ```bash
   curl https://your-app.railway.app/task/list
   ```

3. **Test WebSocket** (browser console or wscat):
   ```javascript
   const ws = new WebSocket('wss://your-app.railway.app/websocket');
   ws.onopen = () => console.log('Connected');
   ws.onmessage = (e) => console.log('Message:', e.data);
   ```

4. **Check logs**:
   - Railway: Click on service → Logs tab
   - Heroku: `heroku logs --tail -a your-app-name`

---

## Performance Tips

1. **Use connection pooling**: Serverpod handles this automatically
2. **Enable Redis caching**: Already configured for session management
3. **Scale horizontally**: Railway allows multiple instances with load balancing
4. **Monitor with Serverpod Insights**: Built-in at `/insights` endpoint
5. **Add CDN for Flutter web**: Use Cloudflare or Railway's CDN for static assets

---

## Next Steps

- Set up CI/CD with GitHub Actions for automated deployments
- Configure custom domain in Railway/Heroku settings
- Add monitoring and alerts (Railway metrics, Sentry, etc.)
- Implement database backups (Railway auto-backups included)
- Use environment-specific configs (staging.yaml for pre-production testing)

---

**Need help?** Check the [Serverpod documentation](https://docs.serverpod.dev) or [Railway docs](https://docs.railway.app).
