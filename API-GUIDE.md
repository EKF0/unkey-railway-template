# APIs — A Complete Guide

> Everything you need to know about APIs, from "what is an endpoint" to building production API platforms.

---

## 1. What Is an API?

**API** = Application Programming Interface. It's a contract between two pieces of software.

Think of it like a restaurant:
- You (the client) sit at a table and read the **menu** (API documentation)
- You tell the **waiter** (HTTP request) what you want
- The waiter takes your order to the **kitchen** (server)
- The kitchen prepares your food and the waiter brings it back (**response**)

In software, the "menu" is the list of available endpoints. The "waiter" is HTTP. The "kitchen" is the backend server.

```bash
# You (client) ask the server for a health check:
curl https://api.example.com/v2/liveness

# Server responds:
{"data":{"message":"we're cooking"}}
```

---

## 2. HTTP — The Language of APIs

HTTP (HyperText Transfer Protocol) is how clients and servers talk to each other on the web.

### 2.1 A Request Has 4 Parts

```
POST /v2/keys.createKey HTTP/1.1          ← Method + Path + Protocol
Host: api.unkey.dev                        ← Headers
Authorization: Bearer unkey_abc123         ← Headers (continued)
Content-Type: application/json             ← Headers (continued)
                                           ← Empty line separates headers from body
{"apiId":"api_xyz","name":"my-key"}        ← Body (for POST/PUT/PATCH)
```

### 2.2 HTTP Methods (Verbs)

| Method | Meaning | Has Body? | Idempotent? | Used For |
|--------|---------|-----------|-------------|----------|
| `GET` | Read data | No | Yes | Fetching resources, health checks |
| `POST` | Create/perform action | Yes | No | Creating keys, verifying, RPC calls |
| `PUT` | Replace entire resource | Yes | Yes | Full updates |
| `PATCH` | Partial update | Yes | No | Partial updates |
| `DELETE` | Remove resource | No | Yes | Deletion |

**Idempotent**: Calling it twice has the same effect as calling once. DELETE is idempotent (deleting something already deleted changes nothing). POST is not (creating a key twice creates two keys).

### 2.3 HTTP Status Codes

```
1xx — Informational (rarely seen by clients)
2xx — Success
3xx — Redirection
4xx — Client Error (YOU messed up)
5xx — Server Error (THEY messed up)
```

| Code | Name | When |
|------|------|------|
| `200` | OK | Request succeeded (GET, successful POST) |
| `201` | Created | Resource was created (POST that creates) |
| `204` | No Content | Success with no response body (DELETE) |
| `301` | Moved Permanently | URL changed forever |
| `302` | Found | Temporary redirect |
| `400` | Bad Request | Malformed request (bad JSON, missing field) |
| `401` | Unauthorized | Missing or invalid credentials |
| `403` | Forbidden | Valid credentials but insufficient permissions |
| `404` | Not Found | Resource doesn't exist (or **path** doesn't exist) |
| `405` | Method Not Allowed | Wrong HTTP method (POST on a GET-only endpoint) |
| `409` | Conflict | Request conflicts with current state |
| `429` | Too Many Requests | Rate limited |
| `500` | Internal Server Error | Server crashed or encountered an unexpected error |
| `502` | Bad Gateway | Upstream server returned invalid response |
| `503` | Service Unavailable | Server overloaded or in maintenance |

**Critical distinction**: `401` = "who are you?" (authentication). `403` = "I know who you are, but you can't do that" (authorization).

### 2.4 Common Headers

#### Request Headers (client → server)
```
Authorization: Bearer <token>         # Auth token
Content-Type: application/json        # Body format
Accept: application/json              # What format client wants back
User-Agent: curl/8.0                  # Client identification
X-Request-Id: abc-123                 # Tracing/correlation
```

#### Response Headers (server → client)
```
Content-Type: application/json        # Response body format
X-Request-Id: abc-123                 # Echoed for tracing
X-RateLimit-Remaining: 99             # Rate limit info
Retry-After: 60                        # When to retry (for 429)
Cache-Control: no-cache               # Caching directives
```

