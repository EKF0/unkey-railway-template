# Unkey Railway Template

One-click deploy [Unkey](https://unkey.dev) — open-source API key management — on Railway.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy?repo=https://github.com/EKF0/unkey-railway-template)

## Services

| Service | Image | Port |
|---------|-------|------|
| **Unkey** | `ghcr.io/unkeyed/unkey:v2.0.49` (wrapper Dockerfile) | 7070 |
| **MySQL** | `mysql:9.4` (Railway database plugin) | 3306 |
| **Redis** | `redis:8.2` (Railway database plugin) | 6379 |

## Quick Deploy

### 1. Deploy Unkey from this repo
Click the "Deploy on Railway" button above, or use:
```
railway init --from-repo https://github.com/EKF0/unkey-railway-template
railway up
```
This deploys only Unkey. It will crash initially — that's expected.

### 2. Add MySQL
In your Railway project, click **+ New → Database → MySQL**.

### 3. Add Redis
Click **+ New → Database → Redis**.

### 4. Create the Unkey database
Connect to MySQL and run:
```sql
CREATE DATABASE IF NOT EXISTS unkey;
```
From the Railway CLI:
```bash
# Get the MySQL public URL
railway variables list -s MySQL | grep PUBLIC_URL
# Connect (substitute your values):
mysql -h <host> -P <port> -u root -p -e "CREATE DATABASE IF NOT EXISTS unkey;"
```

### 5. Set Unkey Environment Variables
On the Unkey service, go to **Variables → Raw Editor** and add:

```
UNKEY_DATABASE_PRIMARY=root:<mysql-password>@tcp(<mysql-host>:3306)/unkey?parseTime=true
UNKEY_REDIS_URL=redis://default:<redis-password>@<redis-host>:6379
PORT=7070
```

Replace `<values>` with actual MySQL/Redis credentials shown in their service variables.

### 6. Generate a Public Domain
```bash
railway domain -p 7070
```

### 7. Redeploy Unkey
Trigger a redeploy. The healthcheck will now pass.

### 8. Publish as Template (Optional)
**Settings → Publish as Template** for one-click sharing. Save the template with all service configurations.

## Verify Deployment
```bash
curl https://<your-domain>.up.railway.app/v2/liveness
# {"data":{"message":"we're cooking"},"meta":{"requestId":"..."}}
```

## Healthcheck
The v2.0.49 image exposes `GET /v2/liveness` on port 7070.

## Architecture Notes
- Unkey v2.0.49 uses **CLI flags** (`--database-primary`, `--redis-url`) with `os.Getenv` fallback, not TOML config files
- The API server runs as `unkey run api` (the base image has no default CMD)
- `${{}}` Railway references don't expand in service variables — use raw connection strings

## License
MIT. See [LICENSE](LICENSE). Unkey is also MIT licensed.
