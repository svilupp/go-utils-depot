# Sotto Reference

Contributor-focused reference for the `sotto` module. For day-to-day usage, see [SKILL.md](SKILL.md).

## Package Structure

```text
sotto/
├── main.go                    # Entry point, version injection via ldflags
├── cmd/
│   ├── root.go                # Root command, global flags, bare invocation shorthand
│   ├── init.go                # Vault bootstrap and config creation
│   ├── set.go                 # Single-value writes and atomic bulk JSON writes
│   ├── get.go                 # Single-secret resolve and profile dump mode
│   ├── del.go                 # Secret deletion and token burning
│   ├── list.go                # Metadata listing, tag filtering, token listing
│   ├── search.go              # Metadata-index search (local nodes only)
│   ├── wrap.go                # Ephemeral token creation
│   ├── unlock.go              # Temporal unlock session bootstrap and daemon spawn
│   ├── lock.go                # Session shutdown
│   ├── import.go              # Dotenv import with dry-run support
│   ├── env.go                 # .sotto.toml env export and subprocess injection
│   ├── status.go              # Config/node/context status
│   └── helpers.go             # Shared scope/passphrase/output helpers
└── internal/
    ├── config/config.go       # Global config, XDG paths, SOTTO_CONFIG override
    ├── dotenv/parse.go        # Dotenv parsing + key normalization
    ├── node/
    │   ├── node.go            # Client interface, local node, remote node
    │   └── http.go            # Remote resolve HTTP client
    ├── ref/ref.go             # sotto:// and secret:// parsing, cascade candidates
    ├── scope/scope.go         # Flags -> env -> .sotto.toml -> config resolution
    ├── session/
    │   ├── session.go         # Session socket/info paths and persistence
    │   ├── client.go          # Client helpers for getpass/shutdown
    │   └── daemon.go          # In-memory unlock daemon
    ├── vault/
    │   ├── vault.go           # Encrypted vault persistence
    │   ├── token.go           # Ephemeral token lifecycle
    │   └── index.go           # Unencrypted metadata index for list/search
    └── clip/clipboard.go      # System clipboard integration
```

## Core Types

| Type | Package | Purpose |
|------|---------|---------|
| `Ref` | `ref` | Parsed logical secret reference |
| `ParsedArg` | `ref` | CLI argument kind: bare key, URI, token, `secret://` |
| `Config` | `config` | Global node/profile defaults and node definitions |
| `Scope` | `scope` | Resolved node/profile/project context |
| `Client` | `node` | Abstraction over local and remote backends |
| `Vault` | `vault` | Encrypted document of secrets + tokens |
| `Index` | `vault` | Unencrypted metadata catalog for local discovery |
| `Secret` | `vault` | Stored secret record |
| `Token` | `vault` | Ephemeral token record |

## Node Interface

```go
type Client interface {
    Kind() string
    Resolve(ctx context.Context, req ResolveRequest) (ResolvedSecret, error)
    Put(ctx context.Context, req PutRequest) (vault.Secret, error)
    Delete(ctx context.Context, req DelRequest) error
    List(ctx context.Context, req ListRequest) ([]vault.VisibleSecret, error)
    ListTokens(ctx context.Context) ([]ListedToken, error)
    Wrap(ctx context.Context, req WrapRequest) (WrapResult, error)
    Status(ctx context.Context) (Status, error)
}
```

Local node behavior:

- decrypts the vault per secret-bearing operation
- maintains the metadata index on writes/deletes/wraps
- serves `list` from the index when no passphrase is available

Remote node behavior:

- supports resolve-only HTTP POSTs to `/api/v1/sotto/resolve`
- authenticates via JWT from env var, file, or command output
- supports raw `secret://...` forwarding
- still does not implement remote `List`, `ListTokens`, or `Wrap`

## Metadata Index

Local nodes maintain an unencrypted sidecar index at:

```text
<vault path with extension removed>.index.json
```

It stores discovery metadata only:

- key name
- profile/project scope
- type
- tags
- created/modified timestamps

The index does **not** store secret values or notes.

## Unlock Sessions

`sotto unlock` starts a local daemon that:

- reads the passphrase once from the interactive caller
- keeps it in memory only
- serves later commands over a `0600` Unix socket
- expires automatically after the configured TTL

Session metadata is written to a `0600` JSON file in the session directory so
`status` can report whether the session is active, expired, profile-scoped, or
read-only.

Current session guardrails:

- `--read-only` blocks write operations while the session is used
- `--session-profile` restricts session-backed reads/writes to one profile
- explicit `SOTTO_PASSPHRASE` bypasses the session and its restrictions

This enables:

- `sotto list` without `SOTTO_PASSPHRASE` on local nodes
- `sotto search` without `SOTTO_PASSPHRASE` on local nodes
- typo suggestions on missing-key lookups

## Cascade Semantics

`ref.Candidates()` drives bare-key lookup:

```go
// profile="work", project="acme.backend.worker", key="db-url"
// =>
// work/acme.backend.worker/db-url
// work/acme.backend/db-url
// work/acme/db-url
// work/db-url
// db-url
```

`exact=true` disables the cascade and produces only the exact candidate.

## Batch Writes

`sotto set --file ...` and `sotto set --stdin-json`:

- validate all keys and values before writing anything
- open/decrypt the local vault once
- apply all writes in-memory
- save once

Remote batch writes are not supported.

## Error Handling

Key exported errors:

| Error | Package | Meaning |
|-------|---------|---------|
| `ErrVaultMissing` | `vault` | Vault file does not exist yet |
| `ErrNotFound` | `vault` | No secret/token matches |
| `ErrTokenExpired` | `vault` | Token TTL elapsed |
| `ErrTokenExhausted` | `vault` | Token uses depleted |
| `ErrTokenBurned` | `vault` | Token revoked |
| `ErrRemoteNotFound` | `node` | Remote secret not found |
| `ErrRemoteReadOnly` | `node` | Write attempted on read-only remote node |
| `ErrRemoteNotImplemented` | `node` | Remote operation still unsupported |