---

## 3. REST — The Architectural Style

REST (Representational State Transfer) is a set of conventions, not a protocol.

### 3.1 REST Principles

**Resources, not actions**: URLs represent **nouns** (things), not verbs (actions).
```
✅ GET    /users/42          # Get user #42
✅ DELETE /users/42          # Delete user #42
❌ GET    /getUser?id=42     # Don't put verbs in URLs
❌ POST   /deleteUser        # Don't use POST for everything
```

**Statelessness**: Each request contains all information needed. The server doesn't remember previous requests.

**Layered**: Client doesn't know if it's talking to the actual server or a proxy/load balancer.

### 3.2 REST URL Conventions

```
GET    /users              # List all users
GET    /users/42           # Get user #42
POST   /users              # Create a new user
PUT    /users/42           # Replace user #42 entirely
PATCH  /users/42           # Update part of user #42
DELETE /users/42           # Delete user #42

# Nested resources:
GET    /users/42/keys      # Get keys belonging to user #42
GET    /users/42/keys/7    # Get key #7 of user #42
```

### 3.3 JSON — The Universal Format

```json
{
  "id": "key_abc123",
  "name": "production-key",
  "enabled": true,
  "permissions": ["read:data", "write:data"],
  "metadata": {
    "team": "backend",
    "created_by": "alice"
  },
  "createdAt": "2026-01-15T10:30:00Z",
  "expires": null
}
```

Conventions:
- **camelCase** keys (JavaScript convention, used by ~80% of APIs)
- **snake_case** keys (Python/Ruby convention)
- ISO 8601 for dates: `2026-01-15T10:30:00Z`
- `null` for empty values, don't omit the key
- Boolean prefix with `is`/`has`/`can`: `isActive`, `hasBilling`

### 3.4 A Complete REST Example

```bash
# GET — Read a resource
curl https://api.example.com/users/42 \
  -H "Authorization: Bearer tok_xxx"

# Response: 200 OK
{"id": 42, "name": "Alice", "email": "alice@example.com"}

# POST — Create a resource
curl -X POST https://api.example.com/users \
  -H "Authorization: Bearer tok_xxx" \
  -H "Content-Type: application/json" \
  -d '{"name": "Bob", "email": "bob@example.com"}'

# Response: 201 Created
{"id": 43, "name": "Bob", "email": "bob@example.com"}

# PATCH — Partial update
curl -X PATCH https://api.example.com/users/42 \
  -H "Authorization: Bearer tok_xxx" \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice Johnson"}'

# Response: 200 OK
{"id": 42, "name": "Alice Johnson", "email": "alice@example.com"}

# DELETE — Remove a resource
curl -X DELETE https://api.example.com/users/42 \
  -H "Authorization: Bearer tok_xxx"

# Response: 204 No Content
(empty body)
```

---

## 4. RPC — The Alternative to REST

### 4.1 What is RPC?

RPC (Remote Procedure Call) treats API calls like function calls. Instead of "manipulate a resource", you say "execute this procedure".

```
REST:  GET    /users/42           # "Give me user 42"
RPC:   POST   /users.getById      # "Call getById(42) on user"

REST:  DELETE /users/42           # "Delete user 42"
RPC:   POST   /users.delete       # "Call delete(42) on user"
```

### 4.2 Unkey Uses RPC

Unkey v2.0.49 uses an RPC style. Notice the endpoints:

```
POST /v2/keys.verifyKey          # "Run the verifyKey procedure"
POST /v2/keys.createKey          # "Run the createKey procedure"
POST /v2/ratelimit.limit         # "Run the limit procedure"
```

This is why ALL Unkey endpoints use `POST` — in RPC, every call is an action. The method is always POST because you're invoking a procedure, not manipulating a resource.

### 4.3 REST vs RPC — When to Use Which

| Use REST when... | Use RPC when... |
|------------------|-----------------|
| You have CRUD resources (users, posts, products) | You have actions/operations (verify, calculate, process) |
| You need caching (GET requests are cacheable) | Performance matters (single endpoint, optimized) |
| You want URL-based discoverability | You have complex business logic |
| Third-party developers need to explore your API | Internal services communicating |

