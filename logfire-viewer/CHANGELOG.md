# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Keep it brief!

## [0.3.0] - 2026-05-07

### Added
- Replay families: `/replays/family/{hash}` shows every sample sharing the *exact same input* (system prompt + all input messages + tool definitions) side-by-side, so you can read N stochastic outputs in one view. Hash excludes sampling params and model name so re-runs with cache-busting tweaks still group together.
- "View all samples · N" CTA on each variant in the session tree when the family has 2+ samples across sessions.
- Receipt loader stamps `Meta["prefix_sha"]` on every conversation so families are pre-computed at load time.

### Changed
- Compare flow polished: `Compare two variants` button hidden when a session has only one variant; bad `/replays/compare` requests redirect to the originating session with a styled banner instead of returning a raw HTTP error; client-side guardrail blocks submit unless exactly two variants are ticked.

## [0.2.1] - 2026-05-07

### Fixed
- Walker now descends into `.replays/` so `lft` receipts written under the default `LFT_OUTPUT_DIR=.replays/` show up in the Replays tab.

## [0.2.0] - 2026-05-03

### Added
- Saved-items inbox at `/saved` with star, notes, tags, retention, and live updates
- `saved` CLI for pushing and managing traces from the terminal against a running server
- Replay sessions: `/replays` ingests directories of `lft replay --output-dir <DIR>` receipts, auto-clustered by `source_trace_id` × `input_sha`, with side-by-side prompt-diff compare view
- `POST /api/ingest` accepts an optional `session=<label>` form field for a friendly replay-session name (defaults to a random hex)
- Search bar across run / scenario / chat / conversation IDs; sortable, date-filtered tables; green-only runs preset; wipe button

### Changed
- Smarter conversation view: collapsed long system prompts, linked sources, copy buttons, recency badges, empty-turns metadata card

## [0.1.0] - 2026-04-26

### Added
- CLI subcommands: `serve`, `open`, `list`, `inspect`, `show`, `dump`, `init`, `version`
- Multi-source loaders: Perseus scenarios + run directories, Firestore chats, Logfire traces, generic message arrays
- ConvKey fusion across multi-source records
- Run-aware UI: routes `/`, `/runs/{id}`, `/runs/{id}/s/{name}`, `/runs/compare`, `/loose`, `/c/{id}`, plus verdict panel (hard / soft / assertions), sticky filter row, ⌘K palette, `j`/`k`/`[`/`]`/`f`/`1`-`4`/`g r` keybindings
- Navbar drop zone and `POST /api/ingest` for ad-hoc multipart or JSON uploads (not watched)
- `Jobs` tab driving `lft get` / `lft replay` as background subprocesses with ring-buffered stdout/stderr
- SSE live-reload at `/events` and per-job streaming at `/api/jobs/{id}/output`
- Agent discovery: embedded `/llms.txt` and `/openapi.json`
- Headless mode: `serve --quiet` emits a single `READY <url>` line on stdout
- Embedded assets via `//go:embed` synced from `assets/` to `internal/server/assets/` by `make assets`
- Pre-merge gate: `make check` (fmt → vet → lint → `go test -race` → build)
