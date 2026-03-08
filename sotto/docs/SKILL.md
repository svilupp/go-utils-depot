---
name: using-sotto
description: Local-first, node-aware secrets CLI with stable sotto:// references, encrypted vault storage, ephemeral tokens, and remote node support. Use when storing, retrieving, or managing secrets, setting up .sotto.toml project context, resolving sotto:// references in code, wrapping secrets as tokens, importing from .env files, or injecting secrets into subprocesses.
---

# Using Sotto

Sotto stores secrets behind stable `sotto://` references in an encrypted local vault (age + scrypt). The same references resolve through remote HTTPS/JWT nodes without changing syntax.

## First Move

```bash
# Install
eget svilupp/go-utils-depot --tag 'sotto/*' --to ~/.local/bin

# Bootstrap vault + config
sotto init --default-profile work

# Store and retrieve
sotto set openai-api-key
sotto get openai-api-key --stdout
```

For non-interactive/CI usage:

```bash
export SOTTO_PASSPHRASE="correct horse battery staple"
sotto init --non-interactive
sotto set openai-api-key sk-ant-...
sotto get openai-api-key --stdout
```

## Commands

### init -- Bootstrap vault and config

```bash
sotto init                              # Interactive setup
sotto init --default-profile work       # Set default profile
sotto init --non-interactive            # Use SOTTO_PASSPHRASE env var
```

Creates `~/.config/sotto/config.toml` and `~/.config/sotto/vault.age`.

### set -- Store or update a secret

```bash
sotto set api-key                       # Interactive prompt for value
sotto set api-key sk-test-123           # Inline value (warns about shell history)
sotto set db-url --profile work --project acme.backend
sotto set deploy-key --note "CI/CD" --tags ci,deploy
echo "secret" | sotto set api-key       # Auto-detects piped stdin
echo "secret" | sotto set api-key --stdin  # Explicit stdin flag also works
sotto set sotto://work/acme.backend/db-password  # Write via URI
sotto set api-key --global              # Force global scope even with active context
```

Feedback: prints "Updated" for existing keys, "Stored" for new ones.

### get -- Retrieve a secret

```bash
sotto get api-key                       # Copy to clipboard (interactive TTY)
sotto get api-key --stdout              # Print to stdout (scripts)
sotto get db-url --profile work --project acme.backend
sotto get api-key --json                # Metadata JSON (value redacted)
sotto get api-key --json --stdout       # Metadata JSON with value included
sotto get api-key --uri                 # Print resolved sotto:// URI
sotto get api-key --exact               # Disable cascading, match exact scope only
sotto get sottok_7Kx9mPqR2v... --stdout  # Resolve ephemeral token
sotto get secret://provider/key         # Forward to remote node
```

Safety: `get` copies to clipboard by default when stdout is a TTY. Refuses to write to non-interactive stdout without `--stdout` or `--json`.

### del -- Delete a secret or burn a token

```bash
sotto del api-key                       # Delete with confirmation prompt
sotto del api-key --force               # Skip confirmation
sotto del sotto://work/acme.backend/db-password --exact
sotto del sottok_7Kx9mPqR2v... --force  # Burn an ephemeral token
```

Prompts for confirmation unless `--force` is set. `--exact` disables cascading lookup.

### list -- Show secret metadata

```bash
sotto list                              # Table format, current context
sotto ls                                # Alias
sotto list --all                        # Show every stored secret
sotto list --verbose                    # Include created/modified timestamps
sotto list --format json                # JSON output
sotto list --profile work               # Filter by profile
sotto list --project acme.backend       # Filter by project
sotto list --tokens                     # List active ephemeral tokens
```

Never shows raw values -- only metadata (key, ref, type, source, note, timestamps).

### wrap -- Create an ephemeral token

```bash
sotto wrap openai-api-key               # Default: 10m TTL, 1 use
sotto wrap openai-api-key --ttl 1h      # Custom TTL
sotto wrap openai-api-key --ttl 30m --uses 3  # Multiple uses
```

