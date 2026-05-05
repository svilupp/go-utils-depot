---
name: replaying-logfire-conversations
description: Replay recorded AI conversations from Logfire traces against provider APIs. Use when debugging prompt behavior, validating a recorded turn, comparing providers, or recovering a replayable boundary from a trace, chat ID, or conversation ID.
---

# Replaying Logfire Conversations

Use `logfire-trace replay` to rebuild a provider request from a recorded generation span.

Use the full command name in docs and examples. `lft` is only an optional shell alias after setup.

## When to Use

- prompt debugging
- replaying a known turn boundary
- comparing providers on the same recorded request
- recovering the right replay span from a trace, chat ID, or conversation ID
- forward-replaying contaminated multi-turn conversations after a prompt change

## Safe Workflow

Copy this checklist:

Replay workflow:
- [ ] Resolve the source: trace file, trace ID, `-c <chat_id>`, or `--conversation <id>`
- [ ] List replay candidates: `logfire-trace replay <source> --list-replay-spans`
- [ ] Inspect the turn map: `logfire-trace replay <source> --turns`
- [ ] Validate the boundary: `logfire-trace replay <source> --inspect`
- [ ] Prefer canonical selectors from `--turns`
- [ ] Use `--rewrite` for non-structural edits
- [ ] Use `--forward-from/--through` when earlier assistant replies contaminate later turns

## Saving for Review

When you replay anything you might want to look at again — prompt iteration, model comparison, noise sampling — pass `--output-dir <DIR>`. The receipts are cheap, append-only JSON (schema `lft.replay.receipt/v1`) and let you cluster runs later. Same `input_sha` under one `source_trace_id` = noise samples; different `input_sha` = a variant. If you'll do this more than once in a session, `export LFT_OUTPUT_DIR=.replays/` once at the top.

```bash
logfire-trace replay trace.json --output-dir .replays/
jq -r '.input_sha + " " + .input.model' .replays/*.json | sort | uniq -c
```

## Source Forms

```bash
logfire-trace replay <trace_id|url|file>
logfire-trace replay <chat_id>
logfire-trace replay <chat.json>
logfire-trace replay -c <chat_id>
logfire-trace replay --chat <chat_id>
logfire-trace replay --conversation <conversation_id>
```

The first positional argument is auto-detected by content shape:

- 32-char hex trace ID → fetched from Logfire
- shorter alphanumeric ID → Firestore chat
- `*.json` array → trace JSON dump
- `*.json` object with `conversation` + `metadata.chat_id` → chat JSON fixture
- `*.json` object with span keys → single-span trace dump

`-c/--chat` and `--conversation` remain available for the legacy chat-first / conversation-first replay flow that resolves traces, lists candidate spans, and replays from there.

## Actions

```bash
logfire-trace replay <source> --respond-to turn:1.tool:0
logfire-trace replay <source> --regenerate turn:1.response
logfire-trace replay <source> --rewrite system -i prompt.txt --respond-to turn:1.tool:0
logfire-trace replay <source> --rewrite system -i prompt.txt --forward-from turn:0.tool:0 --through turn:1.tool:0
logfire-trace replay <source> --replace user:7 -i override.txt
```

- `--rewrite TARGET -i FILE`: rewrite `TARGET` in place while preserving transcript shape
- `--respond-to TARGET`: keep `TARGET` and ask for the next assistant response
- `--regenerate TARGET`: remove `TARGET` and replay from the prior boundary
- `--forward-from A --through B`: regenerate dependent responses sequentially from `A` through `B`
- `--replace TARGET -i FILE`: legacy rewrite+truncate behavior kept temporarily for compatibility

Targets:

- `system`
- `turn:N.user`
- `turn:N.tool:M`
- `turn:N.response`
- compatibility aliases: `last`, `user:N`, `assistant:N`, `tool:N`, `msg:N`

## Validation Loop

Follow this loop before any provider call:

