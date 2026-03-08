# logfire-trace

Go CLI for downloading and visualizing Logfire traces with a focus on AI/LLM spans.

## When to use it

You have AI agent traces in [Pydantic Logfire](https://logfire.pydantic.dev/) and need to download, inspect, or replay them locally. logfire-trace (aliased `lft`) fetches traces, renders conversation summaries and span trees, and can replay recorded conversations against live provider APIs for prompt iteration and A/B testing.

- `lft get <trace_id>` -- download trace to local JSON
- `lft get -s <trace_id>` -- human-readable conversation summary
- `lft replay trace.json` -- re-send the last turn against the live API
- `lft replay trace.json -n 3` -- generate 3 variations for comparison

## Install

```bash
eget svilupp/go-utils-depot --tag 'logfire-trace/*' --to ~/.local/bin

# Create short alias
alias lft='logfire-trace'
```

## Quick start

```bash
# Interactive setup
lft init

# Or set token directly
export LOGFIRE_READ_TOKEN=pylf_v1_...

# Download trace
lft get <trace_id>

# Conversation summary
lft get -s <trace_id>

# Span tree
lft get -t <trace_id>

# Replay last turn
lft replay logs/trace_abc123.json
```

## Commands

| Command | Description |
|---------|-------------|
| `lft get <trace_id>` | Download trace (and linked chat) to logs/ |
| `lft get -c <chat_id>` | Download chat (and linked trace) to logs/ |
| `lft get -u <email>` | Download latest chat for user (requires Firestore config) |
| `lft get -s <trace_id>` | View conversation summary |
| `lft get -t <trace_id>` | View span tree |
| `lft replay <source>` | Replay a recorded conversation against a live API |
| `lft query <sql>` | Run custom SQL query |
| `lft check` | Validate config and test API |
| `lft init` | Interactive setup |

## Configuration

Config file: `~/.config/logfire-trace/config.yaml`

```yaml
default_profile: prod

profiles:
  prod:
    token: ${LOGFIRE_PROD_TOKEN}
    region: us
    org: my-org
    project: my-project

ai_patterns:
  - "ai.*"
  - "agent.*"
  - "guardrails.*"

# Optional: for replay command
ai_providers:
  anthropic:
    api_key: ${ANTHROPIC_API_KEY}
  google:
    api_key: ${GOOGLE_API_KEY}

# Optional: for --chat / --user flags (Firestore integration)
firestore:
  enabled: true
  project_uat: my-gcp-project-uat
  project_prod: my-gcp-project
  database: my-database
  chats_collection: ai-chats
  users_collection: users
```

Full usage guide: [docs/SKILL.md](docs/SKILL.md)