Prints the `sottok_*` plaintext to stdout (machine-readable). Metadata (expiry, uses) goes to stderr. The token is shown once and cannot be recovered.

### import -- Bulk load from .env files

```bash
sotto import .env                       # Import all entries
sotto import .env --dry-run             # Preview mapping table
sotto import .env --profile work --project acme.backend
sotto import .env --tags "imported,dotenv" --note "bulk import"
```

Keys are normalized from UPPER_SNAKE_CASE to lower-kebab-case. Empty values and comment lines are skipped. Reports new vs updated counts.

### env -- Export secrets as env vars or inject into subprocess

Reads the `[env]` section from the nearest `.sotto.toml`:

```bash
sotto env                               # Print KEY="value" lines (dotenv format)
sotto env -- node server.js             # Exec command with secrets in environment
sotto env -- docker compose up          # Works with any command
```

Requires a `.sotto.toml` with an `[env]` section. Fails with a clear error if any mapping cannot be resolved.

### status -- Show current context

```bash
sotto status                            # Config, node, vault, context info
sotto status --format json
```

## Bare Invocation Shorthand

For quick access without typing `get --stdout`:

```bash
sotto sottok_7Kx9mPqR2v...             # = sotto get sottok_... --stdout
sotto sotto://work/acme.backend/db-url  # = sotto get sotto://... --stdout
sotto secret://provider/key             # = sotto get secret://... --stdout
```

## Ephemeral Tokens (sottok_*)

Tokens are time-limited, use-limited handles to secrets. Share a token instead of the raw value.

```bash
# Create
sotto wrap api-key --ttl 1h --uses 3
# sottok_AbCdEf123456...

# Resolve (decrements remaining uses)
sotto get sottok_AbCdEf123456... --stdout

# List active tokens
sotto list --tokens

# Revoke permanently
sotto del sottok_AbCdEf123456... --force
```

Tokens are stored as SHA-256 hashes in the vault. The plaintext is shown once at creation. Expired, exhausted, or burned tokens are excluded from listings.

## Secret References (sotto://)

References are logical identifiers, not network locators:

```
sotto://api-key                                  # Global
sotto://work/api-key                             # Profile-scoped
sotto://work/acme.backend/db-password            # Project-scoped
sotto://work/acme.backend/db-password?node=corp  # Node selector
```

Dots in project names create hierarchy for monorepos (e.g., `myapp.api`, `myapp.worker`). Secrets set at a parent project cascade down to children automatically.

### secret:// URIs

`secret://` URIs are forwarded verbatim to remote nodes for resolution. They require an active remote node:

```bash
sotto get secret://provider/some-key --node corp
```

See [URI-CONVENTION.md](URI-CONVENTION.md) for the full reference: naming rules, dotted project patterns for monorepos, `.sotto.toml` placement, query parameters, and cascade mechanics.

## Cascading Lookup

Bare-key lookup with `profile=work, project=acme.backend.worker` resolves in order:

```
1. sotto://work/acme.backend.worker/<key>
2. sotto://work/acme.backend/<key>
3. sotto://work/acme/<key>
4. sotto://work/<key>
5. sotto://<key>
```

Profiles and keys are flat (no dots). Projects use dots to encode hierarchy.

Use `--exact` on `get`, `del`, or `wrap` to disable cascading and match only the exact scope.

## Context Detection

Resolution order (highest priority first):

1. CLI flags: `--node`, `--profile`, `--project`
2. Environment: `SOTTO_NODE`, `SOTTO_PROFILE`, `SOTTO_PROJECT`
3. Nearest `.sotto.toml` (walks up from PWD)
4. Global config defaults (`~/.config/sotto/config.toml`)

## Project Files (.sotto.toml)

Place in any directory to set context for that subtree:

