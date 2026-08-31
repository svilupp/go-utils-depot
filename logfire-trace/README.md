# logfire-trace

Go CLI for downloading Logfire traces, inspecting AI spans, and replaying recorded provider requests.

## Installation

```bash
eget svilupp/go-utils-depot --tag 'logfire-trace/' --to ~/.local/bin

# Optional alias
alias lft='logfire-trace'
```

## Quick Start

```bash
# Set token (or use config file)
export LOGFIRE_READ_TOKEN=pylf_v1_...

# Fetch once into a durable investigation folder. JSON is printed to stdout and
# the saved path is reported on stderr.
logfire-trace get <trace_id> --all --output-dir logs/investigation/ > /dev/null

# Reuse that local file; these commands do not download the trace again.
logfire-trace replay logs/investigation/trace_<id>.json --inspect | jq '{replayable, selected_span}'
logfire-trace replay logs/investigation/trace_<id>.json --inspect --human

# Add `--human --tree > report.txt` to that initial fetch when a text tree is useful;
# the JSON capture is still saved alongside it.

# Replay the last assistant turn
logfire-trace replay logs/investigation/trace_<id>.json
```

## Replay

`logfire-trace replay` rebuilds a provider request from a recorded generation span. It is intended for prompt debugging, regression checks, and cross-run comparisons without re-running the full application.

### Replay Receipts

Live replay attempts are automatically saved as one self-contained JSON receipt per provider attempt in `./logs/replay/`. Set `replay_output_dir` in config, or pass `--output-dir <DIR>` (or `LFT_OUTPUT_DIR`) to choose another folder. Inspection and dry-run modes never create receipts.

If you'll save more than once in a session, set `LFT_OUTPUT_DIR` once and forget about it:

```bash
export LFT_OUTPUT_DIR=logs/replay/
```

New receipts use schema `lft.replay.receipt/v2` (v1 remains readable) and include classified status/error, timeout, usage/cost state, redaction counts, semantic span metadata, bundle provenance, and component hashes alongside `input_sha`.

```bash
jq -r '.input_sha + " " + .input.model' logs/replay/*.json | sort | uniq -c
```

Receipts are just JSON on disk, useful on their own and easy to feed into whatever you read them with later.

### Shortest Safe Workflow

```bash
logfire-trace replay <source> --list-replay-spans
logfire-trace replay <source> --turns
logfire-trace replay <source> --inspect
logfire-trace replay <source> --respond-to turn:0.user
```

`<source>` can be:

- a local trace JSON file
- a Logfire URL
- a 32-character trace ID
- `-c <chat_id>` (alias: `--chat`)
- `--conversation <conversation_id>`

## Output and configuration

Fetch commands always save JSON. The default paths are relative to the current
working directory: `logs/trace_<id>.json` and `logs/chat_<id>.json`. Use
`--output FILE` or `--output-dir DIR` when you want an explicit investigation
folder, then analyze the saved file repeatedly instead of downloading again.
The path is reported on stderr, while stdout remains a single machine-readable
JSON value unless `--human` is requested.

See [`docs/output-contract.md`](docs/output-contract.md) for the stable JSON
shapes and save-location precedence.
See [`docs/migration-v0.17.md`](docs/migration-v0.17.md) for the breaking
changes and upgrade steps from 0.16.

Configure the two destinations independently:

```yaml
output_dir: logs
replay_output_dir: logs/replay
```

Relative paths are resolved from the invocation directory. Fetch flags override
`output_dir`; replay `--output-dir`, then `LFT_OUTPUT_DIR`, override
`replay_output_dir`. `--output` on replay remains the optional aggregate result
file and may be used together with receipt output.

### Canonical Selectors

Public replay selectors are turn-safe:

- `system`
- `turn:N.user`
- `turn:N.tool:M`
- `turn:N.response`

Examples:

```text
system
turn:0.user
turn:0.tool:0
turn:0.response
turn:1.user
turn:1.tool:0
turn:1.response
```

Compatibility aliases such as `last`, `user:N`, `assistant:N`, `tool:N`, and `msg:N` are still accepted, but docs and generated commands prefer canonical turn selectors.

