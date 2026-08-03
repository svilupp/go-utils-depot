# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, adapted for this repository.

## [Unreleased]

## [0.10.0] - 2026-08-03

### Added

- `linear favorite add|remove <identifier>` and `linear favorite list`:
  manage and list the viewer's favorited issues (viewer-scoped, no
  `--user`; `add`/`remove` are idempotent and workspace-guarded; `list` is
  read-only).
- `--create-missing-labels` on `create` and `update`: creates any `--label`
  name that doesn't already exist in the workspace instead of failing with
  "label not found" (workspace-guarded; `--dry-run` reports the names that
  would be created without creating them).
- `issues list --label-prefix <prefix>` (repeatable): filter to issues with
  any label containing the prefix, case-insensitively.

## [0.9.0] - 2026-07-30

### Added

- Agent comments now carry invisible, per-profile provenance. Comment reads
  expose verified `agentAuthored` state without showing the stamp, while human
  edits remain human input.
- Agent issue create and update calls can record exact Next revision receipts.
  `LINEAR_CALLER=human` provides an explicit override inside coding harnesses.

### Setup

- Run `linear init --profile-name <name>` once for each agent-used profile to
  generate its private `agent_marker`.

## [0.8.0] - 2026-07-17

### Added

- `linear comment create --parent <comment-uuid>` (also on the legacy
  `comment` form): create the comment as a threaded reply to an
  existing comment. The value is validated as a UUID up front
  (`VALIDATION_ERROR` on typo, before any network round-trip);
  top-level comments never send `parentId`.
- Comment JSON output now includes `parentId` (the id of the parent
  comment for threaded replies; omitted for top-level comments) in
  `comment list --json`, `comment get --json`, and comments embedded
  in `issue get --json`.
- New error code `UPSTREAM_UNAVAILABLE` (exit `9`) covering client-side
  HTTP timeouts, transport errors, Linear 5xx responses, and GraphQL
  `extensions.code == "INTERNAL"`. Carries `details.retry_after_seconds`
  (parsed from `Retry-After` for 5xx, defaulted to 30s for client
  timeouts and 60s for unannotated 5xx) so pollers can branch on
  retryable vs permanent failures without parsing the message.

### Changed

- HTTP client timeout default bumped from 10s to 30s; override via the
  new `LINEAR_HTTP_TIMEOUT` env var (Go duration; clamped to `[1s, 5m]`).
  Fixes spurious dance2 poller failures against the slower Linear
  GraphQL paths.

### Fixed

- Windows builds: the idempotency store's file lock now uses
  `LockFileEx`/`UnlockFileEx` on Windows (build-tagged files) instead of
  the POSIX-only `syscall.Flock`, which broke `GOOS=windows` compilation.

## [0.7.0] - 2026-05-24

### Added

- `linear issues list` (L1): list issues with `--label` (repeatable, AND),
  `--state`, `--assignee`, `--limit`, `--cursor`, and `--json` flags.
  JSON envelope shape `{"issues":[...], "cursor": "..." | null}` with
  cursor-based pagination. Unblocks dance2's label-poller use case.
- `linear me` (L4): print the authenticated viewer (id, email, name,
  organization url-key) as text or `--json`. Backed by the cached
  `ViewerInfo` round-trip.
- `linear comment upsert <issue>` (L2): atomically create-or-update a
  comment matched by `--marker` prefix. Body via `--body` or
  `--body-file` (stdin when `-`). The marker is auto-prepended to the
  body (as `marker + "\n\n" + body`) when missing, so the next upsert
  matches by prefix and edits in place instead of creating a duplicate
  — preserves L2 idempotency without forcing callers to repeat the
  marker. `--json` emits `{"id":"...","created":bool}`. Workspace
  guard runs first.
- `linear comment list --since <RFC3339>` and `--exclude-user <uuid>`
  (L3): server-side time filter (via Linear `comments(filter: {createdAt:
  {gt: ...}})`) and client-side author exclude. Both flags route through
  a new `ListCommentsFiltered` client method.

### Changed

- `client.State` gains an optional `Type` field (workflow type:
  `triage`/`backlog`/`unstarted`/`started`/`completed`/`cancelled`)
  selected by the new Issues list query. Unset on the legacy
  `FetchIssue` path so the wire shape there is unchanged.
- `LinearClient` interface adds `Issues(ctx, opts)` and
  `ListCommentsFiltered(ctx, identifier, opts)`. Existing methods
  unchanged.

