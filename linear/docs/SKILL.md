---
name: linear-cli
description: Fetch, create, and comment on Linear tickets from the command line. Use when reading issue details, creating tickets, or posting comments to Linear.
---

# Linear CLI

CLI for Linear API operations — fetch tickets, create issues, add comments.

## First Move

```bash
# One-time setup
linear init

# Fetch a ticket
linear get AGI-123 -s

# Create a ticket
linear create "Bug: Login broken" -p 2

# Add a comment
linear comment AGI-123 "Status update: investigating"
```

## Commands

### init — Configure credentials

```bash
linear init                         # Interactive wizard
linear init --api-key "$KEY"        # Set API key directly
linear init --non-interactive       # Use LINEAR_API_KEY env var
```

### get — Fetch a ticket

```bash
linear get AGI-123 -s               # Summary to stdout
linear get AGI-123 -o ticket.json   # Save JSON to file
linear get "https://linear.app/.../issue/AGI-123/..." -s  # URL works too
```

### create — Create a ticket

```bash
linear create "Fix auth flow"                          # Title only
linear create "Fix auth flow" -d "Steps to reproduce"  # With description
linear create "Fix auth flow" -f description.md         # Description from file
linear create "Fix auth flow" -p 1                      # Priority: 1=urgent 2=high 3=normal 4=low
```

### comment — Add a comment

```bash
linear comment AGI-123 "Done, see PR #42"       # Inline
linear comment AGI-123 -m "Done, see PR #42"    # Flag
linear comment AGI-123 -f update.md             # From file
```

## Configuration

Config file: `~/.config/linear/config.yaml`

```yaml
linear:
  api_key: ${LINEAR_API_KEY}
  team_id: your-team-uuid
  user_id: your-user-uuid
```

Values support `${VAR}` expansion. Environment fallbacks: `LINEAR_API_KEY`, `LINEAR_TEAM_ID`, `LINEAR_USER_ID`.

## Identifier Formats

Both work for `get` and `comment`:
- `AGI-123`
- `https://linear.app/.../issue/AGI-123/...`