```toml
node = "local"
profile = "work"
project = "acme.backend"

[env]
OPENAI_API_KEY = "openai-api-key"
DATABASE_URL = "db-url"
```

The `[env]` section maps env var names to sotto key names. Used by `sotto env` to export or inject secrets.

## Configuration

Global config: `~/.config/sotto/config.toml` (override path with `SOTTO_CONFIG` env var).

```toml
default_node = "local"
default_profile = "work"

[nodes.local]
kind = "local"
path = "~/.config/sotto/vault.age"

[nodes.corp]
kind = "remote"
url = "https://secrets.internal.example"
read_only = true

[nodes.corp.auth]
mode = "jwt"
audience = "sotto"
jwt_env = "SOTTO_JWT"
```

Node kinds: `local` (encrypted vault) or `remote` (HTTPS + JWT).

### Remote Node Auth

Remote nodes support three JWT resolution methods:

```toml
# From environment variable
jwt_env = "SOTTO_JWT"

# From file
jwt_file = "/path/to/token.jwt"

# From command output
jwt_command = "gcloud auth print-identity-token"
```

URL supports `${VAR}` expansion from environment variables.

Read-only remote nodes reject `Put` and `Delete` operations with a clear error.

## Global Flags

| Flag | Purpose |
|------|---------|
| `--node` | Select node for this operation |
| `--profile` | Set profile scope |
| `--project` | Set project scope |
| `--format` | Output format: `table` (default) or `json` |
| `--non-interactive` | Disable prompts, use env vars |

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `SOTTO_PASSPHRASE` | Vault passphrase (non-interactive/CI) |
| `SOTTO_CONFIG` | Override config file path |
| `SOTTO_NODE` | Default node (overrides config) |
| `SOTTO_PROFILE` | Default profile (overrides config) |
| `SOTTO_PROJECT` | Default project (overrides config) |

## Common Workflows

### Set up a new project

```bash
# 1. Init if not done
sotto init --default-profile work

# 2. Store project secrets
sotto set db-url --project myapp.backend
sotto set api-key --project myapp.backend

# 3. Create project file
cat > .sotto.toml << 'EOF'
profile = "work"
project = "myapp.backend"

[env]
DATABASE_URL = "db-url"
API_KEY = "api-key"
EOF

# 4. Now bare keys resolve with project context
sotto get db-url     # Resolves sotto://work/myapp.backend/db-url
```

### Import from an existing .env file

```bash
sotto import .env --profile work --project myapp.backend --dry-run
sotto import .env --profile work --project myapp.backend
```

### Run a process with secrets injected

```bash
sotto env -- node server.js
sotto env -- docker compose up
```

### Share a secret via ephemeral token

```bash
TOKEN=$(sotto wrap db-password --ttl 1h --uses 1)
echo "Resolve with: sotto get $TOKEN --stdout"
```

### Use in scripts

```bash
export SOTTO_PASSPHRASE="..."
DB_URL=$(sotto get db-url --stdout --non-interactive)
```

### Shared secrets across sub-projects

```bash
# Set at parent project level
sotto set shared-key --profile work --project acme

# Available to all sub-projects via cascade
sotto get shared-key --project acme.backend    # Finds sotto://work/acme/shared-key
sotto get shared-key --project acme.frontend   # Same cascade
```

### Use a remote node

```bash
export SOTTO_JWT="eyJhbGciOi..."
sotto get api-key --node corp --stdout
sotto get secret://provider/key --node corp --stdout
```

## Security Properties

**Protected:** plaintext-at-rest, shell/history leakage (interactive prompt by default), accidental stdout exposure (clipboard default + TTY guard).

**Not protected:** root compromise, same-user malware, leaked bearer grants.

Vault is always encrypted (age + scrypt), file permissions 0600, writes are atomic (temp + rename).

**Token security:** tokens are stored as SHA-256 hashes (plaintext is never persisted). Tokens have mandatory TTL and use limits. Burned tokens cannot be reused. Token resolution decrements the use counter atomically.

