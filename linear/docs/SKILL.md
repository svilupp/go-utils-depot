---
name: linear-cli
description: Interact with Linear via the `linear` Go CLI — fetch/create/update issues and create/list/get/edit/delete comments across multiple workspaces with profile-based auth, workspace mutation guards, and structured `--error-json` errors. Use when an agent needs to read or modify Linear tickets or workpad comments without touching the GraphQL API directly.
---

# Linear CLI

Single-binary Go CLI (`linear`) for the Linear API. Profile-driven, multi-workspace, with a workspace guard that refuses cross-workspace mutations and a `--error-json` envelope on stderr for agent consumption.

## When to Use

- **Read a ticket** by identifier or URL (`AGI-123`, `https://linear.app/.../issue/AGI-123/...`)
- **Create / update** issues (title, description, parent, labels, state, priority, assignee)
- **Comments**: create, list, get, edit in place, delete (use this instead of `curl`-ing `api.linear.app/graphql`)
- **Update a workpad comment in place**: list with `--filter-prefix`, then `comment edit <id> --body-file -`
- **Multi-workspace**: switch via `--profile <name>` or `LINEAR_PROFILE`
- **Inside a Dance run**: always pass `--profile` and `--error-json` so the orchestrator can route errors

## First Move

```bash
# Profile resolution order: --profile > LINEAR_PROFILE > default_profile in config
linear profile show                     # what am I configured for
linear --profile work get SVI-14 -s     # quick sanity read

# Read
linear get AGI-123 -s                   # summary to stdout
linear get AGI-123 --json               # full JSON to stdout
linear get AGI-123 --field parent.identifier

# Comment workflow (workpad pattern)
linear comment list SVI-15 --json --filter-prefix "## Dance Workpad" \
  | jq -r '.[0].id' \
  | xargs -I{} sh -c 'cat workpad.md | linear comment edit {} --body-file -'
```

## Quick Reference

| Task | Command |
|------|---------|
| Show active profile | `linear profile show` |
| Show specific profile | `linear profile show <name>` |
| Show profile as YAML | `linear profile show [name] --output yaml` |
| List profiles | `linear profile list` |
| Read ticket (file) | `linear get AGI-123` (saves `logs/linear_AGI-123.json`) |
| Read ticket (stdout) | `linear get AGI-123 --json` |
| Read one field | `linear get AGI-123 --field parent.identifier` (any dotted JSON path) |
| Create issue | `linear create "Title" -d "body" --parent AGI-1 --label bug` |
| Update issue | `linear update AGI-123 --state QA --assignee me` |
| Clear parent | `linear update AGI-123 --clear-parent` |
| Clear all labels | `linear update AGI-123 --clear-labels` |
| Create comment | `linear comment create AGI-123 "ack"` |
| List comments | `linear comment list AGI-123 --json --limit 50` |
| Filter comments by prefix | `linear comment list AGI-123 --json --filter-prefix "## Dance"` |
| Filter by author | `linear comment list AGI-123 --author jan --json` |
| Get one comment | `linear comment get <uuid> --json` |
| Edit comment in place | `linear comment edit <uuid> --body-file workpad.md` |
| Edit from stdin | `cat body.md \| linear comment edit <uuid> --body-file -` |
| Delete comment | `linear comment delete <uuid> --yes` |

For canonical detail run `linear <cmd> --help` (do not duplicate it here).

## Profiles & Workspace Guard

Config lives at `~/.config/linear/config.yaml`:

```yaml
default_profile: personal
profiles:
  personal:
    api_key: ${LINEAR_API_KEY_PERSONAL}
    team_id: <uuid>
    project_id: <id>
    workspace_key: svilupp
    stakeholders:
      jan: <user-uuid>
  work:
    api_key: lin_api_xxx
    team_id: <uuid>
    workspace_key: <work-org-key>
```

Resolution order: `--profile` flag > `LINEAR_PROFILE` env > `default_profile` field > sole profile (when only one is defined) > legacy `linear:` block.

