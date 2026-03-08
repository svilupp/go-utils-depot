# Notion CLI

CLI for the Notion API. Search, read, create, and update pages, blocks, data sources, users, and comments across multiple workspaces.

## When to use it

You interact with Notion workspaces — searching for pages, reading content, updating properties, appending blocks, or querying structured data. This CLI covers the full Notion API surface including hosted MCP, with saved profiles for switching between workspaces.

## Install

```bash
eget svilupp/go-utils-depot --tag 'notion/*' --to ~/.local/bin
```

## Quick start

```bash
# One-time setup: hosted MCP as default profile
notion auth login --provider mcp --profile work-mcp --set-default

# Search your workspace
notion search "meeting notes"

# Get a page as markdown
notion page get "https://www.notion.so/Page-Title-abc123" --format markdown

# Append blocks to a page
notion block append <page_id> @blocks.json

# Save output to file
notion search "meeting notes" -o results.json
```

For an interactive guide: `notion quickstart`

## Commands

| Command | What it does |
|---------|-------------|
| `search` | Find pages and data sources by keyword |
| `page` | Read/create/update page properties |
| `block` | Read/append/update/delete page content blocks |
| `datasource` | Inspect schemas and query structured rows |
| `database` | Legacy database metadata |
| `user` | Workspace users and authenticated bot |
| `comment` | List or create comments |
| `init` | Create or update auth profiles |
| `auth` | Log in, refresh, or log out OAuth profiles |
| `mcp` | Hosted Notion MCP tool surface (1:1 parity) |
| `profile` | List, switch, and remove saved profiles |
| `quickstart` | Interactive overview of CLI and Notion object model |

## Profiles & auth

Config: `~/.config/notion/config.yaml`

Three auth modes per profile:
- `api_key` — API token (supports `${ENV_VAR}` expansion)
- `public_oauth` — OAuth with browser flow
- `mcp_oauth` — Hosted MCP OAuth (recommended default)

```bash
notion init --profile work --workspace-name "Work" --set-default
notion auth login --provider mcp --profile work-mcp --set-default
notion profile switch personal
notion profile list
```

## Docs

- [Full usage guide](docs/SKILL.md) — all commands, workflows, agent notes
