---
name: using-logfire-trace-cli
description: Use the logfire-trace CLI to fetch traces, inspect AI spans, recover chat or conversation context, and run safe replays. Use when working with Logfire traces, Firestore-linked chats, or when a user refers to the `lft` alias.
---

# Using logfire-trace CLI

Use `logfire-trace` as the primary binary name. `lft` is only an optional shell alias after `logfire-trace init` or manual shell setup.

## Naming Rule

- Prefer `logfire-trace` in docs, examples, and suggested commands.
- Accept `lft` only when the environment already has the alias configured.
- Prefer `-c` for chat IDs because it matches `logfire-trace get -c`.

## Command Map

```bash
logfire-trace get <trace_id>
logfire-trace get -c <chat_id>
logfire-trace get -u <email>
logfire-trace query -S 30d "<sql>"
logfire-trace profiles
logfire-trace replay <source> --inspect
```

- `get`: download traces or chats, save JSON, and optionally render summaries or trees
- `query`: discover trace IDs, chat IDs, and conversation links
- `replay`: rebuild a recorded provider request safely
- `check`: validate config and API access
- `init`: set up config and optional aliasing

## Fetch Workflow

Copy this checklist:

Fetch workflow:
- [ ] Start from a trace ID, chat ID, user email, or SQL query result
- [ ] Fetch once with `get`; keep the reported JSON path for repeated local analysis
- [ ] Prefer `--output FILE` or `--output-dir DIR` for an investigation folder
- [ ] Use `replay <saved-file> --inspect` / `--turns` without downloading again

Examples:

```bash
logfire-trace get <trace_id> --output-dir logs/investigation/ > /dev/null
logfire-trace get -c <chat_id> --output-dir logs/investigation/ > /dev/null
logfire-trace replay logs/investigation/trace_<trace_id>.json --inspect | jq '{replayable, selected_span}'
logfire-trace replay logs/investigation/trace_<trace_id>.json --turns --human
```

`get` emits JSON on stdout and always saves a JSON capture. Replay inspection,
turn reports, candidate lists, and dry-runs also emit JSON by default; pass
`--human` for terminal text. Defaults are
`./logs/trace_<id>.json` and `./logs/chat_<id>.json`; configure `output_dir`
or override it with output flags. Saved paths are status messages on stderr,
so machine pipelines remain valid.

If `firestore.lookup_chats_collection` is configured, `get --chat`/`-c` may
transparently fall back through that lookup collection: when the ID misses the
primary collection, the CLI reads the lookup doc's `conversationId` and
re-queries the primary collection by it. A successful fallback prints a
breadcrumb to stderr — `Note: chat not found in '<primary>'; resolved via
lookup collection '<lookup>' (conversationId <id>)` — meaning the chat was
recovered via the secondary collection, not that anything failed.

## Replay Workflow

Copy this checklist:

Replay workflow:
- [ ] Prefer a trace file or trace ID when available
- [ ] For chat-first replay, use `replay -c <chat_id>`
- [ ] Run `--list-replay-spans`; if there are multiple candidates, pass a stable `--span <span_id>` in subsequent commands
- [ ] Run `--turns` or `--inspect`
- [ ] Prefer canonical selectors from `--turns`
- [ ] Use `--rewrite` for non-structural edits
- [ ] Use `--forward-from/--through` when earlier assistant history must be replayed forward

```bash
logfire-trace replay trace.json --list-replay-spans
logfire-trace replay trace.json --turns
logfire-trace replay trace.json --respond-to turn:0.user
logfire-trace replay trace.json --rewrite system -i prompt.txt --respond-to turn:1.tool:0
logfire-trace replay trace.json --rewrite system -i prompt.txt --forward-from turn:0.tool:0 --through turn:1.tool:0
logfire-trace replay -c <chat_id> --span <span_id> --inspect
```

## Best Practices

1. Use `logfire-trace` in generated docs and examples; mention `lft` only as an alias.
2. Use `-c` for replay chat IDs to stay aligned with `get -c`.
3. Replay saved trace or chat JSON locally whenever possible; do not fetch the
   same remote source repeatedly.
