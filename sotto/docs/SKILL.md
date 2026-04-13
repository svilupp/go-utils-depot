---
name: using-sotto
description: Local-first, node-aware secrets CLI with stable sotto:// references, encrypted vault storage, metadata-only discovery on local nodes, temporal unlock sessions, batch JSON writes, ephemeral tokens, and env injection. Use when storing, retrieving, importing, searching, unlocking, or injecting secrets with profile/project-aware scoping.
---

# Using Sotto

Sotto stores secrets behind stable `sotto://` references in an encrypted local vault (age + scrypt). Local nodes also maintain a metadata-only index so `list` and `search` can work without a passphrase, and `unlock` can start a local session daemon for later reads without `SOTTO_PASSPHRASE`.

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
sotto init
sotto init --default-profile work
sotto init --non-interactive
sotto init --vault-path ~/secure/sotto/vault.age
```

Creates `~/.config/sotto/config.toml` by default. Override the config path with `SOTTO_CONFIG`.

### set -- Store or update a secret

```bash
sotto set api-key
sotto set api-key sk-test-123
sotto set db-url --profile work --project acme.backend
sotto set api-key --global
echo "secret" | sotto set api-key
sotto set --file profile.json --profile personal
cat profile.json | sotto set --stdin-json --profile personal
sotto set api-key sk-test-123 --quiet
```

- Inline values warn by default because of shell history.
- `--quiet` / `-q` suppresses warnings, not errors.
- Batch JSON writes are local-node only and apply atomically after validation.

### get -- Retrieve a secret or dump a profile

```bash
sotto get api-key
sotto get api-key --stdout
sotto get api-key --json
sotto get api-key --json --stdout
sotto get api-key --uri
sotto get api-key --exact
sotto get sottok_7Kx9mPqR2v... --stdout
sotto get secret://provider/key --node corp --stdout

# Dump direct profile-scoped secrets
sotto get --profile personal --format json
sotto get --profile personal --format env
```

- With no positional key, `get` enters profile dump mode and requires `--profile`.
- Profile dump returns direct profile-scoped secrets only; it does not include project-scoped overrides.
- `get` refuses to write a secret to non-interactive stdout unless you use `--stdout` or `--json`.

### del -- Delete a secret or burn a token

```bash
sotto del api-key
sotto del api-key --force
sotto del sotto://work/acme.backend/db-password --exact
sotto del sottok_7Kx9mPqR2v... --force
```

Bare-key deletes follow cascade rules unless `--exact` is set. Confirmation/output show the resolved `sotto://...` target.

### list -- Show secret metadata

```bash
sotto list
sotto ls
sotto list --all
sotto list --verbose
sotto list --format json
sotto list --profile personal
sotto list --tag form-fill,identity
sotto list --tokens
```

- Local `list` works without `SOTTO_PASSPHRASE`; it uses the metadata index.
- `list --tokens` still requires vault access because tokens live inside the encrypted vault.
- Table output includes tags; JSON output includes timestamps and inherited source.

### search -- Search for key names

```bash
sotto search email
sotto search email --profile personal
sotto search api-key --format json
```

- Local `search` uses the metadata index and does not require `SOTTO_PASSPHRASE`.
- Search is key-name substring matching, case-insensitive.

### wrap -- Create an ephemeral token

```bash
sotto wrap openai-api-key
sotto wrap openai-api-key --ttl 1h
sotto wrap openai-api-key --ttl 30m --uses 3
sotto wrap openai-api-key --exact
```

Prints the plaintext `sottok_*` token to stdout and metadata to stderr. Tokens are shown once and stored as hashes in the vault.

### import -- Bulk load from `.env`

```bash
sotto import .env
sotto import .env --dry-run
sotto import .env --profile work --project acme.backend
sotto import .env --tags imported,dotenv --note "bulk import"
```

Keys are normalized from UPPER_SNAKE_CASE to lower-kebab-case.

### env -- Export secrets or inject a subprocess

Reads the `[env]` section from the nearest `.sotto.toml`:

```bash
sotto env
sotto env -- node server.js
sotto env -- docker compose up
```

### status -- Show config, node, and context

```bash
sotto status
sotto status --format json
```

Locked local vaults report `Secrets: locked (set SOTTO_PASSPHRASE to unlock)`.

### unlock / lock -- Start or end a temporal read session

```bash
sotto unlock --ttl 1h
sotto unlock --ttl 30m --read-only
sotto unlock --ttl 2h --session-profile personal --read-only
sotto lock
```

- `unlock` is local-node only.
- The daemon keeps the passphrase in memory and later commands fetch it over a local socket.
- `--session-profile` limits the session to a single profile.
- `--read-only` blocks writes while the session is active.

## Bare Invocation Shorthand

```bash
sotto sottok_7Kx9mPqR2v...
sotto sotto://work/acme.backend/db-url
sotto secret://provider/key --node corp
```

This is shorthand for `sotto get ... --stdout`.

## Secret References

```text
sotto://api-key
sotto://work/api-key
sotto://work/acme.backend/db-password
sotto://work/acme.backend/db-password?node=corp
```

See [URI-CONVENTION.md](URI-CONVENTION.md) for naming rules, dotted project hierarchy, query parameters, and cascade behavior.

## Context Detection

Resolution order:

1. CLI flags: `--node`, `--profile`, `--project`
2. Environment: `SOTTO_NODE`, `SOTTO_PROFILE`, `SOTTO_PROJECT`
3. Nearest `.sotto.toml`
4. Global config defaults

Example `.sotto.toml`:

```toml
node = "local"
profile = "work"
project = "acme.backend"

[env]
OPENAI_API_KEY = "openai-api-key"
DATABASE_URL = "db-url"
```

## Configuration

Default config path: `~/.config/sotto/config.toml`

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
jwt_env = "SOTTO_JWT"
```

Remote auth also supports `jwt_file` and `jwt_command`.

## Global Flags

| Flag | Purpose |
|------|---------|
| `--node` | Select node for this operation |
| `--profile` | Set profile scope |
| `--project` | Set project scope |
| `--format` | Output format: `table`, `json`, or `env` |
| `--quiet`, `-q` | Suppress warnings (errors still print) |

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `SOTTO_PASSPHRASE` | Vault passphrase for non-interactive/local automation |
| `SOTTO_CONFIG` | Override config file path |
| `SOTTO_NODE` | Default node override |
| `SOTTO_PROFILE` | Default profile override |
| `SOTTO_PROJECT` | Default project override |

## Security Properties

**Protected:** plaintext-at-rest, accidental stdout exposure, interactive clipboard default, token plaintext never persisted.

**Not protected:** root compromise, same-user malware, leaked bearer grants.

The local metadata index is unencrypted and stores only discovery metadata: key names, scope, type, tags, and timestamps. Secret values remain encrypted.

## Architecture

See [REFERENCE.md](REFERENCE.md) for package structure, node interface details, testing notes, and remaining work.
