# Unkey Railway Template

One-click deploy [Unkey](https://unkey.dev) (open-source API key management) on Railway.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy?repo=https://github.com/EKF0/unkey-railway-template)

## What Gets Deployed

| Service | Image | Port |
|---------|-------|------|
| **Unkey** | `ghcr.io/unkeyed/unkey:v2.0.49` | 7070 |

## After Initial Deploy — Add MySQL + Redis

The repo deploys only the Unkey service. Add datastores via Railway:

### 1. Add MySQL
- In your Railway project, click **+ New** → **Database** → **MySQL**
- Go to MySQL service variables, add: `MYSQL_DATABASE` = `unkey`, `MYSQL_USER` = `unkey`

### 2. Add Redis
- Click **+ New** → **Database** → **Redis**

### 3. Set Unkey Environment Variables
On the Unkey service, go to **Variables** and add:

| Variable | Value |
|----------|-------|
| `UNKEY_DATABASE_PRIMARY` | `${{MySQL.MYSQLUSER}}:${{MySQL.MYSQLPASSWORD}}@tcp(${{MySQL.MYSQLHOST}}:${{MySQL.MYSQLPORT}})/${{MySQL.MYSQLDATABASE}}?parseTime=true` |
| `UNKEY_REDIS_URL` | `redis://default:${{Redis.REDISPASSWORD}}@${{Redis.REDISHOST}}:${{Redis.REDISPORT}}` |
| `UNKEY_ROOT_KEY` | `${{random.hex(32)}}` |

Then **redeploy** the Unkey service.

### 4. Healthcheck
Status page at `https://<your-project-url>/health/live`

### 5. Publish as Template
Once everything works: **Settings** → **Publish as Template** for one-click sharing.

## License
MIT. See [LICENSE](LICENSE). Unkey is also MIT licensed.