4. Treat `--position` as legacy syntax; prefer explicit replay actions.
5. Treat `user:N`, `assistant:N`, `tool:N`, and `msg:N` as compatibility aliases; prefer `turn:N.*` selectors.
6. Validate the replay boundary with `--inspect` or `--dry-run` before live provider calls.
7. If `--inspect` warns that earlier assistant replies are preserved after a rewrite, switch to `--forward-from`.
8. Expect `--turns` to mark synthetic session-start messages and unwrap common `<user_input>` wrappers so you can pick the real shopper turn faster.
9. For `--forward-from ... --dry-run`, read `preflight` and `would_call`; dry-run validates the sequence but does not emit per-step replay results.
10. Treat `--no-thinking` as provider-specific; OpenAI `gpt-5.4` / `gpt-5.2` currently reject it whenever the rebuilt request still carries tool definitions.
11. `-p` means `--profile` on `get`, `query`, and `check`. On `replay`, `-p` is the legacy `--position` shorthand — use the long `--profile` with replay to avoid clashing with it.
12. If replay extraction looks wrong, or you hit "no adapter matched", try forcing `--format pydantic-ai` (or `--format ai-sdk`) — auto-detection can misfire on mixed-instrumentation traces.

## Common Patterns

```bash
# Find candidate traces first
logfire-trace query -S 30d "SELECT trace_id FROM records ORDER BY start_timestamp DESC"

# Fetch once, then replay the saved artifact repeatedly
logfire-trace get <trace_id> --output-dir logs/investigation/ > /dev/null
logfire-trace replay logs/investigation/trace_<id>.json --inspect

# Chat-first path
logfire-trace replay -c <chat_id> --list-replay-spans
```

## Aggregate trace analysis: common pitfalls

Hard-won lessons from a production incident where a reported count got retracted twice:

- **Never** match error codes with `attributes::text ILIKE '%CODE%'` — error-code tables
  are embedded in system prompts, so this matches nearly every trace (540 vs a true ~30
  in one incident). Query the structured attribute on the tool span instead (e.g.
  `tool.error_code`, `ai.toolCall.result`).
- Count tool calls on `ai.toolCall` spans (1:1 with live executions), never by
  pattern-matching `doStream` spans or `ai.prompt.messages` — conversation history
  replays past events on every later turn (~8x inflation observed). For model-output
  conditions, scope to `ai.response.toolCalls` only.
- Exclude test traffic: `attributes->>'conversation.id' LIKE 'test-conv-%'`, known test stores, and
  filter `deployment_environment = 'production'`. Test/eval harness bursts have
  contaminated counts by 32–99%. Synthetic tells: ~2ms durations, missing expected
  child spans.
- NULL traps: `col LIKE ...` / `col ~ ...` evaluate to NULL (not FALSE) when `col` IS
  NULL, so `COUNT(*) FILTER (WHERE ...)` silently drops those rows — often the worst
  failures. Add explicit `OR col IS NULL OR is_exception`.
- Dimension fields (e.g. `store.id`) may not live on the span you're aggregating — join
  via `trace_id`, or rows silently drop.
- State your denominator explicitly and check the complement population; anchoring on
  "traces like the reported example" hid 54% of defects in one investigation.
- Distinguish domain-valid error codes (e.g. `SEARCH_NO_RESULTS`) from infrastructure
  errors before computing error rates.

## Filing traces for review (logfire-viewer saved)

When the user asks Claude to focus on specific traces — "review the failing
tool calls from this run", "look at any conversation where the agent looped",
"check the ones with truncation" — push them into the user's `logfire-viewer`
saved-items inbox rather than printing inline summaries. The user reviews them
with j/k navigation in the UI; this is a far better workflow than scrolling
chat output.

### When to use it

- The user says "review", "look at", "check", "investigate" + a filter
  ("failed", "looped", "long", "with X tool"), and you have or can fetch
  the underlying trace files.
- You're triaging a batch and want the user to be able to walk it.
- You want to leave a breadcrumb (the `--note`) explaining why each trace
  matters.

Don't use it for one-off lookups where the user just wants the answer
inline.

### Workflow

1. Find candidate traces with `logfire-trace query -S 7d "<sql>"`, then fetch each hit
   with `logfire-trace get <trace_id>`.
2. For each trace that matches the user's criteria:

   ```bash
   logfire-viewer saved add <file> --note "<one-line reason>" \
       --tag <stable-tag-for-this-batch>
   ```

3. Tell the user:
   - How many were filed.
   - The tag you used (so they can filter the inbox).
   - The inbox URL (`<server>/saved`).

### Server discovery

The CLI looks at `~/.config/logfire-viewer/server.json` automatically. If it
isn't running, the CLI exits with a clear hint — pass that hint along to the
user verbatim ("start one with `logfire-viewer serve`"). Do not write to the
saved_items directory directly.

### Idempotency and dismissals

- Re-running the same script is safe: same-SHA adds are no-ops.
- If the user has previously trashed a file, the CLI returns
  "file was previously dismissed" and exits 0. Don't `--force` past this
  unless the user explicitly asks to override their prior dismissal.

### Failure handling

The CLI prints actionable hints for every common failure (no server, file
not found, file too big, format unrecognised, etc.). Surface them to the user
as-is rather than rephrasing — they're written to be self-explanatory.