### Actions

Replay now separates non-structural rewrites from structural replay:

| Action | Meaning | Typical targets |
|--------|---------|-----------------|
| `--rewrite TARGET -i FILE` | Replace content in place while preserving transcript shape | `system`, `turn:N.user`, `turn:N.response` |
| `--respond-to TARGET` | Keep `TARGET`, drop everything after it, and ask for the next assistant step | `turn:N.user`, `turn:N.tool:M` |
| `--regenerate TARGET` | Remove `TARGET` and replay from the previous boundary | `turn:N.response`, `last` |
| `--forward-from A --through B` | Replay dependent assistant responses sequentially from boundary `A` through boundary `B` | `turn:N.user`, `turn:N.tool:M` |
| `--replace TARGET -i FILE` | Legacy rewrite+truncate behavior kept temporarily for compatibility | `user:N`, `assistant:N`, `system`, `last` |

### Safe Semantics

Use `--rewrite` when you want to mutate history without pretending later turns are still valid:

```bash
logfire-trace replay trace.json \
  --rewrite system -i prompt.txt \
  --respond-to turn:0.tool:0
```

Use `--regenerate` when the selected terminal response itself is what you want to re-run:

```bash
logfire-trace replay trace.json --regenerate turn:1.response
```

Use `--forward-from/--through` when earlier assistant behavior contaminates later turns:

```bash
logfire-trace replay trace.json \
  --rewrite system -i prompt.txt \
  --forward-from turn:0.tool:0 \
  --through turn:2.tool:0
```

Forward replay reuses newly generated earlier assistant responses as history for later steps. It skips intermediary turns that have no terminal assistant response, and it still generates the final `--through` step even when the trace currently ends at that boundary.

### Span Selection

Many traces contain multiple generation spans. Replay now scores them and picks a default, but you can inspect and override that choice.

```bash
logfire-trace replay logs/trace2.json --list-replay-spans
logfire-trace replay logs/trace2.json --span <span_id> --inspect
logfire-trace replay logs/trace2.json --span <span_id> --turns
```

The default ranking prefers:

1. non-guardrail / non-classifier spans
2. spans with more prompt messages
3. spans with tool definitions and chat/conversation cross references
4. later timestamps only as a tie-breaker

### Turn Inspection

`--turns` is intended to be actionable, not just descriptive:

```bash
logfire-trace replay logs/trace3.json --turns
```

It shows:

- the selected source span
- the canonical turn graph
- raw alias mappings such as `user:1`, `tool:0`, and `msg:5`
- unwrapped `user_input` text when the raw message is a transcription wrapper
- explicit markers for synthetic server-update turns so you do not mistake them for the shopper's first message
- response boundaries that are safe for `--respond-to` / `--regenerate`
- a concrete command to run

### Inspect Without Sending

```bash
logfire-trace replay logs/trace3.json --inspect
logfire-trace replay logs/trace3.json --respond-to turn:1.tool:0 --dry-run | jq '.preflight'
```

`--inspect` emits a structured JSON inspection by default and normalizes compatibility aliases like
`msg:N` back to canonical `turn:*` labels. Add `--human` for the readable report.

Replay JSON now includes an `inspection` object with:

- selected span
- rewrites
- forward replay steps
- request roles
- last request role
- replayable / non-replayable classification
- warning messages
- suggested canonical commands
- model, provider, and tool count

For `--forward-from ... --dry-run`, inspect `preflight` and `would_call`; dry-run validates the
sequential replay plan but does not synthesize per-step `results`.

### Multi-Turn Shopping Example

Real shopping traces often look like:

```text
turn:12.user       "Any pink hoodies?"
turn:12.tool:0     product_search results
turn:12.response   "Here are three options"
turn:13.user       "Show me the second one"
turn:13.tool:0     product details
turn:13.response   "This one's cropped..."
```

Useful commands:

```bash
# Re-run the assistant answer after the tool result
logfire-trace replay trace.json --respond-to turn:13.tool:0

# Re-run the assistant answer itself
logfire-trace replay trace.json --regenerate turn:13.response

# Clean a prompt and replay a later turn without deleting middle history
logfire-trace replay trace.json --rewrite system -i prompt.txt --respond-to turn:13.tool:0

# Clean the prompt and replay forward from the earliest contaminated boundary
logfire-trace replay trace.json \
  --rewrite system -i prompt.txt \
  --forward-from turn:12.tool:0 \
  --through turn:13.tool:0
```

### Common Failure Modes

1. Rewriting the system prompt and replaying a later turn while earlier assistant replies still encode the old behavior.
2. Empty or unhelpful replay because the rebuilt request ends on `assistant` or has no request messages.
3. Wrong source span because the trace contains both guardrail/classifier generations and main-agent generations.
4. Replaying a Firestore chat JSON without a recipe or tool definitions; use a trace source or provide the missing recipe.
5. Assuming middle-turn deletion is safe. It is not.

The tool now catches non-replayable plans before provider calls, warns about contaminated history, and suggests safer canonical commands.

### Explicitly Rejected

Replay intentionally does not support:

- dropping an individual assistant message while keeping later turns
- dropping a tool result while keeping later assistant text
- middle-history hole punching
- rewriting tool-result payloads as free text

If earlier history changes must affect later turns, use `--forward-from` instead of deleting messages.

