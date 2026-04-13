---
name: linear-cli
description: Fetch, create, update, and comment on Linear tickets from the command line. Use when reading issue details, creating tickets, updating issue fields, or posting comments to Linear.
---

# Linear CLI

CLI for Linear API operations — fetch tickets, create issues, update fields, add comments.

## First Move

```bash
# One-time setup
linear init

# Fetch a ticket
linear get AGI-123 -s

# Create a ticket
linear create "Bug: Login broken" -p 2

# Update a ticket
linear update AGI-123 --state QA --priority 2

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
linear get AGI-123 --json           # Full issue JSON to stdout
linear get AGI-123 --field parent.identifier  # Extract one field
linear get AGI-123 -o ticket.json   # Save JSON to file
linear get "https://linear.app/.../issue/AGI-123/..." -s  # URL works too
```

Summary (`-s`) includes team, project, parent, and internal issue UUID.

### create — Create a ticket

```bash
linear create "Fix auth flow"                          # Title only
linear create "Fix auth flow" -d "Steps to reproduce"  # With description
linear create "Fix auth flow" -f description.md        # Description from file
linear create "Fix auth flow" -p 1                     # Priority: 1=urgent 2=high 3=normal 4=low
linear create "Bug: Login broken" --parent AGI-123     # Child of another issue
linear create "Bug" --state QA --assignee me --project "Sprint 42" --label bug
linear create "Bug" --json                             # Print created issue JSON
linear create "Bug" --dry-run                          # Resolve inputs, print request, don't create
```

Flags: `--parent`, `--state`, `--assignee`, `--project`, `--label` (repeatable), `--json`, `--dry-run`.

### update — Update an existing ticket

```bash
linear update AGI-123 --state QA --priority 2
linear update AGI-123 --title "New title" -d "Updated description"
linear update AGI-123 --parent AGI-100                  # Set parent
linear update AGI-123 --clear-parent                    # Remove parent
linear update AGI-123 --label bug --label regression    # Add labels
linear update AGI-123 --clear-labels                    # Remove all labels
linear update AGI-123 --assignee me
linear update AGI-123 --json                            # Print updated issue JSON
linear update AGI-123 --dry-run                         # Resolve inputs, print request, don't update
```

Flags: `--title`, `-d/--description`, `-f/--file`, `--parent`, `--clear-parent`, `--state`, `-p/--priority` (0=none, 1=urgent..4=low), `--assignee`, `--project`, `--label` (repeatable), `--clear-labels`, `--json`, `--dry-run`.

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

Both work for `get`, `update`, `comment`, and parent references:
- `AGI-123`
- `https://linear.app/.../issue/AGI-123/...`
