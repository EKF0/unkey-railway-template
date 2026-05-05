# Template Publishing — Fill This On Railway

## Step 1: Go to Your Template Settings

Open: https://railway.com/deploy/6r8cz3
Click the "..." menu or Settings → Edit Template

## Step 2: Basic Info

```
Name:        Unkey
Short Description: Open-source API key management with rate limiting, usage tracking, and RBAC
Long Description: (paste the MARKDOWN section below)
Category:    Developer Tools (or API)
Tags:        api-key, authentication, rate-limiting, open-source, api-management
GitHub Repo: https://github.com/EKF0/unkey-railway-template (already set)
```

## Step 3: Template Variables

These must use `${{}}` syntax so Railway auto-wires services when someone deploys.

### On the Unkey service, set these template variables:

| Variable | Value (template syntax) |
|----------|------------------------|
| `UNKEY_DATABASE_PRIMARY` | `${{MySQL.MYSQLUSER}}:${{MySQL.MYSQLPASSWORD}}@tcp(${{MySQL.MYSQLHOST}}:${{MySQL.MYSQLPORT}})/${{MySQL.MYSQLDATABASE}}?parseTime=true` |
| `UNKEY_REDIS_URL` | `redis://default:${{Redis.REDISPASSWORD}}@${{Redis.REDISHOST}}:${{Redis.REDISPORT}}` |
| `UNKEY_ROOT_KEY` | `${{random.hex(32)}}` |
| `PORT` | `7070` |

### On the MySQL service:

| Variable | Value |
|----------|-------|
| `MYSQL_DATABASE` | `unkey` |
| `MYSQL_USER` | `unkey` |

## Step 4: Markdown Description

Copy and paste everything below into the template's Markdown/README field:

---

```
# Deploy and Host Unkey on Railway

Unkey is an open-source API management platform that lets you secure your services with **low-latency API key authentication**. It provides out-of-the-box **rate limiting**, **usage tracking**, **RBAC permissions**, and **temporary keys** — no custom auth layer needed.

## What Gets Deployed

| Service | Image | Purpose |
|---------|-------|---------|
| **Unkey** | `ghcr.io/unkeyed/unkey:v2.0.49` | API key verification, rate limiting, analytics |
| **MySQL** | `mysql:9.4` | Persistent data (API configs, key metadata, hashes) |
| **Redis** | `redis:8.2.1` | Real-time rate limiting counters, cache state |

## Architecture

Unkey is a high-performance Go backend targeting **<40ms key verification**. It uses:
- **MySQL** for API configs, key metadata, and encrypted key hashes
- **Redis** for high-speed rate limiting, temporary counters, and state

Railway auto-provisions both databases and injects environment variables via private internal networking.

## After Deployment

### 1. Create the Unkey Database
Connect to MySQL and run:
```sql
CREATE DATABASE IF NOT EXISTS unkey;
```

### 2. Get Your Root Key
Find `UNKEY_ROOT_KEY` in the Unkey service's Variables tab.

### 3. Generate a Public Domain
```bash
railway domain -p 7070
```

### 4. Verify It's Running
```bash
curl https://<your-domain>.up.railway.app/v2/liveness
# {"data":{"message":"we're cooking"},"meta":{"requestId":"..."}}
```

## Available API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v2/liveness` | GET | Health check |
| `/v2/keys.verifyKey` | POST | Verify an API key |
| `/v2/keys.createKey` | POST | Create a new API key |
| `/v2/keys.deleteKey` | POST | Delete/revoke a key |
| `/v2/keys.updateKey` | POST | Update key metadata/limits |
| `/v2/keys.getKey` | POST | Get key details |
| `/v2/apis.createApi` | POST | Create an API namespace |
| `/v2/apis.getApi` | POST | Get API configuration |
| `/v2/ratelimit.limit` | POST | Check rate limit |
| `/v2/ratelimit.setOverride` | POST | Override rate limit |
| `/v2/identities.*` | POST | Identity management |
| `/v2/permissions.*` | POST | RBAC permission management |

All endpoints require `Content-Type: application/json` and `Authorization: Bearer <UNKEY_ROOT_KEY>` (except `/v2/liveness` and `/v2/keys.verifyKey`).

## Common Use Cases

### SaaS API Authentication
Issue and manage unique API keys for customers with built-in revocation and rotation.

### AI / LLM Usage Guardrails
Apply per-user rate limits and usage caps to prevent runaway AI costs.

### Microservices Gateway
Secure internal service-to-service communication with metadata-tagged, short-lived keys.

## Template Configuration

The template auto-configures the connection between services:

```
UNKEY_DATABASE_PRIMARY → MySQL in Go driver format
UNKEY_REDIS_URL → Redis connection string
UNKEY_ROOT_KEY → Auto-generated 32-char hex key
PORT → 7070 (the port Unkey listens on)
```

### Healthcheck
The template uses `GET /v2/liveness` on port 7070 to verify the service is healthy.

## Why Self-Host Unkey on Railway

- Zero-config database provisioning for MySQL + Redis
- Private internal networking between services
- Automatic environment variable injection
- Vertical and horizontal scaling
- No PlanetScale or Clerk required (fully self-hosted)

## Source

Template source: https://github.com/EKF0/unkey-railway-template
Unkey source: https://github.com/unkeyed/unkey
```
