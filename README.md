# Unkey Railway Template

One-click deploy [Unkey](https://unkey.dev) (open-source API key management) on Railway with MySQL and Redis.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy?repo=https://github.com/EKF0/unkey-railway-template)

## Services

| Service | Image | Purpose |
|---------|-------|---------|
| **Unkey** | `ghcr.io/unkeyed/unkey:v2.0.49` | API key management, rate limiting, auth |
| **MySQL** | `mysql:9.4` | Persistent data (API configs, key metadata) |
| **Redis** | `redis:8.2.1` | Real-time rate-limiting counters and state |

## What Gets Configured Automatically

The template wires up all connections between services:

- `UNKEY_DATABASE_PRIMARY` → MySQL in Go driver format: `user:password@tcp(host:port)/unkey?parseTime=true`
- `UNKEY_REDIS_URL` → Redis connection: `redis://default:password@host:port`
- `UNKEY_ROOT_KEY` → Auto-generated 32-char hex key for admin access

## After Deployment

1. In your Railway project, open the **Unkey** service
2. Go to the **Variables** tab and note the generated `UNKEY_ROOT_KEY`
3. Redeploy the Unkey service (if not done automatically)
4. Access the dashboard at the Unkey service's public URL

## Why Railway

- Zero-config database provisioning
- Automatic environment variable injection between services
- Private internal networking between Unkey, MySQL, and Redis
- One-click deploy from this template

## License

This template is MIT licensed. See [LICENSE](LICENSE).

Unkey itself is MIT licensed — see [Unkey's license](https://github.com/unkeyed/unkey/blob/main/LICENSE).