### Fixes / Hardening

- `comment upsert`: when multiple comments match `--marker` (from a
  prior race), sort by `createdAt` ascending and edit the oldest so
  duplicates converge to a single canonical comment on subsequent
  upserts.
- `comment upsert --help`: documents that `--marker` is auto-prepended
  to `--body` when missing, and that race-time duplicates converge on
  the oldest match.
- `comment upsert --json`: envelope now includes `url` and
  `issueIdentifier` (parity with `comment create --json`), so agents
  no longer need a follow-up fetch to link the comment.
- `comment delete`: prompt-deny "Aborted." message now goes to stderr
  so stdout stays clean for pipelines.
- `comment edit` / `comment upsert`: `--body-file` pointing at an
  empty file is rejected with `VALIDATION_ERROR` (mirrors the existing
  empty-stdin guard), preventing silent body wipes.
- `comment list --exclude-user`: validates each value is UUID-shaped
  before fetching, so a typo'd stakeholder name fails fast instead of
  silently matching nothing.
- `comment list --help`: notes that `--exclude-user` is applied
  client-side after `--limit`, so the visible result may be smaller
  than `--limit`.
- `issues list --assignee`: preserves `UNAUTHORIZED` (exit 2) and
  `RATE_LIMITED` (exit 4) sentinels from `ResolveAssigneeID` instead
  of masking them as `VALIDATION_ERROR` (exit 8).
- `me`: non-auth / non-rate-limit failures from `ViewerInfo` are now
  wrapped as `INTERNAL` with the original error in `details.cause`,
  so `--error-json` is debuggable instead of opaque.

### Deferred

- L5 (`linear comment create --idempotency-key <k>`) is deferred:
  Linear's `CommentCreateInput` does not currently expose an
  `idempotencyKey` field. The SQLite client-side dedupe fallback is
  disproportionate complexity for the ~5 LOC savings it would yield
  on the dance2 side. Revisit if/when Linear adds native support, or
  if the crash window becomes a real problem in production.

## [0.6.0] - 2026-05-09

### Added

- Multi-workspace profiles in `~/.config/linear/config.yaml`. Select with `--profile`, `LINEAR_PROFILE`, `default_profile`, or sole-profile fallback.
- Workspace guard: mutations abort with `WORKSPACE_MISMATCH` if the profile's `workspace_key` doesn't match the API key's organization.
- `--error-json` flag: structured `{status, code, message, details}` errors on stderr with stable exit codes.
- `comment list`, `get`, `edit`, `delete` subcommands. `list` supports `--filter-prefix`, `--author`, `--limit`, `--json`.
- `profile list` and `profile show` for inspecting configured profiles.

### Changed

- `--assignee <name>` resolves through the active profile's `stakeholders` map first.

## [0.5.0] - 2026-05-09

### Breaking

- `linear init` now clears the legacy top-level `linear:` block after migrating its values into a profile (see `cmd/init.go:writeProfile`). Configs converge on the new profile-based schema; any tool that read fields directly out of the legacy block needs to read them out of the matching profile instead.

## [0.4.0] - 2026-03-11

### Added

- Added `linear update` for issue mutations from the CLI, including parent, state, priority, assignee, project, and label changes.
- Added machine-readable stdout modes:
  - `linear get --json`
  - `linear get --field <path>`
  - `linear create --json`
  - `linear update --json`
- Added parent-aware ticket creation with `linear create --parent <identifier-or-url>`.
- Added `--dry-run` support for `create` and `update`.

### Changed

- Expanded the internal issue model and GraphQL queries to include team, project, parent, label IDs, and richer mutation responses.
- Improved `linear get -s` summary output to include team, project, parent, and the internal issue UUID.
- Switched issue lookup to direct issue queries instead of search-based lookup for more reliable identifier resolution.

## [0.3.1] - 2026-03-11

### Added

- Added [`PLAN.md`](/Users/jsiml/Documents/GitHub/go-training-range/linear/PLAN.md) describing the next extension pass for the CLI.
- Documented the missing workflows discovered in real usage:
  - parent-child ticket creation
  - issue updates
  - machine-readable stdout output
  - richer issue metadata in `get`
  - optional batch ticket creation

### Changed

- Bumped the repo build version from `0.3.0` to `0.3.1` to reflect the planning/documentation release.