**Workspace guard**: every mutation (`create`, `update`, `comment create/edit/delete`) calls Linear once to confirm the api_key's organization matches the profile's `workspace_key`. On mismatch the request is aborted with `WORKSPACE_MISMATCH` before any write. Read commands (`get`, `comment list`, `comment get`) skip the guard.

Setup a profile interactively:

```bash
linear init --profile-name work
linear init --profile-name personal --api-key lin_api_xxx
LINEAR_API_KEY=lin_api_xxx linear init --non-interactive   # CI
```

## High-Signal Workflows

### Find the workpad comment by prefix → edit in place

```bash
COMMENT_ID=$(linear comment list SVI-15 --json --filter-prefix "## Dance Workpad" \
  | jq -r '.[0].id')
[ -n "$COMMENT_ID" ] && [ "$COMMENT_ID" != "null" ] || { echo "no workpad"; exit 1; }
linear comment edit "$COMMENT_ID" --body-file workpad.md
```

### Round-trip a comment body through a transform

```bash
linear comment get <uuid> --json \
  | jq -r .body \
  | sed 's/old/new/' \
  | linear comment edit <uuid> --body-file -
```

### Find your last comment by author → edit

```bash
COMMENT_ID=$(linear comment list AGI-123 --author jan --json \
  | jq -r 'sort_by(.createdAt) | reverse | .[0].id')
linear comment edit "$COMMENT_ID" --body "follow-up"
```

### Bulk-delete throwaway test comments

```bash
linear comment list AGI-123 --json --filter-prefix "TEST:" \
  | jq -r '.[].id' \
  | while read id; do linear comment delete "$id" --yes; done
```

### Capture comment ID at creation time

```bash
ID=$(linear --profile personal --error-json comment create SVI-15 "TEST" --json | jq -r .id)
linear --profile personal --error-json comment edit "$ID" --body "TEST edited"
```

### Create issue → assign → set state → comment

```bash
ID=$(linear create "Bug: login fails" -d "repro..." --parent AGI-1 --label bug --json \
  | jq -r .identifier)
linear update "$ID" --assignee jan --state "In Progress"
linear comment create "$ID" "started"
```

### Cross-workspace read (without changing default)

```bash
linear --profile work get SVI-14 -s
LINEAR_PROFILE=work linear comment list SVI-14 --json
```

## Error Handling

Use `--error-json` on every agent invocation. Errors go to **stderr** as a stable envelope; stdout stays clean for jq.

```json
{
  "status": "error",
  "code": "ISSUE_NOT_FOUND",
  "message": "issue SVI-99999 not found in workspace \"svilupp\" (profile \"personal\").\n...",
  "details": {"identifier": "SVI-99999", "profile": "personal", "workspace_key": "svilupp"}
}
```

Exit code is non-zero (e.g. `3` for not-found). Branch on `code`, not `message`.

| Code | Meaning | Agent action |
|------|---------|--------------|
| `WORKSPACE_MISMATCH` | profile's `workspace_key` ≠ api_key's org | **STOP** — fix profile config; never retry, never override |
| `UNAUTHORIZED` / auth failures | api_key invalid or revoked | **STOP** — prompt user to re-init profile |
| `ISSUE_NOT_FOUND` | identifier doesn't exist in this workspace | STOP — likely wrong `--profile` |
| `RATE_LIMITED` | Linear API throttling | RETRY with backoff |
| `VALIDATION_ERROR` (exit 8) | bad input — see triggers below | **STOP** — fix the invocation; never retry as-is |
| `CONFIG_INVALID` (exit 5) | bad / missing config (e.g. no `default_profile` and multiple profiles) | **STOP** — fix `~/.config/linear/config.yaml`. |
| `INTERNAL` (exit 1) | unexpected error wrapped by the CLI | RETRY once, then escalate. |
| network / 5xx | transient | RETRY (bounded) |

`VALIDATION_ERROR` triggers:
- Invalid `--limit` (must be `>= 1`; `0` and negatives rejected)
- Invalid comment-id UUID format on `comment get/edit/delete`
- Empty stdin via `--body-file -`
- `--body-file <path>` doesn't exist
- Both `--body` and `--body-file` passed
- Neither `--body` nor `--body-file` passed when one is required

Capture both streams:

