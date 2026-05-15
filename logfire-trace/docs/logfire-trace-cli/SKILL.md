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
logfire-trace replay <source> --inspect
```

- `get`: download traces or chats and render summaries or trees
- `query`: discover trace IDs, chat IDs, and conversation links
- `replay`: rebuild a recorded provider request safely
- `check`: validate config and API access
- `init`: set up config and optional aliasing

## Fetch Workflow

Copy this checklist:

Fetch workflow:
- [ ] Start from a trace ID, chat ID, user email, or SQL query result
- [ ] Use `get` to save the trace or chat locally
- [ ] Use `get -s` or `get -t` before replay when you need context

Examples:

```bash
logfire-trace get 019b93fef58a772e9ce3b26b756ced88
logfire-trace get -c YOlefE2UTuJ87F73ghLp
logfire-trace get -s 019b93fef58a772e9ce3b26b756ced88
logfire-trace get -t 019b93fef58a772e9ce3b26b756ced88
```

## Replay Workflow

Copy this checklist:

Replay workflow:
- [ ] Prefer a trace file or trace ID when available
- [ ] For chat-first replay, use `replay -c <chat_id>`
- [ ] Run `--list-replay-spans`
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
logfire-trace replay -c YOlefE2UTuJ87F73ghLp --span 15 --inspect
```

## Best Practices

1. Use `logfire-trace` in generated docs and examples; mention `lft` only as an alias.
2. Use `-c` for replay chat IDs to stay aligned with `get -c`.
3. Do not replay Firestore chat JSON documents directly.
4. Treat `--position` as legacy syntax; prefer explicit replay actions.
5. Treat `user:N`, `assistant:N`, `tool:N`, and `msg:N` as compatibility aliases; prefer `turn:N.*` selectors.
6. Validate the replay boundary with `--inspect` or `--dry-run` before live provider calls.
7. If `--inspect` warns that earlier assistant replies are preserved after a rewrite, switch to `--forward-from`.
8. Expect `--turns` to mark synthetic session-start messages and unwrap common `<user_input>` wrappers so you can pick the real shopper turn faster.
9. For `--forward-from ... --dry-run`, read `inspection.forward_steps` and `steps`; dry-run validates the sequence but does not emit per-step replay results.
10. Treat `--no-thinking` as provider-specific; OpenAI `gpt-5.4` / `gpt-5.2` currently reject it whenever the rebuilt request still carries tool definitions.

## Common Patterns

```bash
# Preview an unfamiliar query first (caps at 50 rows; recommended for agents)
logfire-trace query --sample "SELECT * FROM records WHERE span_name LIKE 'agent.%'"

# Find candidate traces (default lookback is --since 30d; pass -S 90d to widen)
logfire-trace query "SELECT trace_id FROM records ORDER BY start_timestamp DESC LIMIT 20"

# Fetch then replay
logfire-trace get <trace_id>
logfire-trace replay logs/trace_<id>.json --inspect

# Chat-first path
logfire-trace replay -c <chat_id> --list-replay-spans
```

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

1. Fetch candidate traces with `lft fetch <query>`.
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
