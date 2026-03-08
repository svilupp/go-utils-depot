# Linear CLI

CLI for the Linear API. Fetch, create, and comment on tickets.

## When to use it

You work with Linear tickets — fetching issue details, creating new tickets, or adding comments. Works with both issue IDs (`AGI-123`) and full Linear URLs. Designed for both interactive use and scripted/agent workflows.

## Install

```bash
eget svilupp/go-utils-depot --tag 'linear/*' --to ~/.local/bin
```

## Quick start

```bash
# Configure (prompts for API key, team, user)
linear init

# Fetch a ticket as formatted summary
linear get AGI-123 -s

# Create a ticket
linear create "Bug: Login broken" -f description.md -p 2

# Add a comment
linear comment AGI-123 "Status update: investigating"
```

## Commands

| Command | What it does |
|---------|-------------|
| `init` | Configure API key, team ID, user ID |
| `get` | Fetch a ticket (JSON or summary format) |
| `create` | Create a new ticket |
| `comment` | Add a comment to a ticket |

## Key flags

| Command | Flag | Description |
|---------|------|-------------|
| `get` | `-s, --summary` | Print summary to stdout |
| `get` | `-o, --output` | Save to file |
| `create` | `-d, --description` | Issue description |
| `create` | `-f, --file` | Read description from file |
| `create` | `-p, --priority` | Priority (1=urgent, 2=high, 3=normal, 4=low) |
| `comment` | `-m, --message` | Comment message |
| `comment` | `-f, --file` | Read comment from file |

## Configuration

Config: `~/.config/linear/config.yaml`

```yaml
linear:
  api_key: lin_api_xxx
  team_id: your-team-uuid
  user_id: your-user-uuid
```

Environment fallbacks: `LINEAR_API_KEY`, `LINEAR_TEAM_ID`, `LINEAR_USER_ID`.

For CI: `linear init --non-interactive` (requires `LINEAR_API_KEY`).

## Identifier formats

Both work for `get` and `comment`:
- Direct: `AGI-123`
- URL: `https://linear.app/.../issue/AGI-123/...`
