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

## Commands

| Command   | What it does                                                    |
| --------- | --------------------------------------------------------------- |
| `init`    | Create or update a profile                                      |
| `get`     | Fetch a ticket; `--json` or `--field <path>` for scripts         |
| `create`  | New ticket; supports `--parent`, `--label`, `--project`          |
| `update`  | Edit ticket fields (state, priority, assignee, labels, parent)   |
| `comment` | Manage comments: `list`, `get`, `edit`, `delete`, or post inline |
| `profile` | `list` / `show` configured profiles                              |

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
    stakeholders:
      jan: 11111111-1111-1111-1111-111111111111
  personal:
    api_key: ${LINEAR_API_KEY_PERSONAL}   # env vars expanded at load
    team_id: <team-uuid>
    workspace_key: jan-personal
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
linear comment edit <comment-id> --body-file new.md
linear comment delete <comment-id> --yes
```

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

Always pass `--profile <name>` explicitly in agent flows so the transcript shows which workspace was targeted.

## CI / non-interactive

```bash
LINEAR_API_KEY=lin_api_xxx LINEAR_TEAM_ID=<uuid> \
  linear init --non-interactive --profile-name ci
```

Env-var references (`${LINEAR_API_KEY}`) are expanded at load time, so the YAML can stay secret-free.

See [CHANGELOG.md](./CHANGELOG.md) for what's new.
