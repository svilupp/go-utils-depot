# logfire-trace

Go CLI for downloading and visualizing Logfire traces with a focus on AI/LLM spans.

## When to use it

You have AI agent traces in [Pydantic Logfire](https://logfire.pydantic.dev/) and need to download, inspect, or replay them locally. logfire-trace (aliased `lft`) fetches traces, renders conversation summaries and span trees, and can replay recorded conversations against live provider APIs for prompt iteration and A/B testing.

- `lft get <trace_id>` -- download trace to local JSON
- `lft get -s <trace_id>` -- human-readable conversation summary
- `lft replay trace.json` -- re-send the last turn against the live API
- `lft replay <chat_id>` -- replay a Firestore chat directly (auto-detected source)
- `lft replay <chat.json> --recipe <trace_id>` -- replay a chat with model/tools/settings from a sibling trace
- `lft replay trace.json --output-dir .replays/` -- write a `lft.replay.receipt/v1` JSON per invocation
- `lft replay trace.json --dry-run` -- print the resolved `ReplayConfig` with per-field provenance and exit

## Install

```bash
eget svilupp/go-utils-depot --tag 'logfire-trace/' --to ~/.local/bin

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

# Replay a Firestore chat with a recipe trace
lft replay <chat_id> --recipe logs/trace_abc123.json

# Save replay receipts (one JSON per invocation)
lft replay logs/trace_abc123.json --output-dir .replays/
```

## Commands

| Command | Description |
|---------|-------------|
| `lft get <trace_id>` | Download trace (and linked chat) to logs/ |
| `lft get -c <chat_id>` | Download chat (and linked trace) to logs/ |
| `lft get -u <email>` | Download latest chat for user (requires Firestore config) |
| `lft get -s <trace_id>` | View conversation summary |
| `lft get -t <trace_id>` | View span tree |
| `lft replay <source>` | Replay a recorded conversation against a live API (trace ID, chat ID, trace JSON, or chat JSON; auto-detected) |
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

## Replay receipts

Pass `--output-dir <DIR>` (env `LFT_OUTPUT_DIR`) when you'll want to look at a replay again — prompt iteration, model comparison, noise sampling. Each invocation drops one self-contained `lft.replay.receipt/v1` JSON into the folder; the directory is append-only and stays cluster-friendly.

```bash
export LFT_OUTPUT_DIR=.replays/
lft replay logs/trace_abc123.json
lft replay logs/trace_abc123.json --temperature 0.7
jq -r '.input_sha + " " + .input.model' .replays/*.json | sort | uniq -c
```

Receipts include an `input_sha` fingerprint of the rendered request (model, system, messages, tools, params). Same `source_trace_id` + same `input_sha` = noise samples; different `input_sha` = a variant. `logfire-viewer` ingests `--output-dir` directories at `/replays` with auto-clustering and a side-by-side prompt-diff compare view.

## Replay flags

| Flag | Purpose |
|---|---|
| `--recipe <trace_id\|path>` | Trace supplying model/tools/settings; auto-discovered from chat metadata when omitted |
| `--model <name>` | Override model (replaces `--model-override`; old name kept as deprecated alias) |
| `--system-file <path>` | Override system prompt from text file |
| `--temperature <float>` | Override generation temperature |
| `--reasoning-effort low\|medium\|high` | CLI-only; not stored in span data |
| `--max-output-tokens <int>` | Override max output tokens |
| `--skip-tools` | Run without tools; emits permanent stderr warning |
| `--tools-file <path>` | Override tool definitions from JSON |
| `--output-dir <DIR>` | Append a `lft.replay.receipt/v1` JSON to `<DIR>` for every invocation |
| `--run-id <STRING>` | Optional grouping tag stamped on receipts |
| `--dry-run` / `--dry-run --json` | Print resolved `ReplayConfig` with per-field provenance and exit |

Full usage guide: [docs/SKILL.md](docs/SKILL.md)
