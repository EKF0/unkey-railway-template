# Unkey on Railway — Template Creation Guide

## What We Built & Why

We created a Railway template to deploy Unkey (open-source API key management platform) with MySQL and Redis. The goal: one-click deployment for anyone wanting to self-host Unkey.

## The Journey (14 deployments later)

### Deployment Summary
```
Attempts: 14 (13 FAILED, 1 SUCCESS — now consistently successful)
Total time: ~2 hours of debugging
```

### Root Causes & Fixes

#### 1. THE BIG ONE: No CMD in Docker Image
**Problem**: The `ghcr.io/unkeyed/unkey:v2.0.49` image has `ENTRYPOINT ["/unkey"]` (CLI tool) but no `CMD`. Running `/unkey` alone shows help text and exits immediately.

**How we found it**: Checked `main.go` at tag v2.0.49 — the base `Command` struct has `Action: nil`, meaning no default action. The `run` subcommand has the actual API server logic.

**Fix**: Added `CMD ["run", "api"]` to our wrapper Dockerfile.

**Lesson**: Never assume a Docker image starts a server. Always check the `ENTRYPOINT` and `CMD` — especially with CLI tools packaged as Docker images.

#### 2. Wrong Healthcheck Path
**Problem**: We used `/health/live` (from the main branch's `runner.RegisterHealth()` code). This endpoint doesn't exist in v2.0.49.

**How we found it**: Read the v2.0.49 `svc/api/run.go` — no `runner.RegisterHealth()` call. Then searched routes directory for `v2_liveness` and found the handler at `svc/api/routes/v2_liveness/handler.go`.

**Fix**: Changed `healthcheckPath` to `/v2/liveness`.

**Lesson**: Never trust the main branch when deploying a specific tag. Tags can have completely different architectures. Always read the source at the exact tag you're deploying.

#### 3. Wrong Port
**Problem**: Railway defaults to port 3000 for healthchecks. Unkey v2.0.49 listens on port 7070 (set in config struct: `HttpPort int // default 7070`).

**How we found it**: Checked `svc/api/config.go` at tag v2.0.49 — `HttpPort` default is 7070.

**Fix**: Added `EXPOSE 7070` to Dockerfile and set `PORT=7070` env var.

**Lesson**: Railway's auto-port-detection from `EXPOSE` is not always reliable. Always set `PORT` explicitly for non-standard ports.

#### 4. Railway Variable Syntax (`${{}}`) Doesn't Expand in Service Variables
**Problem**: We set `UNKEY_DATABASE_PRIMARY=${{MySQL.MYSQLUSER}}:${{MySQL.MYSQLPASSWORD}}@...` hoping Railway would expand the `${{}}` references. The CLI picked up `UNKEY_REDIS_URL` but NOT `UNKEY_DATABASE_PRIMARY`.

**How we found it**: The `--database-primary` flag showed `(required)` with no default in help text, while `--redis-url` showed the actual value as default.

**Fix**: Set variables with raw connection strings instead of `${{}}` references.

**Lesson**: Railway's `${{ServiceName.VARIABLE}}` syntax only works in template definitions (when creating templates via the UI). It does NOT resolve when setting service variables manually or via CLI. Use raw values for service variables.

#### 5. Database Must Be Created Before App Starts
**Problem**: MySQL service exists, but the `unkey` database inside it was never created. App logged `Unknown database 'unkey'`.

**How we found it**: Saw the warning in deployment logs: `WRN db/database.go:71 failed to ping database on startup error="Error 1049 (42000): Unknown database 'unkey'"`.

**Fix**: Created the database with `CREATE DATABASE IF NOT EXISTS unkey;` via PyMySQL connection.

**Lesson**: Railway creates the MySQL service but NOT the databases inside it. Always verify databases exist before deploying apps that need them.

### Key Architecture Decisions

| Decision | Why |
|----------|-----|
| **Pre-built image + wrapper Dockerfile** | Building Unkey from source requires Bazel and the full Unkey repo. Much simpler to pull `ghcr.io/unkeyed/unkey:v2.0.49` and just set `CMD`. |
| **v2.0.49 tag, not latest** | This is the version used by the working Railway template. Using `latest` risks breaking changes. |
| **Single-service repo deploy** | Railway's "Deploy from Repo" only supports one service. MySQL/Redis are added as Railway database plugins via UI. |
| **PORT=7070 explicit** | Don't rely on `EXPOSE` for auto-detection. Set `PORT` explicitly. |

### How We Read the Unkey Source Code

Since Unkey has no official self-hosting docs, we navigated the source directly:

```
main.go              → Entry point: CLI with subcommands
cmd/run/api/main.go  → "run api" command: calls svc/api.Run()
svc/api/config.go    → Config struct showing env var names and defaults
svc/api/run.go       → Startup: DB init, Redis connect, HTTP server
svc/api/routes/      → All registered routes, including healthcheck
pkg/cli/flag.go      → How CLI flags map to env vars
pkg/cli/parser.go    → How required flag validation works
```

### Files in the Final Template

```
unkey-railway-template/
├── Dockerfile      # FROM ghcr.io/unkeyed/unkey:v2.0.49
│                   # EXPOSE 7070
│                   # CMD ["run", "api"]
├── railway.json    # { "build": {"builder": "DOCKERFILE"},
│                   #   "deploy": {"healthcheckPath": "/v2/liveness"} }
├── LICENSE         # MIT
└── README.md       # Deployment instructions
```

### Template Workflow for Users

1. Deploy repo → Unkey service starts (crashes — expected)
2. Add MySQL + Redis via Railway UI as database plugins
3. Create `unkey` database inside MySQL
4. Set `UNKEY_DATABASE_PRIMARY`, `UNKEY_REDIS_URL`, `PORT=7070` env vars
5. Generate public domain with `railway domain -p 7070`
6. Redeploy → healthy
7. Access at `https://<domain>/v2/liveness` → `{"message":"we're cooking"}`

### Useful Railway CLI Commands

```bash
railway login --browserless          # Auth in CI/headless
railway link                         # Link to existing project
railway service list                 # List all services
railway variables list               # Show service variables
railway variables list -s MySQL      # Show another service's variables
railway variables set KEY=VALUE      # Set variables
railway up                           # Deploy current directory
railway logs                         # View deployment logs
railway deployment list              # Show deployment history
railway domain -p 7070               # Create public domain
railway add -d mysql -s MySQL        # Add MySQL plugin
railway add -d redis -s Redis        # Add Redis plugin
```
