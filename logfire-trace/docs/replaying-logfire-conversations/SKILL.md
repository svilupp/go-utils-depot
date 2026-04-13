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

## Source Forms

```bash
logfire-trace replay <trace_id|url|file>
logfire-trace replay -c <chat_id>
logfire-trace replay --chat <chat_id>
logfire-trace replay --conversation <conversation_id>
```

- Prefer `-c` for chat replay so it matches `logfire-trace get -c`.
- Do not replay Firestore chat JSON documents directly. Use `-c/--chat` or `--conversation`.

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
