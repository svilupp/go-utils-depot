# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Keep it brief!

## 0.4.1 — 2026-08-26

- Scenario detail header now shows the conversation ID (`conv <id>`) with a copy button.
- Fused Logfire conversations now use the *last* turn's trace ID (by latest EndedAt/StartedAt) for `PrimaryTraceID`, the `lft replay` command, and the Logfire link — previously used the first turn.

## 0.4.0 — 2026-08-11

- Eval config explorer at `/evals`: point `--evals <dir>` at any folder and it walks the tree and loads the eval scenario/manifest TOMLs it recognizes — by file content, not by directory layout. Nothing recognizable found, nothing shown: no nav link, no routes.
- Browse and search every spec at `/evals/specs` — filter by category, store, mode, tool, criterion, assertion type, or orphan status. Criterion text is searchable via an opt-in toggle. Each row shows a one-line headline plus a fact strip of what the spec actually enforces.
- Spec detail resolves stores, personas, shared criteria, and inherited sidecar flags, and lists which manifests reference it.
- `/evals/manifests` groups near-identical manifests into clusters: the shared case set is rendered once, then only the fields that differ across members — one screen instead of diffing dozens of files by hand.
- Run directories are listed newest-first (100 by default, `Load more` for the rest) and are never parsed until you load one, so pointing at a repo root with gigabytes of logs stays instant.
- Nav gained a section switcher (Runs · Replays · Evals · Jobs) with active highlighting and a `g e` shortcut. Eval specs and manifests are searchable from the ⌘K palette.
- Settings live in `~/.config/logfire-viewer/config.json` (`evals_dir`, `evals_max_depth`, `evals_max_rundirs`, `evals_skip_dirs`), overridable by `$LFV_EVALS_*` env vars and CLI flags.

## 0.3.3 — 2026-07-03

- Fix: Perseus run scenarios now show the main agent's system prompt instead of the guardrails classifier prompt. `trace_enrichment.system_prompt` is sometimes populated upstream with the wrong prompt (scraped from the `guardrails.classify` → `ai.generateText` span); the loader now recovers the correct prompt from the replay trace's primary agent span (`ai.streamText`/`agent.generate.response`) and prefers it, falling back to `trace_enrichment.system_prompt` when no replay trace is available.

## 0.3.2 — 2026-05-22

- Dropped trace files now land directly in the ★ Saved inbox and survive server restarts. Multi-trace logfire JSON files no longer collapse to one item — each `trace_id` becomes its own inbox entry.

## 0.3.1 — 2026-05-15

- Render tool calls in Perseus runs whose conversation files leave `tool_invocations` empty but ship a `replay_traces/` dump: load the spans (with basename fallback so cross-machine run dirs work) and synthesize tool calls from descendant `ai.toolCall` spans. Also accept `tool_call`/`tool_result` underscore variants in Logfire trace content alongside the existing hyphen forms.

## 0.3.0 — 2026-05-07

- Replay families: `/replays/family/{hash}` shows every sample sharing the *exact same input* (system prompt + all input messages + tool definitions) side-by-side, so you can read N stochastic outputs in one view. Hash excludes sampling params and model name so re-runs with cache-busting tweaks still group together.
- Receipt loader stamps `Meta["prefix_sha"]` on every conversation; the session tree shows a prominent `▶ View all samples · N` button per variant when the family has 2+ samples.
- Compare flow polished: `Compare two variants` button hidden when a session has only one variant; bad `/replays/compare` requests redirect with a styled banner instead of returning a raw HTTP error.

## 0.2.1 — 2026-05-07

- Fix: walker now descends into `.replays/` so `lft` receipts written under the default `LFT_OUTPUT_DIR=.replays/` show up in the Replays tab.

## 0.2.0 — 2026-05-03

- Saved-items inbox at `/saved` with star, notes, tags, retention, and live updates.
- `saved` CLI for pushing and managing traces from the terminal against a running server.
- Search, wipe, sortable + date-filtered tables, green-only runs preset.
- Smarter conversation view: collapsed long system prompts, linked sources, copy buttons, recency badges, empty-turns card.
- Replay sessions: `/replays` ingests directories of `lft replay -O <DIR>` receipts, auto-clustered by `source_trace_id` × `input_sha` with side-by-side prompt-diff compare view.
- `POST /api/ingest` accepts an optional `session=<label>` form field for a friendly replay-session name (defaults to a random hex).

## [0.1.0] - 2026-04-26

### Added
- CLI subcommands: `serve`, `open`, `list`, `inspect`, `show`
- Multi-source loaders: Perseus scenarios + run directories, Firestore chats, Logfire traces, generic message arrays
- Run-aware UI: routes `/`, `/runs/{id}`, `/runs/{id}/s/{name}`, `/loose`, `/c/{id}`, plus verdict panel (hard / soft / assertions), sticky filter row, ⌘K palette, j/k/[ ]/f/1-4/g r keybindings
- SSE live-reload plus `/partials/{status,footer,scenarios}` HTMX swaps
- Parallel file scanning via errgroup with `BenchmarkStoreLoadParallel` budget
- Embedded assets via `//go:embed` synced from `assets/` to `internal/server/assets/` by `make assets`
- Pre-merge gate: `make check` (fmt → vet → lint → `go test -race` → build)
