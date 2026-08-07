# logfire-trace

Go CLI for downloading and visualizing Logfire traces with a focus on AI/LLM spans.

## When to use it

You have AI agent traces in [Pydantic Logfire](https://logfire.pydantic.dev/) and need to download, inspect, or replay them locally. logfire-trace (aliased `lft`) fetches traces, renders conversation summaries and span trees, and can replay recorded conversations against live provider APIs for prompt iteration and A/B testing.

- `lft get <trace_id>` -- download trace to local JSON
- `lft get -s <trace_id>` -- human-readable conversation summary
- `lft replay trace.json` -- re-send the last turn against the live API
- `lft replay <chat_id>` -- replay a Firestore chat directly (auto-detected source)
- `lft replay <chat.json> --recipe <trace_id>` -- replay a chat with model/tools/settings from a sibling trace
- `lft replay trace.json --request-overrides-file bundle.json` -- replay through a provider-neutral, policy-pinned bundle
- `lft replay trace.json --output-dir .replays/` -- write one redacted `lft.replay.receipt/v2` per attempt
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

# Save replay receipts (one JSON per provider attempt)
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
  openrouter:
    api_key: ${OPENROUTER_API_KEY}

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

Pass `--output-dir <DIR>` (env `LFT_OUTPUT_DIR`) when you'll want to look at a replay again — prompt iteration, model comparison, noise sampling. Each provider attempt drops one redacted, hashed `lft.replay.receipt/v2` JSON into the folder; v1 receipts remain readable.

```bash
export LFT_OUTPUT_DIR=.replays/
lft replay logs/trace_abc123.json
lft replay logs/trace_abc123.json --temperature 0.7
jq -r '.input_sha + " " + .input.model' .replays/*.json | sort | uniq -c
```

Receipts include status/error class, timeout and cost state, semantic span metadata, redaction counts, bundle provenance, component hashes, and an `input_sha` fingerprint. Same `source_trace_id` + same `input_sha` = noise samples; different `input_sha` = a variant.

## Replay flags

| Flag | Purpose |
|---|---|
| `--recipe <trace_id\|path>` | Trace supplying model/tools/settings; auto-discovered from chat metadata when omitted |
| `--model <name>` | Override model (replaces `--model-override`; old name kept as deprecated alias) |
| `--provider <name>` | Force provider routing, used verbatim; skips model-prefix inference. One of `anthropic`, `google`, `openai`, `openrouter` |
| `--fusion` | Route through OpenRouter Fusion (≡ `--model openrouter/fusion`): a panel answers, a judge synthesizes. Billable |
| `--fusion-panel <a,b,c>` | Custom Fusion analysis models (CSV); implies `--fusion` |
| `--fusion-judge <model>` | Custom Fusion judge; implies `--fusion` |
| `--fusion-max-tokens <int>` | Custom Fusion max completion tokens; implies `--fusion` |
| `--system-file <path>` | Override system prompt from text file |
| `--temperature <float>` | Override generation temperature (omit to keep recorded value) |
| `--format ai-sdk\|pydantic-ai` | Force replay source format; default auto-detect. Use if extraction looks wrong or no adapter matches |
| `--reasoning-effort low\|medium\|high` | CLI-only; not stored in span data |
| `--max-output-tokens <int>` | Override max output tokens (omit to keep recorded value) |
| `--skip-tools` | Run without tools; emits permanent stderr warning |
| `--tools-file <path>` | Override tool definitions from JSON |
| `--output-dir <DIR>` | Append a `lft.replay.receipt/v2` JSON to `<DIR>` for every provider attempt |
| `--run-id <STRING>` | Optional grouping tag stamped on receipts |
| `--dry-run` / `--dry-run --json` | Print resolved `ReplayConfig` with per-field provenance and exit |
| `--request-overrides-file <FILE>` | Load a provider-neutral, secret-free, allowlisted request bundle |
| `--attempt-timeout <DURATION>` | Bound each provider attempt (default `3m`) |
| `--total-timeout <DURATION>` | Bound the complete replay run (`0` disables) |
| `--allow-ambiguous-span` | Permit numeric span indices for debugging; stable IDs are preferred |

Full usage guide: [docs/logfire-trace-cli/SKILL.md](docs/logfire-trace-cli/SKILL.md) · Replay guide: [docs/replaying-logfire-conversations/SKILL.md](docs/replaying-logfire-conversations/SKILL.md)