1. Run `--inspect`.
2. Confirm `replayable=true`.
3. If needed, run `--dry-run | jq '.inspection'`.
4. If the planner warns about contamination, use `--forward-from` instead of keeping stale later replies.
5. If the request ends on `assistant`, switch to `--respond-to` or a safer target.
6. For `--forward-from ... --dry-run`, inspect `inspection.forward_steps` and `steps`; dry-run validates the sequence but does not emit per-step replay `results`.
7. Treat `--no-thinking` as provider-specific: Anthropic works, Gemini 3 is best-effort, Gemini 2.5 Pro is unsupported, and OpenAI `gpt-5.4` / `gpt-5.2` currently cannot use it when the rebuilt request still carries tool definitions.

## Span Selection

If the trace contains multiple generation spans:

```bash
logfire-trace replay <source> --list-replay-spans
logfire-trace replay <source> --span 3 --inspect
```

The default selector prefers:

1. non-guardrail / non-classifier spans
2. more prompt messages
3. spans with tools and chat/conversation cross references
4. later timestamps only as a tie-breaker

## Common Failure Modes

1. Legacy `-p user:N` removes the target user turn and leaves the request ending on `assistant`.
2. The trace contains both main-agent and guardrail/classifier generations, so the wrong span gets selected.
3. The rebuilt request ends on `assistant` or has no request messages.
4. A chat document file is used as replay input instead of a trace source.
5. A prompt rewrite is tested against a later turn while earlier assistant replies still encode the old behavior.

The planner now catches non-replayable requests before provider calls and prints safer suggestions.

## Recipe Trace Workflow

A chat alone is missing model, tool definitions, and generation settings. Supply them with a recipe trace.

```bash
# Recipe is auto-discovered from chat fixture metadata when present
logfire-trace replay logs/chat.json --dry-run

# Pin a recipe explicitly (always wins over auto-discovery)
logfire-trace replay logs/chat.json --recipe 019aabbccdd... --dry-run

# Firestore chats: pass --recipe explicitly (no auto-discovery for now)
logfire-trace replay <chat_id> --recipe trace.json
```

When auto-discovery fires, the CLI prints to stderr:

```
recipe: auto-discovered from chat metadata: 019ddaeb466ff5ca2e...
```

Pick a recipe trace whose model, tools, and system prompt match the chat's intended runtime — typically a sibling agent run from the same batch or a known-good capture.

If the chat contains tool calls but no tool definitions reach the resolver (no recipe, no `--tools-file`), replay errors out with the called tool names and remediation hints. Resolve by passing `--recipe`, `--tools-file`, or `--skip-tools`.

## New Replay Flags (0.10.0)

| Flag | Purpose |
|---|---|
| `--recipe <trace_id\|path>` | Trace supplying model/tools/settings; auto-discovered from chat metadata when omitted |
| `--model <name>` | Override model (replaces `--model-override`; old name kept as deprecated alias, conflict errors) |
| `--system-file <path>` | Override system prompt from text file |
| `--temperature <float>` | Override generation temperature |
| `--reasoning-effort low\|medium\|high` | CLI-only; not stored in span data |
| `--max-output-tokens <int>` | Override max output tokens |
| `--skip-tools` | Run without tools; emits permanent stderr warning |
| `--dry-run` | Print resolved `ReplayConfig` + provenance and exit |
| `--dry-run --json` | Emit resolved config as JSON for tooling |
| `--output-dir <DIR>` | Append a `lft.replay.receipt/v1` JSON to `<DIR>` for every invocation |
| `--run-id <STRING>` | Optional grouping tag stamped on receipts |

## Dry-Run Validation

```bash
logfire-trace replay logs/chat.json --recipe 019aabbccdd... --dry-run
logfire-trace replay logs/chat.json --recipe 019aabbccdd... --dry-run --json | jq .
```

`--dry-run` shows where each field came from (chat, recipe, flag, sibling span) so you can confirm the layered resolution before sending. As of 0.10.0, trace `--dry-run` prints this provenance summary instead of the full `ReplayOutput` JSON; use `--dry-run --json` when tooling needs structured output.

## --skip-tools Fidelity Caveat

`--skip-tools` is the opt-in escape hatch when the chat called tools you cannot reproduce. It runs the model with no tool schemas, so the replayed turn is not 1:1 with production behavior. The CLI emits a permanent stderr warning every time it is used; this is intentional and cannot be silenced. Prefer `--recipe` or `--tools-file` whenever possible.
