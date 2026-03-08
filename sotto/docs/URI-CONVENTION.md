# Sotto URI Convention

`sotto://` is a **logical secret reference**, not a network locator. The path identifies which secret you mean. Where it gets resolved (local vault, remote node) is a separate concern.

## Structure

```
sotto://[profile/][project/]key[?query]
```

Three forms, three scopes:

```
sotto://api-key                          # global
sotto://work/api-key                     # profile-scoped
sotto://work/acme.backend/api-key        # project-scoped
```

- **1 segment** → key only (global scope)
- **2 segments** → profile / key
- **3 segments** → profile / project / key

More than 3 path segments is invalid.

## Naming Rules

| Component | Dots | Pattern | Examples |
|-----------|------|---------|----------|
| **Profile** | no | `[A-Za-z][A-Za-z0-9_-]*` | `work`, `personal`, `staging` |
| **Key** | no | `[A-Za-z][A-Za-z0-9_-]*` | `api-key`, `db-password`, `JWT_SECRET` |
| **Project** | yes, meaningful | each segment matches profile pattern | `acme`, `acme.backend`, `acme.backend.worker` |

Profiles are flat namespaces (think: identity / persona). Keys are flat names (think: what the secret is). Projects use dots to encode hierarchy (think: where the secret belongs).

## Dotted Projects and Monorepos

Dots in project names create **inheritance hierarchy**. This is the primary mechanism for sharing secrets across related services.

### Model your repo structure with dots

Given a monorepo:

```
myapp/
├── apps/
│   ├── web/
│   ├── api/
│   └── worker/
└── packages/
    ├── auth/
    └── db/
```

Map it to sotto projects:

```
myapp                    # shared across everything
myapp.web                # web app only
myapp.api                # api server only
myapp.worker             # background worker only
```

### Set secrets at the right level

```bash
# Shared by all services — set at root project
sotto set db-url --project myapp --profile work

# Only the API needs this
sotto set stripe-key --project myapp.api --profile work

# Only the worker needs this
sotto set redis-url --project myapp.worker --profile work
```

### Cascading lookup does the rest

When resolving a bare key with `profile=work, project=myapp.worker`:

```
1. sotto://work/myapp.worker/redis-url    ← found here (worker-specific)
2. sotto://work/myapp/redis-url           ← would check here next
3. sotto://work/redis-url                 ← then profile level
4. sotto://redis-url                      ← then global
```

When resolving `db-url` with the same context:

```
1. sotto://work/myapp.worker/db-url       ← not found
2. sotto://work/myapp/db-url              ← found here (shared)
```

The worker gets `db-url` from the parent project without explicitly setting it at the worker level.

### Deeper hierarchies

Dots can go as deep as needed:

```
acme                              # company-wide
acme.platform                     # platform team
acme.platform.auth                # auth service
acme.platform.auth.staging        # auth service staging overrides
```

Each dot adds a cascade step. `acme.platform.auth.staging` resolves through 5 candidates:

```
1. sotto://work/acme.platform.auth.staging/<key>
2. sotto://work/acme.platform.auth/<key>
3. sotto://work/acme.platform/<key>
4. sotto://work/acme/<key>
5. sotto://work/<key>
6. sotto://<key>
```

### .sotto.toml in monorepos

Place `.sotto.toml` files at service boundaries:

```
myapp/
├── .sotto.toml              # project = "myapp"
├── apps/
│   ├── web/.sotto.toml      # project = "myapp.web"
│   ├── api/.sotto.toml      # project = "myapp.api"
│   └── worker/.sotto.toml   # project = "myapp.worker"
```

Each `.sotto.toml` sets the project context so bare `sotto get <key>` commands resolve correctly from that directory:

```toml
# apps/api/.sotto.toml
profile = "work"
project = "myapp.api"

[env]
STRIPE_KEY = "stripe-key"
DATABASE_URL = "db-url"
```

The `[env]` section maps environment variable names to sotto key names. `DATABASE_URL` resolves via cascade — set once at `myapp`, inherited by `myapp.api`.

## Query Parameters

Query parameters are transport hints and never change the logical secret identity.

| Parameter | Purpose | Status |
|-----------|---------|--------|
| `node` | Which configured node resolves this reference | Implemented |
| `field` | Access a field within a structured secret | Reserved |
| `version` | Select a specific secret version | Reserved |

```
sotto://work/acme.backend/db-config?node=corp
sotto://work/acme.backend/db-config?field=password
sotto://work/acme.backend/api-key?version=2
```

Unknown query parameters are rejected.

### Why `node` is a query parameter, not a host

`sotto://` is not HTTP. The path is the identity ("which secret?"), the node is the resolver ("where to fetch it?"). Keeping these separate means references stay stable when you move from local to remote resolution.

```
sotto://work/acme/api-key              # resolves via default node
sotto://work/acme/api-key?node=corp    # resolves via corp node
```

Same secret, different resolver. The reference itself doesn't change.

## Storage Keys

Internally, references map to vault storage keys by joining non-empty components with `/`:

| Reference | Storage Key |
|-----------|-------------|
| `sotto://api-key` | `api-key` |
| `sotto://work/api-key` | `work/api-key` |
| `sotto://work/acme.backend/db-url` | `work/acme.backend/db-url` |

The dot in `acme.backend` is preserved as-is in storage — dot-splitting only happens during cascading lookup.

## Full vs Bare References

| Form | Behavior |
|------|----------|
| `sotto get api-key` | Bare key — cascades through project → profile → global |
| `sotto get sotto://work/acme/api-key` | Full URI — exact match only, no cascade |

Use bare keys for everyday lookups (let context + cascade do the work). Use full URIs in documentation, configs, or when you need an unambiguous pointer to a specific secret.
