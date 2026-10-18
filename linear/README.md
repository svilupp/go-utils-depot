# Linear CLI

A simple CLI for working with Linear tickets and comments — built for humans and AI agents.

- **Read, create, update, comment** on tickets without touching GraphQL
- **Multi-workspace profiles** so one user can switch between work, personal, etc.
- **Safe by default** — workspace guard refuses cross-workspace writes

## Install

```bash
eget svilupp/go-utils-depot --tag 'linear/v0.16.0' --to ~/.local/bin
```

## Quick start

```bash
linear init                # configure your first profile
linear get ENG-123
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
| `issues list`  | List issues; labels/state (or `--state-not`)/assignee/`--team`, created/updated-time windows, cursor pagination, JSON |
| `comment`      | Manage comments: `list`, `get`, `edit`, `delete`, `upsert`, or post inline                     |
| `favorite`     | `add` / `remove` / `list` the viewer's favorited issues                                        |
| `relate`       | Create (`--blocks`/`--blocked-by`/`--related`/`--duplicate-of`) or `--remove` an issue relation |
| `relations`    | List an issue's relations (blocks, blocked by, related, duplicate); `--json`                   |
| `me`           | Print the authenticated viewer (id, email, name, organization); `--json`                       |
| `profile`      | `list` / `show` configured profiles                                                            |

`comment list` also accepts `--since <RFC3339>` (server-side time filter) and
`--exclude-user <uuid>` (repeatable, client-side). `comment upsert <issue>` is
an atomic find-or-create matched by `--marker` prefix; the marker is
auto-prepended to the body when missing so subsequent calls match and edit in
place instead of duplicating.

`relate <issue> --blocks <issue>` creates a Linear `issueRelation`;
`--blocked-by` is normalized to the equivalent `blocks` relation with the
two issues swapped (Linear has no native "blocked_by" type). Use
`linear relations <issue>` to find a relation's id, then
`linear relate <issue> --remove <relation-id>` to delete it. Both `relate`
actions are workspace-guarded mutations and support `--dry-run --json`.

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
    workspace_key: example-workspace           # pinned by `linear init`
    agent_marker: linear-agent-...    # generated, keep private
    stakeholders:
      reviewer: 11111111-1111-1111-1111-111111111111
  personal:
    api_key: ${LINEAR_API_KEY_PERSONAL}   # env vars expanded at load
    team_id: <team-uuid>
    workspace_key: example-personal
    agent_marker: linear-agent-...
```

Active profile resolution: `--profile <name>` > `LINEAR_PROFILE` > `default_profile` > sole profile > legacy `linear:` block.

`stakeholders` maps friendly names to user UUIDs. Used by `--assignee <name>` and `comment list --author <name>`.

## Examples

```bash
# Read
linear get ENG-123 --summary
linear get ENG-123 --json
linear get ENG-123 --field parent.identifier

# Create / update
linear create "Bug: login broken" --parent ENG-123 --label bug
linear create "Data pipeline spike" --team ENG --estimate 5
linear update ENG-123 --state QA --priority 2 --assignee reviewer
linear update ENG-123 --remove-label workflow:done
linear update ENG-123 --estimate 3
linear update ENG-123 --team ENG --state Triage   # state resolves against the new team

# Comments
linear comment ENG-123 "ack"                          # inline post
linear comment list DEMO-15 --json --limit 50
linear comment list DEMO-15 --json --filter-prefix "## Workpad"
linear comment list DEMO-15 --json --since 2026-05-24T10:00:00Z --exclude-user <bot-uuid>
linear comment upsert DEMO-15 --marker "## Workpad" --body-file workpad.md --json
linear comment edit <comment-id> --body-file new.md
linear comment delete <comment-id> --yes

# Relations
linear relate ENG-288 --blocks ENG-286
linear relate ENG-286 --blocked-by ENG-288          # equivalent to the line above
linear relate ENG-288 --duplicate-of ENG-290 --json
linear relations ENG-288 --json
linear relate ENG-288 --remove <relation-id>

# Discovery
linear issues list --label workflow:active --state Todo --json
linear issues list --updated-since 2026-05-24T10:00:00Z \
  --updated-before 2026-05-24T11:00:00Z --limit 10 --json
linear me --json

# Teams / projects / labels / users
linear teams list --json
linear projects list --team ENG --json
linear labels list --team ENG --json
linear users list --json

# Projects
linear project create "Q3 Search Revamp" --team ENG --lead me
linear project create "Data pipeline" --team ENG --team "Data Platform" \
  --description "Migrate ingestion" --dry-run --json
```

`issues list --json` returns a paginated envelope:

```json
{
  "issues": [
    {"id":"...","identifier":"DEMO-42","title":"...",
     "state":{"name":"Todo","type":"unstarted"},
     "labels":["workflow:active"],"url":"...","updatedAt":"...",
     "createdAt":"...","team":{"id":"...","key":"ENG","name":"Engineering"}}
  ],
  "cursor": null
}
```

`--state-not <name>` (repeatable) excludes workflow states server-side and is
mutually exclusive with `--state`. `--team <key>` (repeatable) scopes to team
key(s), overrides the profile's configured team, and is mutually exclusive with
`--all-teams`. `--created-before` / `--created-after` filter by `createdAt`
(RFC3339 or bare `YYYY-MM-DD`, UTC midnight); `--created-before` is exclusive,
`--created-after` is inclusive.

When `cursor` is non-null, pass it back via `--cursor <value>` for the next page.
`--updated-since` is an exclusive `updatedAt` lower bound and
`--updated-before` is an inclusive upper bound. Keep both unchanged while
following a cursor; `issues list` explicitly orders the connection by
`updatedAt`, making the page cursor resumable for a frozen polling window.

Identifiers accept either form: `ENG-123` or the full Linear URL.

## For agents / scripts

Pass `--error-json` to get a stable JSON envelope on stderr and branch on `code`:

```json
{"status":"error","code":"ISSUE_NOT_FOUND","message":"...","details":{"identifier":"ENG-9999"}}
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

The CLI detects Codex, Claude, and Pi from the same environment and Linux
process ancestry signals as `agent-playbooks`. Automated wrappers can set `LINEAR_CALLER=agent`.

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
| `LINEAR_CALLER`        | Provenance override: `auto`, `human`, `agent`, `codex`, `claude`, or `pi`. Default `auto`.                          |
| `LINEAR_API_KEY`       | API key for non-interactive `init`. Also referenced from YAML via `${LINEAR_API_KEY}`.                                        |
| `LINEAR_TEAM_ID`       | Team UUID for non-interactive `init`.                                                                                         |
| `LINEAR_HTTP_TIMEOUT`  | HTTP client timeout in Go duration form (e.g. `30s`, `1m`, `45s`). Default `30s`. Clamped to `[1s, 5m]`; out-of-range or unparseable values fall back to the default with a stderr warning. |

See [CHANGELOG.md](./CHANGELOG.md) for what's new.