### 4.4 gRPC and Connect RPC

Beyond JSON-based RPC, there are binary RPC protocols:

**gRPC**: Google's high-performance RPC framework using Protocol Buffers (binary format). 7-10x faster than JSON REST. Used by Unkey internally between services.

**Connect RPC**: A protocol by Buf that supports gRPC, gRPC-Web, and Connect protocols. Unkey uses this for service-to-service communication.

```protobuf
// A gRPC service definition (Protocol Buffers)
service KeyService {
  rpc VerifyKey(VerifyKeyRequest) returns (VerifyKeyResponse);
  rpc CreateKey(CreateKeyRequest) returns (CreateKeyResponse);
}
```

---

## 5. Authentication & Authorization

### 5.1 Authentication vs Authorization

- **Authentication** (AuthN): Who are you? (login, API key)
- **Authorization** (AuthZ): What can you do? (permissions, roles)

### 5.2 API Keys

The simplest form of API authentication. A long random string sent with each request.

```bash
# In a header (recommended):
curl https://api.example.com/data \
  -H "Authorization: Bearer sk_live_abc123xyz"

# In a query parameter (less secure — logged in URLs):
curl "https://api.example.com/data?api_key=sk_live_abc123xyz"

# In a custom header:
curl https://api.example.com/data \
  -H "X-API-Key: sk_live_abc123xyz"
```

**Key management** is exactly what Unkey provides — creating, rotating, revoking, and verifying API keys at scale.

### 5.3 JWT (JSON Web Tokens)

A self-contained token that carries claims (data) and is cryptographically signed.

```
Header:   {"alg": "HS256", "typ": "JWT"}
Payload:  {"sub": "user_42", "exp": 1716150000, "role": "admin"}
Signature: HMAC-SHA256(base64(header) + "." + base64(payload), secret)
```

Encoded JWT: `eyJhbG... . eyJzdW... . signature`

```bash
# Using a JWT:
curl https://api.example.com/admin \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..."
```

**Pros**: No database lookup needed (self-contained), can include permissions in the token.
**Cons**: Can't be revoked individually (without a blocklist), larger than API keys.

### 5.4 OAuth 2.0

A delegation protocol. "Allow App X to access my data on Service Y without sharing my password."

```
1. User clicks "Login with Google" on App X
2. App X redirects to Google's authorization page
3. User approves ("App X can read my email")
4. Google redirects back to App X with an authorization code
5. App X exchanges the code for an access token
6. App X uses the token to call Google's API on the user's behalf
```

Key concepts:
- **Authorization Code**: Short-lived, exchanged for tokens
- **Access Token**: Used to call the API (short-lived, e.g. 1 hour)
- **Refresh Token**: Used to get new access tokens (long-lived, e.g. 30 days)
- **Scopes**: Granular permissions ("read:email", "write:calendar")

### 5.5 How Unkey Handles Auth

```bash
# 1. Create an API (a namespace for keys):
curl -X POST https://unkey-railway-template-production.up.railway.app/v2/apis.createApi \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <UNKEY_ROOT_KEY>" \
  -d '{"name": "my-first-api"}'

# Response: {"apiId": "api_abc123"}

# 2. Create a key for that API:
curl -X POST https://unkey-railway-template-production.up.railway.app/v2/keys.createKey \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <UNKEY_ROOT_KEY>" \
  -d '{"apiId": "api_abc123", "name": "production-key", "remaining": 1000}'

# Response: {"key": "unkey_prod_abc...", "keyId": "key_xyz789"}

# 3. Verify a key (your backend does this on every user request):
curl -X POST https://unkey-railway-template-production.up.railway.app/v2/keys.verifyKey \
  -H "Content-Type: application/json" \
  -d '{"key": "unkey_prod_abc..."}'

# Response: {"valid": true, "ownerId": "...", "meta": {"name": "production-key"}}
```

---

## 6. API Design Patterns