See [Deprecated Flags](#deprecated-flags) for the legacy `--position` replacement table.

### Chat-First and Conversation-First Replay

```bash
logfire-trace replay -c <chat_id> --list-replay-spans
logfire-trace replay -c <chat_id> --span <span_id> --inspect
logfire-trace replay --conversation test-conv-123 --turns
```

These modes resolve matching traces first, then feed the resulting spans through the same candidate discovery and inspection pipeline. They do not attempt to reconstruct provider requests from Firestore chat documents alone.

### Tools and Model Overrides

```bash
# Override tool schema before replaying
logfire-trace replay trace.json --tools-file tools.json --dry-run | jq '.request.tools'

# Compare providers on the same trace
logfire-trace replay trace.json --model gemini-2.5-flash --output gemini.json
```

`--tools-file` accepts:

- direct arrays of tool objects
- `{"tools":[...]}`
- Gemini `functionDeclarations`
- OpenAI-style `{"type":"function","function":{...}}`

`--no-thinking` is provider-specific. It works cleanly for Anthropic, is best-effort for Gemini 3, is unsupported for Gemini 2.5 Pro, and currently fails for OpenAI `gpt-5.4` / `gpt-5.2` whenever the replay request still includes tool definitions because the replay path still uses `/v1/chat/completions`.

### Chat Replay and Recipe Traces

`replay` accepts chats as well as traces. A chat alone is missing the model, tool definitions, and generation settings — supply them with a recipe trace (or with explicit flags).

```bash
# Replay a chat fixture; recipe is auto-discovered from chat metadata if present
logfire-trace replay logs/chat.json --dry-run

# Replay a chat fixture, supply the recipe explicitly
logfire-trace replay logs/chat.json --recipe 019aabbccdd... --dry-run

# Replay a Firestore chat by ID with an explicit recipe trace
logfire-trace replay <chat_id> --recipe trace.json
```

The chat supplies messages. The recipe supplies model, tools, system prompt, and generation settings. Explicit flags (`--model`, `--tools-file`, `--system-file`, `--temperature`, `--reasoning-effort`, `--max-output-tokens`) override the recipe per field.

#### Source Auto-Detection

The first positional argument is classified by content shape — there is no `--chat` flag for the new path.

| Input | Detection rule | Resolved kind |
|---|---|---|
| 32-char hex matching the trace-ID regex | `traceIDPattern` | trace ID (fetched from API) |
| Shorter alphanumeric ID | doesn't match trace ID, looks Firestore-shaped | chat ID |
| `*.json` containing a JSON array | matches trace dump fixtures | trace JSON file |
| `*.json` object with `conversation` + `metadata.chat_id` | matches conversation fixture | chat JSON file |
| `*.json` object with `trace_id`/`span_id`/`attributes` | single-span dump | trace JSON file |

Ambiguous inputs error out and list the candidate kinds — there are no silent guesses.

#### Replay Flags Reference

| Flag | Argument | Purpose |
|---|---|---|
| `--recipe` | `TRACE_ID|PATH` | Recipe trace supplying model/tools/settings (auto-discovered from chat metadata when omitted) |
| `--model` | `NAME` | Override model |
| `--format` | `ai-sdk\|pydantic-ai` | Force source format detection (default: auto-detect); use when extraction looks wrong or a `NoAdapterError` is raised |
| `--tools-file` | `PATH` | Override tool definitions from JSON file |
| `--system-file` | `PATH` | Override system prompt from text file |
| `--temperature` | `FLOAT` | Override generation temperature |
| `--reasoning-effort` | `low|medium|high` | Reasoning effort (CLI-only; not in span data) |
| `--max-output-tokens` | `INT` | Override max output tokens |
| `--skip-tools` | (bool) | Run replay without tool definitions; emits a permanent stderr warning |
| `--dry-run` | (bool) | Emit resolved `ReplayConfig` with per-field provenance as JSON and exit |
| `--human` | (bool) | Render replay inspection/results as terminal text; JSON remains the default |
| `--json` | (bool) | Deprecated explicit-JSON alias for the default machine output |
| `--output-dir` | `DIR` | Override automatic receipt directory (default `./logs/replay/`, config `replay_output_dir`; env: `LFT_OUTPUT_DIR`) |
| `--run-id` | `STRING` | Optional tag stamped onto receipts to group replays across folders or sessions |
| `--request-overrides-file` | `FILE` | Provider-neutral, secret-free replay override bundle; records model/provider policy and request extensions |
| `--attempt-timeout` | `DURATION` | Per-provider-attempt deadline (default `3m`) |
| `--total-timeout` | `DURATION` | Deadline for the complete replay run (`0` disables) |
| `--yes` | (bool) | Confirm live inference when using an external request override bundle |
| `--allow-ambiguous-span` | (bool) | Permit unstable numeric span indices for debugging; stable span IDs are required otherwise |

#### Recipe Auto-Discovery

When a chat fixture file carries `metadata.trace.primary_trace_id`, the replay command will auto-load that trace as the recipe and print a stderr note:

```
recipe: auto-discovered from chat metadata: 019ddaeb466ff5ca2e...
```

Pass `--recipe` explicitly to override the auto-discovered value.

#### Strict Tools

If the chat contains tool calls but no tool definitions are available (no recipe, no `--tools-file`), replay errors out with the called tool names and remediation hints. To proceed anyway:

> **Warning**: `--skip-tools` runs the replay without tool schemas. Replay quality is degraded and is not 1:1 with production. The CLI emits a stderr warning every time `--skip-tools` is used; this warning cannot be silenced.

#### Dry Run

`--dry-run` for chat or trace replays prints the resolved `ReplayConfig` and per-field provenance as
JSON — where each value came from (chat, recipe, flag, sibling span). Use `--human` for text:

```bash
logfire-trace replay logs/chat.json --recipe 019aabbccdd... --dry-run | jq '.preflight'
logfire-trace replay logs/chat.json --recipe 019aabbccdd... --dry-run --human
```

The `--json` flag remains as a deprecated compatibility alias. Inspection modes never call a
provider and never create replay receipts.

### API Keys

Replay needs provider API keys.

```bash
export ANTHROPIC_API_KEY=sk-ant-...
export GOOGLE_API_KEY=AIza...
```

Or configure them in `~/.config/logfire-trace/config.yaml` under `ai_providers`.

## Query

`logfire-trace query` runs raw SQL against Logfire’s `records` table.

### `--since`

`--since` (default `30d`) is sent to Logfire as the `min_timestamp` API parameter — it does not rewrite or inject SQL into your query at all. The server uses it to prune partitions before scanning, so there are no query-shape restrictions: any SQL you can otherwise run (including `UNION`, subqueries, etc.) works unchanged.

Accepts `h`/`d` units, any value:

- `1h`
- `24h`
- `7d`
- `90d`

### Example Queries

Single-line:

```bash
logfire-trace query -S 7d "SELECT * FROM records WHERE span_name LIKE 'agent.%'"
```

Multiline:

```bash
logfire-trace query -S 30d "
SELECT trace_id,
       attributes->>'chat.id' AS chat_id,
       attributes->>'ai.telemetry.metadata.chatId' AS telemetry_chat_id
FROM records
WHERE attributes->>'layercode.conversation.id' = 'test-conv-123'
   OR attributes->>'conversation.id' = 'test-conv-123'
   OR attributes->>'ai.telemetry.metadata.conversationId' = 'test-conv-123'
ORDER BY start_timestamp DESC
"
```

### Recover a Chat ID from a Conversation ID

```bash
logfire-trace query -S 30d "
SELECT trace_id,
       attributes->>'chat.id' AS chat_id,
       attributes->>'ai.telemetry.metadata.chatId' AS telemetry_chat_id
FROM records
WHERE attributes->>'layercode.conversation.id' = 'test-conv-123'
   OR attributes->>'conversation.id' = 'test-conv-123'
   OR attributes->>'ai.telemetry.metadata.conversationId' = 'test-conv-123'
ORDER BY start_timestamp DESC
"
```

### Conversation Search

```bash
logfire-trace query -S 7d "
SELECT trace_id,
       attributes->>'layercode.conversation.id' AS conversation_id
FROM records
WHERE attributes->>'store.id' = 'abc'
ORDER BY start_timestamp DESC
"
```

## Get

`logfire-trace get` is the primary downloader. It saves traces and chats to `logs/` by default and cross-fetches linked assets when they are discoverable.

```bash
logfire-trace get <trace_id>
logfire-trace get -c <chat_id>
logfire-trace get -u <email>
logfire-trace get -s <trace_id>
logfire-trace get -t <trace_id>
```

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
    description: "Production read-only, us region"

ai_patterns:
  - "ai.*"
  - "agent.*"
  - "guardrails.*"
```

`description` is optional and purely informational — it shows up in `logfire-trace profiles`.

Falls back to `$LOGFIRE_READ_TOKEN` / `$LOGFIRE_TOKEN` (plus `$LOGFIRE_REGION`, `$LOGFIRE_ORG`,
`$LOGFIRE_PROJECT`) when no config file exists and no `--profile`/`-p` was explicitly requested.

### `logfire-trace profiles`

Lists every configured profile (sorted by name) with its token status, source, region/org/project,
and description — without making any API calls:

```bash
logfire-trace profiles          # human-readable table
logfire-trace profiles           # machine-readable JSON by default
logfire-trace profiles --human   # terminal table
```

Use this to see which profiles are usable before picking one with `-p`, e.g.
`logfire-trace get -p staging <trace_id>`. For a full connectivity check of a single profile
(including a live API call), use `logfire-trace check`.

## Misc

Set `LFT_NO_HINTS=1` to disable the occasional TTY-only hint reminders that some commands
print to stderr.

## Deprecated Flags

These still work but are legacy and print a stderr warning; prefer the replacements.

| Deprecated | Replacement |
|---|---|
| `--model-override` | `--model` (cannot be combined with `--model`) |
| `-O` / `--out` | `--output-dir` |
| replay `-o` | `--output` |
| `$LFT_OUT` | `$LFT_OUTPUT_DIR` |
| `--position` | see table below |

### Legacy `--position` mapping

| Legacy | Canonical replacement |
|--------|-----------------------|
| `-p last` | `--regenerate last` |
| `-p assistant:12` | `--regenerate turn:12.response` |
| `-p user:7` | `--respond-to turn:7.user` or `--replace user:7 -i override.txt` |
| `-p system -i prompt.txt` | `--replace system -i prompt.txt` |

## Agent guides

- [CLI workflow](docs/logfire-trace-cli/SKILL.md)
- [Replay workflow](docs/replaying-logfire-conversations/SKILL.md)