```bash
out=$(linear --error-json --profile work comment edit "$id" --body-file - 2> err.json) || {
  code=$(jq -r .code < err.json)
  case "$code" in
    WORKSPACE_MISMATCH|UNAUTHORIZED|ISSUE_NOT_FOUND) echo "STOP: $code"; exit 1 ;;
    RATE_LIMITED) sleep 5; retry ;;
    *) echo "unknown: $(cat err.json)"; exit 1 ;;
  esac
}
```

## DO / DON'T

**DO**
- Pass `--profile <name>` explicitly inside any Dance / orchestrator run — don't rely on the user's shell `default_profile`.
- Use `--error-json` for every agent-driven invocation and parse the envelope.
- Use `--body-file -` (stdin) for multi-line comment bodies — avoids shell-quoting bugs and temp files.
- Use `comment list --filter-prefix` + `comment edit` to update workpad comments in place (no duplicate posts).
- Use `--field <path>` on `get` when you only need one value — cheaper than piping through jq.
- Use `--dry-run` on `create` / `update` to preview the resolved request before mutating.
- Capture new comment IDs at creation time with `comment create ... --json` instead of re-listing.
- Validate user-provided comment IDs are UUIDs before invoking the CLI — the CLI catches them, but pre-checking saves a process spawn.

**DON'T**
- **Don't `curl https://api.linear.app/graphql` directly** — leaks `LINEAR_API_KEY` in process listings, bypasses the workspace guard, and skips the structured error envelope.
- **Don't omit `--profile` in a Dance run** — the active profile depends on the caller's environment and can silently flip to `personal`.
- **Don't override `WORKSPACE_MISMATCH`** — it means the api_key and `workspace_key` disagree; the only correct fix is re-running `linear init` for that profile.
- Don't paste comment bodies inline if they contain backticks, `$`, or newlines — use `--body-file` / `-f`.
- Don't `comment create` to "update" an existing workpad — find it via `--filter-prefix` and `comment edit` instead.
- Don't pipe empty content to `--body-file -` expecting the body to clear; the CLI refuses. Clearing a comment body is not supported; edit the body to a single space or marker instead.

## Agent Notes

- `comment list` filters (`--filter-prefix`, `--author`) run **client-side** after fetching `--limit` (default 50). Bump `--limit` if older comments may match.
- `comment edit` requires exactly one of `--body` or `--body-file`. `--body-file -` reads stdin.
- **Empty stdin on `--body-file -` is rejected** with `VALIDATION_ERROR` to prevent accidentally clearing a comment when an upstream pipeline produced nothing. Clearing a comment body is not supported (`--body ""` also errors); edit the body to a single space or marker instead.
- **Comment IDs are Linear UUIDs** (e.g., `9b8a8f12-4fcb-4234-9f0b-1745ce8ee85e`). Don't try to address comments by index, position, or human label. `comment get/edit/delete` pre-validate the UUID format and fail fast with `VALIDATION_ERROR` (hint: use `comment list <issue> --json` to find IDs) rather than wasting a network call ending in `COMMENT_NOT_FOUND`.
- `comment delete` prompts unless `--yes` is passed. Always use `--yes` in scripts.
- `update` only changes fields you pass; state is never auto-applied — pass `--state` explicitly.
- `--assignee jan` resolves via the profile's `stakeholders` map first, then by name/email/UUID. `--assignee me` resolves to the api_key owner.
- `linear get` saves to `logs/linear_<ID>.json` by default. Use `-s` for summary-to-stdout, `--json` for raw JSON, `-o <path>` for custom path.
- `linear get` rejects combining `--summary` / `--json` / `--field` / `--output` — pick exactly one. (Enforced at `cmd/get.go:60-77`.)
- `--field` accepts arbitrary dotted JSON paths into the issue payload (e.g. `id`, `state.name`, `assignee.email`, `parent.identifier`) — not just `parent.identifier`.
- The legacy positional form `linear comment SVI-15 "msg"` still works but new scripts should use `linear comment create SVI-15 "msg"`.
- Active profile and stakeholders are echoed at the bottom of every `--help` — handy for confirming you're in the right workspace before mutating.