### 6.1 Error Responses — Be Consistent

```json
// ✅ Good — always same structure:
{
  "error": {
    "code": "INVALID_KEY",
    "message": "The provided API key does not exist or has been revoked",
    "details": [
      {"field": "key", "issue": "not_found"}
    ],
    "requestId": "req_abc123"
  }
}

// ❌ Bad — inconsistent:
{"error": "not found"}           // Sometimes a string
{"code": 404, "msg": "nope"}     // Sometimes different keys
```

Always include:
- A machine-readable `code` (for programmatic handling)
- A human-readable `message` (for debugging)
- A `requestId` (for support/tracing)

### 6.2 Pagination

Never return ALL records at once. Use cursor-based pagination.

```bash
# First page:
curl "https://api.example.com/users?limit=50"

# Response includes a cursor for the next page:
{
  "data": [ ... 50 users ... ],
  "cursor": "eyJpZCI6NTB9"      # Opaque cursor for next page
}

# Next page:
curl "https://api.example.com/users?limit=50&cursor=eyJpZCI6NTB9"
```

**Why cursors > page numbers**: Page numbers break when data changes between requests (items shift pages). Cursors point to a specific position.

### 6.3 Rate Limiting

Prevent abuse by limiting how many requests a client can make.

```
Headers in every response:
X-RateLimit-Limit: 100         # Max requests per window
X-RateLimit-Remaining: 73      # Requests left in this window
X-RateLimit-Reset: 1716150600  # Unix timestamp when window resets
```

When exceeded, return `429 Too Many Requests`:
```
HTTP/1.1 429 Too Many Requests
Retry-After: 60
```

Unkey provides rate limiting as a core feature — the `POST /v2/ratelimit.limit` endpoint.

### 6.4 Idempotency Keys

For operations that shouldn't be repeated (payments, creates), clients send a unique key:

```bash
curl -X POST https://api.example.com/payments \
  -H "Idempotency-Key: 7b3f9a1c-4e2d-4f5a-8b6c-9d0e1f2a3b4c" \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000, "currency": "usd"}'
```

If the same key is sent twice, the server returns the original result instead of processing again. This prevents double-charging when network retries happen.

### 6.5 Webhooks

Instead of polling ("is it done yet?"), the server calls YOU when something happens.

```
1. You register a URL: https://myapp.com/webhooks/unkey
2. When an event occurs, Unkey POSTs to your URL:
   POST https://myapp.com/webhooks/unkey
   {"event": "key.expired", "keyId": "key_abc123", "timestamp": "..."}
3. Your server responds 200 OK to acknowledge receipt
```

**Always verify webhook signatures** — anyone can POST to your webhook URL.

---

## 7. API Development Lifecycle

### 7.1 Design First, Code Second

Write your API specification before writing code. Use **OpenAPI** (formerly Swagger):

```yaml
openapi: 3.0.0
info:
  title: My API
  version: 1.0.0
paths:
  /users:
    get:
      summary: List users
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
      responses:
        '200':
          description: A list of users
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/User'
```

Benefits:
- Auto-generate documentation
- Auto-generate client SDKs
- Auto-generate server stubs
- Contract testing — verify server matches spec

### 7.2 Versioning

APIs change over time. How do you handle breaking changes?

```
# URL versioning (most common):
https://api.example.com/v1/users
https://api.example.com/v2/users

# Header versioning:
curl https://api.example.com/users \
  -H "Accept: application/json; version=2"

# Query parameter (least recommended):
https://api.example.com/users?version=2
```

Unkey uses URL versioning: `/v2/keys.verifyKey`, `/v2/ratelimit.limit`.

### 7.3 Testing APIs

```bash
# 1. Manual testing with curl:
curl -X POST https://api.example.com/endpoint \
  -H "Content-Type: application/json" \
  -d '{"field": "value"}' | jq

# 2. Automated testing:
# Write tests that make real HTTP calls and assert responses
# Use tools like Jest + Supertest (JS), pytest + httpx (Python), Go's httptest

# 3. Load testing:
# How does the API behave under 1000 concurrent users?
# Tools: k6, wrk, Artillery

# 4. Contract testing:
# Does the API still match its OpenAPI spec?
# Tools: Schemathesis, Dredd
```

