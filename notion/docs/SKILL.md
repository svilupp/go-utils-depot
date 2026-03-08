---
name: notion-cli
description: Interact with the Notion API — search, read, create, and update pages, blocks, databases, data sources, users, and comments. Use when you need to read or modify Notion workspace content, query structured rows, or manage Notion pages programmatically.
---

# Notion CLI

CLI for the Notion API with saved multi-workspace profiles, API keys, and OAuth.

## When to Use

- **Read Notion content**: fetch pages, blocks, data source schemas, users, and comments
- **Search**: find pages and data sources by keyword
- **Create/update**: create pages, append blocks, update properties
- **Query data sources**: filter and sort structured data (replaces old database queries)
- **Multi-workspace**: switch between workspaces via named profiles

## First Move

```bash
# One-time setup: make hosted MCP the default profile
notion auth login --provider mcp --profile work-mcp --set-default

# Search
notion search "meeting notes"

# Get a page or full document
notion page get <page_id>
notion page get "https://www.notion.so/Page-Title-1234567890" --format markdown

# Upload blocks to a page
notion block append <page_id> @blocks.json

# Save results
notion search "meeting notes" -o results.json
notion page get "https://www.notion.so/Page-Title-1234567890" --format markdown -o page.md
```

## Quick Reference

| Task | Command |
|------|---------|
| Search | `notion search "query"` |
| Get page or document | `notion page get <id-or-url>` |
| Get page content | `notion block children <id> --all --format markdown` |
| Create page | `notion page create @page.json` |
| Update page | `notion page update <id> '{"properties":{...}}'` |
| Query data source | `notion datasource query <id> @query.json --all` |
| List users | `notion user list` |
| Who am I | `notion user me` |
| Save output | `notion search "query" -o results.json` |

For more, run `notion quickstart`.

## Setup

```bash
# First-time setup
notion init --profile work --workspace-name "Work" --set-default

# OAuth setup for REST commands
notion auth login --provider public --profile work-oauth

# Hosted MCP as the default profile
notion auth login --provider mcp --profile work-mcp --set-default

# Add additional workspace profiles
notion init --profile personal --workspace-name "Personal"

# Or use an environment variable directly
export NOTION_TOKEN=ntn_...
```

## High-Signal Workflows

```bash
# Search
notion search "meeting notes"
notion search "tasks" --filter-type data_source --format table
notion search "meeting notes" -o results.json

# Read a page
notion page get <page_id>
notion page get "https://www.notion.so/Page-Title-1234567890" --format markdown
notion page get "https://www.notion.so/Page-Title-1234567890" --format markdown -o page.md
notion block children <page_id> --all --format markdown

# Exact hosted MCP tool surface
notion mcp tools
notion mcp fetch "https://www.notion.so/Page-Title-1234567890" --format markdown -o fetch.md

# Query structured rows
notion datasource get <data_source_id>
notion datasource query <data_source_id> @query.json --all

# Append content
notion block types
notion block append <page_id> @blocks.json

# Multi-workspace
notion --profile work search "standup"
notion --profile personal page get <page_id>
notion profile list
```

## Agent Notes

- `page get` returns properties and metadata. Use `block children` for actual page content.
- If the default profile is `work-mcp`, plain `notion search ...`, `notion page get <url>`, and `notion mcp ...` all use hosted Notion MCP by default without `--profile`.
- `--all` follows cursor-based pagination and merges paginated list responses.
- Prefer `@file.json` for page create/update, block append, and data source create/update payloads.
- `search --filter-type database` is accepted as an alias for `data_source`.
- `notion block types` is the fastest way to get valid block payload shapes without hunting through docs.
- Use `notion auth login --provider public` to preserve the REST command surface with OAuth.
- `notion auth login --provider mcp` enables the hosted MCP command surface (`notion mcp ...`) plus MCP-backed aliases like `search` and `page get <url>`; legacy REST commands still require the compatibility probe to succeed.
- Use `-o, --output` to save search results, markdown page fetches, or MCP output to files.
