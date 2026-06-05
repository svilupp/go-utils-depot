# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Keep it brief!

## [0.12.1] - 2026-06-05

### Added
- `--version` / `-v` now prints the version (commit + build time); config loading still prefers `~/.config/logfire-trace/config.yaml` but falls back to the legacy `config.yml` when the canonical file is absent

## [0.12.0] - 2026-06-05

### Added
- `get -c` falls back through an optional `firestore.lookup_chats_collection`: a chat ID missing from the primary collection is resolved via the lookup collection's `conversationId`, then re-queried against the primary (empty config value = disabled)
- Enable it by adding `lookup_chats_collection: <collection-name>` under the `firestore:` block in `~/.config/logfire-trace/config.yaml` (or answer the "Lookup chats collection" prompt in `lft init`); leave it empty/absent to disable

## [0.11.0] - 2026-05-15

### Changed
- `/v1/query` requests now send `json_rows=true` and parse the row-oriented response directly, per Logfire's request to stop sending wide column-format queries that hammered their infrastructure
- All trace/chat/conversation lookups send `min_timestamp` so Logfire can prune partitions instead of scanning history; default lookback is 30 days, override with `--since`

### Added
- `get` command grew `--since` / `-S` (default `30d`, e.g. `--since 90d`)
- `query --sample` previews the result shape at 50 rows with a `[sample mode]` banner — recommended first step for agents on unfamiliar queries
- `query` prints a stderr tip when SQL has no top-level `LIMIT` and `--sample` is not set

## [0.10.1] - 2026-05-06

### Fixed
- `get -c <conversation-id>` now resolves chats whose Firestore documents store the canonical `conversationId` field (the legacy `layercodeConversationId`-only lookup silently missed ~94% of recent docs)

### Added
- `FindChat` falls back to the legacy `layercodeConversationId` field after trying canonical `conversationId`, so older documents written before the rename remain reachable
- Replay chat-document JSON detector accepts both `conversationId` and `layercodeConversationId`

### Changed
- Renamed `ChatDocument.LayercodeConversationID` → `ConversationID` (firestore tag `conversationId`); legacy field exposed as `LegacyConversationID` and surfaced via `ChatDocument.Conversation()` which prefers canonical
- Saved chat JSON now writes `conversationId` instead of `layercodeConversationId`

## [0.10.0] - 2026-05-03

### Added
- Chat replay support: pass a Firestore chat ID or a chat JSON fixture directly to `replay`
- `--recipe <trace_id|path>` supplies model, tools, and generation settings from a sibling trace; auto-discovered from chat fixture `metadata.trace.primary_trace_id` when omitted
- Source auto-detection across trace ID, chat ID, trace JSON, and chat JSON inputs (`replay/detect.go`)
- New flags: `--system-file`, `--temperature`, `--reasoning-effort` (`low|medium|high`), `--max-output-tokens`, `--skip-tools`
- `--dry-run` and `--dry-run --json` print the resolved `ReplayConfig` with per-field provenance
- Strict-tools validation: chats with tool calls but no tool definitions error out with the called tool names and remediation hints (`--recipe`, `--tools-file`, `--skip-tools`)
- Replay receipts: `--output-dir <DIR>` (env `LFT_OUTPUT_DIR`) writes one `lft.replay.receipt/v1` JSON per invocation (atomic, append-only)
- `--run-id <STRING>` stamps an optional grouping tag on receipts

### Changed
- `--model-override` renamed to `--model`; the old name remains as a hidden alias and emits a stderr warning. Setting both flags is a hard error.
- `--skip-tools` always emits a permanent stderr warning before each replay reminding that fidelity is degraded.
- Trace replays now actually apply `--temperature`, `--system-file`, `--max-output-tokens`, and `--reasoning-effort` to the provider request (previously read but dropped); `runReplay` rejects unexpected extra positional args with a clear error pointing at the `--flag=value` form
- `--output` and `--output-dir` reject mismatched path shapes (`.json` vs trailing slash) with corrective error messages that name the other flag

### Breaking
- Trace-replay `--dry-run` now prints a resolved-config provenance summary instead of a full `ReplayOutput` JSON. Use `--dry-run --json` to get structured output for tooling.

## [0.9.0] - 2026-03-27

### Added
- Turn-safe replay selectors and planning around `system`, `turn:N.user`, `turn:N.tool:M`, and `turn:N.response`
- Non-structural `--rewrite` plus sequential `--forward-from/--through` replay for contaminated multi-turn traces
- Replay turn normalization that handles assistant preludes and richer turn inspection metadata

### Changed
- `--turns`, `--inspect`, README, bundled replay skills, and CLI help now teach the canonical `turn:*` workflow first
- `--turns` now unwraps common `<user_input>` wrappers, marks synthetic server-update turns, and points system rewrites at the first real shopper turn
- `--inspect` now normalizes compatibility aliases like `msg:N` back to canonical `turn:*` labels

### Fixed
- `--no-thinking` now fails early for OpenAI `gpt-5.4` / `gpt-5.2` replays that still carry tool definitions
- Forward replay now skips response-less middle turns, preserves open-ended `--through` boundaries, and rejects `--count` even in `--dry-run`

## [0.8.0] - 2026-03-11

### Added
- Explicit replay intent flags: `--regenerate`, `--respond-to`, and `--replace`
- Replay span discovery with `--list-replay-spans` and explicit `--span <index|span_id>`
- Machine-readable `inspection` output plus human-readable `--inspect`
- Chat-first and conversation-first replay entry points: `--chat` and `--conversation`
- Actionable `--turns` output with canonical command suggestions
- Fixture-backed replay planner tests and query regression tests for multiline `--since` examples

### Changed
- Replay now plans and validates requests before any provider call; non-replayable plans fail fast with warnings and suggestions
- Default replay span selection now prefers non-guardrail spans, richer conversations, and spans with tools/xrefs
- `README`, replay skill docs, and CLI help now lead with `logfire-trace` and the shortest safe replay workflow
- `query --since` now uses a top-level SQL scanner instead of naive string matching

## [0.7.0] - 2026-03-10

### Added
- `--tools-file` flag for replay: override tool definitions from JSON (accepts Anthropic, Gemini, OpenAI payload shapes)
- `source` object in replay output with trace/span reference and recovered `chat_id`/`conversation_id`
- `tool_calls` array in replay response when model requests tool use (name, id, input)
- Conversation ID lookup now checks `conversation.id` and `ai.telemetry.metadata.conversationId` (not just Layercode key)
- `get` auto-recovers chat ID from conversation ID via Logfire query when trace lacks `chat.id`
- Actionable error when replaying a Firestore chat document instead of a trace file

### Changed
- Replay internals refactored: extracted `prepareReplay`, `buildSourceRef`, `executeCompletions`
- xref extraction prefers higher-priority keys across all spans before falling back
- Output renderers suppress unchecked `fmt.Fprint`/`color.Fprintf` return values
- Provider tool conversion accepts `parameters` key alongside `input_schema`/`inputSchema`
- Tests use `t.Setenv` instead of manual `os.Setenv`/`os.Unsetenv`

## [0.6.0] - 2026-03-08

### Changed
- Firestore integration is now fully config-driven and disabled by default
- `init` flow prompts for Firestore settings (GCP project, database, collections)
- Removed all hardcoded GCP project IDs, database names, and internal URLs

### Removed
- Hardcoded 1Password link and default Logfire project URL from init flow
- `.env.test` and `logs/` removed from tracking
