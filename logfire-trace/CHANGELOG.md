# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Keep it brief!

## [0.9.0] - 2026-03-27

### Added
- Turn-safe replay selectors around `system`, `turn:N.user`, `turn:N.tool:M`, and `turn:N.response`
- Non-structural `--rewrite` plus sequential `--forward-from/--through` replay for contaminated multi-turn traces
- Replay turn normalization that handles assistant preludes and richer turn inspection metadata

### Changed
- `--turns`, `--inspect`, README, bundled replay skills, and CLI help now teach the canonical `turn:*` workflow first
- `--turns` unwraps common `<user_input>` wrappers, marks synthetic server-update turns, and points system rewrites at the first real shopper turn
- `--inspect` normalizes compatibility aliases like `msg:N` back to canonical `turn:*` labels

### Fixed
- `--no-thinking` fails early for OpenAI `gpt-5.4` / `gpt-5.2` replays that still carry tool definitions
- Forward replay skips response-less middle turns, preserves open-ended `--through` boundaries, and rejects `--count` even in `--dry-run`

## [0.8.0] - 2026-03-11

### Added
- Explicit replay intent flags: `--regenerate`, `--respond-to`, and `--replace`
- Replay span discovery with `--list-replay-spans` and explicit `--span <index|span_id>`
- Machine-readable `inspection` output plus human-readable `--inspect`
- Chat-first and conversation-first replay entry points: `--chat` and `--conversation`
- Actionable `--turns` output with canonical command suggestions

### Changed
- Replay plans and validates requests before any provider call; non-replayable plans fail fast with warnings and suggestions
- Default replay span selection prefers non-guardrail spans, richer conversations, and spans with tools/xrefs
- README, replay skill docs, and CLI help lead with `logfire-trace` and the shortest safe replay workflow
- `query --since` uses a top-level SQL scanner instead of naive string matching

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
- Provider tool conversion accepts `parameters` key alongside `input_schema`/`inputSchema`

## [0.6.0] - 2026-03-08

### Added
- First public release: trace download, conversation summary, span tree, replay, cross-provider comparison
- Config-driven Firestore integration (disabled by default)
- Interactive `init` setup flow
