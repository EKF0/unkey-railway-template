# Unkey Railway Template

One-click deploy [Unkey](https://unkey.dev) (open-source API key management) on Railway.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy?repo=https://github.com/EKF0/unkey-railway-template)

## What Gets Deployed

| Service | Image |
|---------|-------|
| **Unkey** | `ghcr.io/unkeyed/unkey:v2.0.49` |

## After Initial Deploy — Add MySQL + Redis

The initial deploy only launches Unkey. You need to add its datastores:

### 1. Add MySQL
- In your Railway project, click **+ New** → **Database** → **MySQL**
- Set variables on the MySQL service:
  - `MYSQL_DATABASE` = `unkey`
  - `MYSQL_USER` = `unkey`

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

### 4. Publish as Template
Once everything works, click the project's **Settings** → **Publish as Template** to create a one-click template others can use.

## Access the Dashboard
Your Unkey dashboard will be at the Unkey service's public URL.

## License
This template is MIT licensed. See [LICENSE](LICENSE). Unkey itself is MIT licensed.
