# Linear CLI

A simple CLI for working with Linear tickets and comments — built for humans and AI agents.

- **Read, create, update, comment** on tickets without touching GraphQL
- **Multi-workspace profiles** so one user can switch between work, personal, etc.
- **Safe by default** — workspace guard refuses cross-workspace writes

## Install

```bash
eget svilupp/go-utils-depot --tag 'linear/' --to ~/.local/bin
```

## Quick start

```bash
linear init                # configure your first profile
linear get AGI-123
```

`init` asks for your API key (<https://linear.app/settings/api>), team, and pins the workspace so mutations can't go to the wrong place.
It also generates a private `agent_marker` for automatic agent provenance.

## Commands

| Command        | What it does                                                                                  |
| -------------- | --------------------------------------------------------------------------------------------- |
| `init`         | Create or update a profile                                                                    |
| `get`          | Fetch a ticket; `--json` or `--field <path>` for scripts                                       |
| `create`       | New ticket; supports `--parent`, `--label`, `--project`                                        |
| `update`       | Edit ticket fields (state, priority, assignee, labels, parent)                                 |
| `issues list`  | List issues; `--label` (repeatable, AND), `--label-prefix` (repeatable, prefix match), `--state`, `--assignee`, `--limit`, `--cursor`, `--json` |
| `comment`      | Manage comments: `list`, `get`, `edit`, `delete`, `upsert`, or post inline                     |
| `favorite`     | `add` / `remove` / `list` the viewer's favorited issues                                        |
| `me`           | Print the authenticated viewer (id, email, name, organization); `--json`                       |
| `profile`      | `list` / `show` configured profiles                                                            |

`create` and `update` accept `--create-missing-labels`: any `--label` value
that doesn't already exist in the workspace is created instead of failing
with "label not found" (workspace-guarded; `--dry-run` reports the names that
would be created without creating them).

`favorite add`/`favorite remove <identifier>` are idempotent and
workspace-guarded (no-op if already/not favorited); `favorite list` is
read-only and viewer-scoped — there is no `--user` flag.

`comment list` also accepts `--since <RFC3339>` (server-side time filter) and
`--exclude-user <uuid>` (repeatable, client-side). `comment upsert <issue>` is
an atomic find-or-create matched by `--marker` prefix; the marker is
auto-prepended to the body when missing so subsequent calls match and edit in
place instead of duplicating.

Workspace profiles continue to work as before — `--profile`, `LINEAR_PROFILE`,
and `default_profile` resolution is unchanged.

Run `linear <cmd> --help` for full flags.

## Profiles

One config, many workspaces. `~/.config/linear/config.yaml`:

```yaml
default_profile: work
profiles:
  work:
    api_key: lin_api_xxx
    team_id: <team-uuid>
    workspace_key: svilupp           # pinned by `linear init`
    agent_marker: linear-agent-...    # generated, keep private
    stakeholders:
      jan: 11111111-1111-1111-1111-111111111111
  personal:
    api_key: ${LINEAR_API_KEY_PERSONAL}   # env vars expanded at load
    team_id: <team-uuid>
    workspace_key: jan-personal
    agent_marker: linear-agent-...
```

Active profile resolution: `--profile <name>` > `LINEAR_PROFILE` > `default_profile` > sole profile > legacy `linear:` block.

`stakeholders` maps friendly names to user UUIDs. Used by `--assignee <name>` and `comment list --author <name>`.

## Examples

```bash
# Read
linear get AGI-123 --summary
linear get AGI-123 --json
linear get AGI-123 --field parent.identifier

# Create / update
linear create "Bug: login broken" --parent AGI-123 --label bug
linear update AGI-123 --state QA --priority 2 --assignee jan

# Comments
linear comment AGI-123 "ack"                          # inline post
linear comment list SVI-15 --json --limit 50
linear comment list SVI-15 --json --filter-prefix "## Workpad"
linear comment list SVI-15 --json --since 2026-05-24T10:00:00Z --exclude-user <bot-uuid>
linear comment upsert SVI-15 --marker "## Workpad" --body-file workpad.md --json
linear comment edit <comment-id> --body-file new.md
linear comment delete <comment-id> --yes

# Discovery
linear issues list --label dance2:active --state Todo --json
linear issues list --label-prefix dance2: --json
linear me --json

# Favorites
linear favorite add AGI-1840
linear favorite remove AGI-1840 --json
linear favorite list --json

# Create/update with auto-created labels
linear create "Bug: login broken" --label new-label --create-missing-labels
linear update AGI-123 --label new-label --create-missing-labels --dry-run
```

`issues list --json` returns a paginated envelope:

```json
{
  "issues": [
    {"id":"...","identifier":"SVI-42","title":"...",
     "state":{"name":"Todo","type":"unstarted"},
     "labels":["dance2:active"],"url":"...","updatedAt":"..."}
  ],
  "cursor": null
}
```

When `cursor` is non-null, pass it back via `--cursor <value>` for the next page.

Identifiers accept either form: `AGI-123` or the full Linear URL.

## For agents / scripts

Pass `--error-json` to get a stable JSON envelope on stderr and branch on `code`:

```json
{"status":"error","code":"ISSUE_NOT_FOUND","message":"...","details":{"identifier":"AGI-9999"}}
```

| Code                 | Exit | Meaning                                                |
| -------------------- | ---- | ------------------------------------------------------ |
| `INTERNAL`           | 1    | Unexpected failure                                     |
| `UNAUTHORIZED`       | 2    | API key rejected                                       |
| `ISSUE_NOT_FOUND`    | 3    | Identifier not in this workspace                       |
| `RATE_LIMITED`       | 4    | Slow down                                              |
| `CONFIG_INVALID`     | 5    | Missing/bad config or unknown profile                  |
| `WORKSPACE_MISMATCH` | 6    | Profile doesn't match the API key's org                |
| `COMMENT_NOT_FOUND`  | 7    | Stale comment id                                       |
| `VALIDATION_ERROR`   | 8    | Bad input (mutually-exclusive flags, empty body, etc.) |
| `UPSTREAM_UNAVAILABLE` | 9 | Linear API timeout / 5xx / transient INTERNAL (retryable) — `details.retry_after_seconds` carries a backoff hint |

Always pass `--profile <name>` explicitly in agent flows so the transcript shows which workspace was targeted.

For pollers: branch on exit `9` (or `code == "UPSTREAM_UNAVAILABLE"`) for retryable upstream failures and back off using `details.retry_after_seconds` before retrying. Exit `4` (`RATE_LIMITED`) also carries `retry_after_seconds`.

### Agent provenance

The CLI detects Codex, Claude, and Pi from environment and process ancestry
signals.

For detected agent calls:

- comment create, edit, and upsert append an invisible HMAC stamp keyed by the
  active profile's `agent_marker`
- comment list and get set `agentAuthored: true` only when that stamp matches
  the current body, then remove the stamp from command output

Agents do not add a visible signature. Human edits invalidate an old stamp.
Use `LINEAR_CALLER=human` for a human-intended command launched inside a coding
harness. `LINEAR_CALLER=agent` forces agent provenance for another wrapper.

## CI / non-interactive

```bash
LINEAR_API_KEY=lin_api_xxx LINEAR_TEAM_ID=<uuid> \
  linear init --non-interactive --profile-name ci
```

Env-var references (`${LINEAR_API_KEY}`) are expanded at load time, so the YAML can stay secret-free.

### Environment variables

| Variable               | Purpose                                                                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `LINEAR_PROFILE`       | Select active profile (overridden by `--profile`).                                                                            |
| `LINEAR_CALLER`        | Provenance override: `auto`, `human`, `agent`, `codex`, `claude`, or `pi`. Default `auto`.                                     |
| `LINEAR_API_KEY`       | API key for non-interactive `init`. Also referenced from YAML via `${LINEAR_API_KEY}`.                                        |
| `LINEAR_TEAM_ID`       | Team UUID for non-interactive `init`.                                                                                         |
| `LINEAR_HTTP_TIMEOUT`  | HTTP client timeout in Go duration form (e.g. `30s`, `1m`, `45s`). Default `30s`. Clamped to `[1s, 5m]`; out-of-range or unparseable values fall back to the default with a stderr warning. |

See [CHANGELOG.md](./CHANGELOG.md) for what's new.