---

## 8. API Performance

### 8.1 Caching

Don't recompute or refetch the same data repeatedly.

```
Client → Cache (Redis/Memcached) → Database

1st request: Client → Cache → Miss → Database → Store in cache → Return
2nd request: Client → Cache → Hit → Return (10-100x faster)
```

**Cache-Control headers:**
```
Cache-Control: public, max-age=3600        # Cache for 1 hour
Cache-Control: private, max-age=60         # Only browser cache, 1 minute
Cache-Control: no-cache                    # Revalidate before using
Cache-Control: no-store                    # Don't cache at all (payments, PII)
```

**ETags** — conditional caching:
```
# First request:
GET /users/42 → 200 OK + ETag: "abc123"

# Subsequent request:
GET /users/42 + If-None-Match: "abc123" → 304 Not Modified (no body)
```

### 8.2 Connection Pooling

Opening a new TCP connection for every request is slow (TLS handshake, TCP handshake). Keep connections alive:

```
Connection: keep-alive
Keep-Alive: timeout=5, max=1000
```

This is handled automatically by HTTP clients (Go's `http.Client`, Python's `requests.Session`, Node's `http.Agent`).

### 8.3 Compression

Reduce bandwidth by compressing responses:

```bash
curl https://api.example.com/large-data \
  -H "Accept-Encoding: gzip"
```

Server compresses, client decompresses. Typically 5-10x smaller for JSON.

---

## 9. API Security

### 9.1 Always Use HTTPS

Never expose an API over plain HTTP. TLS encrypts:
- The URL path (but NOT the hostname — that leaks via SNI)
- Headers (including `Authorization`)
- Request/response body

### 9.2 CORS (Cross-Origin Resource Sharing)

Browsers block cross-origin requests by default. If your API needs to be called from a browser:

```
# Server sends these headers:
Access-Control-Allow-Origin: https://myapp.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
Access-Control-Allow-Headers: Authorization, Content-Type
```

For public APIs: `Access-Control-Allow-Origin: *`

### 9.3 Input Validation

**Never trust client input.** Validate everything:

```json
// ✅ Server validates:
{
  "email": "alice@example.com",    // Must match email regex
  "age": 25,                        // Must be 0-150
  "name": "Alice",                  // Must be 1-100 chars, no HTML
  "role": "user"                    // Must be one of ["user", "admin"]
}

// ❌ Never do this (SQL injection):
query = "SELECT * FROM users WHERE name = '" + userInput + "'"
// Input: "'; DROP TABLE users; --"

// ✅ Use parameterized queries:
query = "SELECT * FROM users WHERE name = ?"
db.Query(query, userInput)
```

### 9.4 Common Attacks

| Attack | What It Is | Defense |
|--------|-----------|---------|
| SQL Injection | Injecting SQL through inputs | Parameterized queries |
| XSS | Injecting scripts through inputs | Escape output, Content-Security-Policy |
| CSRF | Forging requests from another site | CSRF tokens, SameSite cookies |
| DDoS | Overwhelming with traffic | Rate limiting, CDN, WAF |
| MITM | Intercepting traffic | HTTPS (TLS) |
| Replay | Resending a captured request | Timestamps + nonces |

---

## 10. APIs in Production

### 10.1 Monitoring

Track these metrics:
- **Latency**: p50, p95, p99 response times
- **Error rate**: Percentage of 4xx/5xx responses
- **Throughput**: Requests per second
- **Saturation**: CPU, memory, connection pool usage

### 10.2 The Four Golden Signals (Google SRE)

1. **Latency** — How long does it take to serve a request?
2. **Traffic** — How many requests are coming in?
3. **Errors** — What fraction are failing?
4. **Saturation** — How full is the service?

### 10.3 SLIs, SLOs, SLAs

- **SLI** (Service Level Indicator): What you measure (e.g., "99.9% of requests return in <200ms")
- **SLO** (Service Level Objective): What you promise internally (e.g., "99.9% availability")
- **SLA** (Service Level Agreement): What you promise customers, with penalties (e.g., "99.5% or refund")

### 10.4 Graceful Degradation

When a dependency fails, don't crash everything:

```go
// Unkey v2.0.49 does this — database ping fails but server still starts:
if err := db.Ping(); err != nil {
    log.Warn("database ping failed, continuing anyway")
    // Don't os.Exit() — degrade gracefully
}
```

### 10.5 Circuit Breakers

If a downstream service is failing, stop calling it:

```
State transitions:
Closed → (5 failures in 10s) → Open
Open → (30s timeout) → Half-Open
Half-Open → (success) → Closed
Half-Open → (failure) → Open
```

---

## 11. How Unkey Fits In

Unkey is an **API key management platform**. Here's what each layer does:

```
┌─────────────────────────────────────────┐
│              Your API Users             │
│  (end users calling YOUR API with keys) │
└────────────────┬────────────────────────┘
                 │ x-api-key: unkey_xxx
                 ▼
┌─────────────────────────────────────────┐
│            Your Application             │
│      (backend, edge function, etc.)     │
│                                         │
│  On every request, call Unkey:          │
│  POST /v2/keys.verifyKey               │
│  POST /v2/ratelimit.limit              │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│              Unkey API                  │
│                                         │
│  • Verify keys (fast, <40ms target)     │
│  • Enforce rate limits                  │
│  • Track usage                          │
│  • Manage permissions/rbac              │
└──────┬──────────────┬───────────────────┘
       │              │
       ▼              ▼
   ┌───────┐    ┌─────────┐
   │ MySQL │    │  Redis  │
   │ keys  │    │  rates  │
   └───────┘    └─────────┘
```

### Key verification flow:
```
1. Your user makes a request to your API with x-api-key header
2. Your middleware extracts the key
3. Your middleware calls Unkey's /v2/keys.verifyKey
4. Unkey checks: key exists? not expired? not revoked? has permissions?
5. Unkey returns {valid: true/false, meta: {...}}
6. Your middleware allows or rejects the request
```

---

## 12. Quick Reference

### cURL Cheatsheet

```bash
# Basic GET
curl https://api.example.com/users

# GET with headers
curl https://api.example.com/users -H "Authorization: Bearer tok"

# POST JSON
curl -X POST https://api.example.com/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer tok" \
  -d '{"name": "Alice"}'

# Show response headers
curl -i https://api.example.com/users

# Follow redirects
curl -L https://api.example.com/users

# Show timing info
curl -w "\nTime: %{time_total}s\n" https://api.example.com/users

# Pretty-print JSON response
curl -s https://api.example.com/users | jq

# POST form data
curl -X POST https://api.example.com/login \
  -d "username=alice" \
  -d "password=secret"

# Upload a file
curl -X POST https://api.example.com/upload \
  -F "file=@/path/to/file.pdf"
```

### HTTP Decision Tree

```
Building an API? Start here:

Is it primarily CRUD operations on resources?
├── Yes → Use REST
│   └── GET /resources, POST /resources, GET /resources/:id, etc.
│
└── No (it's actions/operations)
    └── Use RPC
        └── POST /service.method

Need real-time communication?
├── Yes → Use WebSockets or Server-Sent Events
└── No → Use HTTP

Need type safety and high performance?
├── Yes → Use gRPC with Protocol Buffers
└── No → Use JSON over HTTP
```

### API Checklist

Before going to production, verify:

- [ ] All endpoints use HTTPS
- [ ] Authentication on every protected endpoint
- [ ] Input validation on every endpoint
- [ ] Consistent error response format
- [ ] Rate limiting
- [ ] Health check endpoint
- [ ] Logging with request IDs for tracing
- [ ] CORS configured (if called from browsers)
- [ ] Pagination on list endpoints
- [ ] Monitoring (latency, errors, throughput)
- [ ] OpenAPI/Swagger documentation
- [ ] Versioned (v1, v2) so you can make breaking changes
