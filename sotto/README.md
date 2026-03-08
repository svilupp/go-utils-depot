# Sotto

Encrypted secrets CLI. Store secrets locally, reference them with stable `sotto://` URIs, scope them by profile and project.

## When to use it

You have API keys, database passwords, tokens scattered across `.env` files, shell history, and sticky notes. Sotto gives them a single encrypted home with a consistent naming scheme that works across projects.

- `sotto set db-password` — store once, encrypted at rest
- `sotto get db-password --stdout` — retrieve in scripts
- `sotto://work/myapp/db-password` — stable reference that works everywhere
- `.sotto.toml` in project root — automatic context, `sotto env` exports secrets as env vars

## Install

```bash
eget svilupp/go-utils-depot --tag 'sotto/*' --to ~/.local/bin
```

## Quick start

```bash
# Set up vault
sotto init --default-profile work

# Store a secret (prompts for value)
sotto set openai-api-key

# Retrieve it
sotto get openai-api-key --stdout

# See what's stored (values stay hidden)
sotto list
```

Non-interactive (CI, scripts):

```bash
export SOTTO_PASSPHRASE="correct horse battery staple"
sotto set openai-api-key sk-test-123
sotto get openai-api-key --stdout
```

AI agents and long-running sessions:

```bash
sotto unlock --ttl 1h            # unlock once, agents read freely
sotto get openai-api-key --stdout  # no passphrase prompt needed
sotto lock                        # end session when done
```

## How it works

Secrets live in an encrypted vault (`~/.config/sotto/vault.age`) using [age](https://age-encryption.org/) encryption (AES-256-GCM + scrypt). Each secret is scoped by profile (who you are) and project (what you're working on).

Lookup cascades from specific to general. With `profile=work, project=myapp.backend`:

```
1. sotto://work/myapp.backend/<key>
2. sotto://work/myapp/<key>
3. sotto://work/<key>
4. sotto://<key>
```

Set a secret at `myapp` and every sub-project (`myapp.backend`, `myapp.frontend`) inherits it.

## Project files

Drop `.sotto.toml` in your project root to set context automatically:

```toml
profile = "work"
project = "myapp.backend"

[env]
OPENAI_API_KEY = "openai-api-key"
DATABASE_URL   = "db-url"
```

Then:

```bash
sotto env                       # print KEY="value" lines
sotto env -- node server.js     # run with secrets injected
sotto env -- docker compose up
```

## Commands

| Command | What it does |
|---------|-------------|
| `init` | Create vault and config |
| `set <key>` | Store or update a secret (`--file`/`--stdin-json` for bulk) |
| `get [<key>]` | Retrieve (clipboard default, `--stdout` for scripts, no key = profile dump) |
| `del <key>` | Delete a secret |
| `list` | Show metadata (values hidden, `--tag` to filter) |
| `search <term>` | Search key names (no passphrase needed) |
| `unlock` | Start a session for non-interactive access (`--ttl`, `--read-only`) |
| `lock` | End the active session |
| `status` | Show config, node, context, and session info |
| `env` | Export secrets from `.sotto.toml` `[env]` section |
| `import` | Bulk import from `.env` files |
| `wrap` | Create a time-limited token (`sottok_*`) |

## Context resolution

Sotto picks up profile/project from (highest priority first):

1. Flags: `--profile`, `--project`
2. Environment: `SOTTO_PROFILE`, `SOTTO_PROJECT`
3. Nearest `.sotto.toml` (walks up directory tree)
4. Global config defaults

## Config

`~/.config/sotto/config.toml`:

```toml
default_node = "local"
default_profile = "work"

[nodes.local]
kind = "local"
path = "~/.config/sotto/vault.age"
```

## Security

- Encrypted at rest (age + scrypt), vault file permissions 0600
- `list`, `search`, and `status` never show values
- `get` copies to clipboard interactively; requires `--stdout` for piping
- Atomic writes (temp file + rename)
- Session daemon holds passphrase in memory only (never written to disk), Unix socket with 0600 permissions, mandatory TTL (max 24h)

## Docs

- [Full usage guide](docs/SKILL.md) — every command with examples, workflows, env vars
- [URI convention](docs/URI-CONVENTION.md) — `sotto://` format, cascading rules, monorepo patterns
