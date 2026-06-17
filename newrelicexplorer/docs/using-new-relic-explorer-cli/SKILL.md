---
name: using-new-relic-explorer-cli
description: >-
  Operate the newrelicexplorer (nrx) CLI to find logs and errors in New Relic
  (EU account) via NRQL/NerdGraph — search a service's logs, surface grouped
  errors, check latency/health/slow traces, list deploys, resolve curated
  service names to entities, build shareable NR links, or run raw NRQL. Covers
  the stdout-JSON / stderr-human contract, service/env resolution, and
  time/unit/limit guardrails. Triggers: "newrelicexplorer", "nrx", "New Relic
  logs", "find errors in New Relic", "NRQL", "why is a service failing".
---

# Using the New Relic Explorer CLI (`nrx`)

`newrelicexplorer` (alias `nrx`) finds logs and errors in New Relic via
NerdGraph/NRQL from one Go binary. Built for agents: **valid JSON on stdout,
human status on stderr**, full contract self-described by `--help` and
`nrx schema --json`. If `nrx` isn't aliased, run `newrelicexplorer`.

## Setup (once)

```bash
NEW_RELIC_API_KEY=... newrelicexplorer init   # writes ~/.config/newrelicexplorer/config.yaml (0600), offers `nrx` alias
nrx check                                      # confirm auth + account + region
```

`init` is env-first: with `$NEW_RELIC_API_KEY` set it stores only the
`${NEW_RELIC_API_KEY}` reference; a pasted key is saved to the 0600 config. Run
`nrx check` first whenever anything looks broken.

## Output contract

Canonical pattern: `nrx <cmd> ... 2>/dev/null | jq .`

- **stdout is always valid JSON.** Row commands emit a bare array (`[]` when empty,
  exit 0); `latency` emits an object with `unit` + `series`. With `--link`, output
  wraps as `{"results":[...],"links":{...}}`.
- **stderr is human-only** (`nrql:`, `warning:`, `hint:`, `note:`) — resolved NRQL,
  freshness/truncation notes, links. Never parse it.
- **ISO timestamps, raw epochs kept.** Templated row commands
  (`logs`/`changes`/`traces slow`) add `timestamp_iso` (RFC3339 UTC) beside the raw
  epoch; `latency` adds `beginTimeSeconds_iso`/`endTimeSeconds_iso`. Labels, never
  converts.
- **Raw `query` is verbatim** — no `_iso`, no facet→`message` rename. Only typed
  subcommands enrich; only `errors` collapses the facet column to `message`.
- **Deterministic order:** `logs`/`changes` newest-first; `traces slow` slowest-first.
- **Truncation:** when row count == `--limit`, stderr warns
  `returned N rows (= limit N); results may be truncated` (uniform across
  `logs`/`errors`/`traces slow`/`changes`); a `--limit exceeds max (5000)` note fires
  on clamp. **`changes` defaults to 50 rows over 30d and truncates — use `-n 200`.**
  Treat `count == limit` as "more probably exist".
- **Exit codes** (branch on these): `0` success incl. empty `[]`; `1` runtime
  (API/auth/network, or NRQL rejected by NerdGraph); `2` usage (bad flag,
  unknown/ambiguous service, bad arity, invalid `--env`/`--since`/`--region`/`--account`,
  unknown command) — caught before any API call, so a malformed token never leaks into NRQL.

## Commands & examples

Identify the service with `-s <short name>` (fuzzy). `--since` takes `30m`/`1h`/`7d`.

```bash
# logs — find logs that say X, or error logs
nrx logs -s agents --contains "timed out"          # literal substring; positional arg also works
nrx logs -s agents --level error --since 15m
nrx logs -s agents --env uat --limit 20

# errors — top messages, grouped (FACET); fastest "what's failing"
nrx errors -s checkout --since 6h

# latency / health / slow traces — mind the units
nrx latency -s agents -e production --percentile 50,95,99 -S 1h   # unit: seconds
nrx health  -s window-shop-core-api                                # requests/errorRate/rpm/percentiles
nrx traces slow -s agents --min-ms 2000 -S 30m                     # unit: ms

# deploys (account-wide, sparse), shareable link, raw NRQL
nrx changes -n 200
nrx link -s agents -e production --errors -S 30m
nrx query "SELECT count(*) FROM Log SINCE 1 hour ago"
```

Debugging flow: **`errors` → `logs --level warn` + targeted `--contains` → `traces
slow`/`latency`/`health` → onset via `query ... TIMESERIES`.** Count first if the
window is large; widen `--since` on a `quiet` note.

## Bootstrap — discover, don't guess

```bash
nrx schema --json     # OFFLINE contract: commands, flags, NRQL templates, services, exit codes
nrx <command> --help  # per-command NRQL template + examples
nrx services          # curated inventory + descriptions (offline)
nrx services list     # resolve names to LIVE entity.name(s); labels ok/quiet/dark
```

Authoritative and never stale — prefer them over memorizing flags.

## Service & env targeting

- `-s <short name>` fuzzy-resolves to the real `entity.name`; ambiguous/unknown →
  **exit 2** with "did you mean". **Omit `-s` to sweep all services account-wide.**
- Targeting always uses `LIKE`, never `=` (NRQL `=` is case-sensitive → silent zero
  rows). Do the same in raw `query`.
- **`-e/--env`:** `production` (default) | `staging` | `development` | `uat`; invalid
  → exit 2. Maps to suffix `:prod%`/`:staging%`/`:dev%`/`:uat%`.
- **Three service shapes** (shown by `nrx services`): `envs` (honors `--env`, most
  services), `no_env` (single entity), `match` (broad pattern spanning envs). For
  `no_env` and `match`, **`--env` is ignored** (CLI prints a stderr advisory) — don't
  read env scoping into those results.
- Cases to remember: `window-shop-inventory` has **staging/dev only, no production**
  (use `--env staging`); `window-shop-ai-product-intelligence` and
  `window-shop-ai-evaluations` are `no_env`; `window-shop-ai-analytics` is `match`
  (mixes prod + dev).
- **17 curated services**; 3 are intentionally dark (`reporting:false`):
  `window-shop-cron-jobs`, `window-shop-pilot-web`, `wire-worker`.

## Filters

- **`--contains "X"`** → `message LIKE '%X%'`, literal & case-insensitive (positional
  arg is shorthand). Gotchas:
  - Substring, not stem: `timeout` misses `"timed out"` — try both phrasings.
  - Short/numeric terms false-positive (`503` matches a port; `token` matches
    `input_tokens`) — use a phrase with context (`"503 The service"`).
  - Apostrophes work (`--contains "can't"`).
- **`--level X`** → `level LIKE 'X%'`, case-insensitive. Level casing varies by stack
  (Node lowercase, Python uppercase) and can mix in one result — never `level = 'ERROR'`
  in raw NRQL.
- **`--since`** accepts only `^\d+[mhd]$` (`30m`/`6h`/`7d`); anything else → exit 2.
  Default `30m` (`changes` is `30d`). The shorthand is for typed subcommands only —
  raw `query` needs NRQL syntax (`SINCE 7 days ago`).
- **`errors` vs `logs`:** `errors` groups by message (dominant failure, fastest);
  `logs` is per-line detail.

## Tips & gotchas

- **Empty ≠ broken.** Zero rows exit `0` with a stderr freshness label echoing your
  window: `ok`; `quiet` (had data in 7d, recent window empty — widen `--since`);
  **filtered-empty** (`--contains`/`--level` matched nothing — service may still be
  active; loosen the filter); `dark`, which distinguishes `configured reporting:false`
  from `no telemetry in 7d`.
- **Units labeled, never converted:** Transaction `duration` is seconds
  (`latency`/`health`); Span `duration.ms` is ms (`traces slow`). Read `unit`.
- **`latency` scales its TIMESERIES bucket to the window** — `7d`/`48h` work, just
  coarser. No upper window limit.
- **Limits:** `--limit` default 50, clamped to 5000. `--sample` gives a cheap small
  preview (`[sample mode]` on stderr).
- **Links:** `--link` / `link` return a verified `entity_permalink` + `ui_filter`,
  plus a `logs_deeplink` tagged `constructed-unverified` (don't present as authoritative).
- **Caching:** `services list` and `link` cache resolution (short TTL); `--refresh`
  busts it.
- **Region:** EU only; US 403s (client retries once). Set `region:` in config to fix.
- **Raw `query` traps:** `=` is case-sensitive (use `LIKE`); malformed-but-parseable
  NRQL (unknown event type/attribute) exits `0` with `[]` — re-check table/field names.
  Tables: `Log`, `Transaction`, `Span`, `Deployment`.

## Best practices (from heavy real use)

1. **WARNING-level failures are invisible to `errors`.** The `ai-*` (Python/FastAPI)
   services log real failures — missing API keys, DB auth, GCS 403s, health 503s — at
   **WARNING**. `errors` and `logs --level error` return `[]` while the service is
   failing. Always also `nrx logs -s <svc> --level warn` and sweep targeted phrases.
2. **`health.errorRate` is Transaction-based** — ~0% for worker/ingestion/pipeline
   services (they fail in Log/Span/PubSub, not HTTP). Lead with `errors`/`logs`/`traces
   slow`; reserve `health` for HTTP services.
3. **Root cause often lives in `payload.error.*`, not `message`** (which can be null).
   `errors` only facets `message`; drop to raw query, and backtick dotted attrs in FACET:
   ```bash
   nrx query "SELECT payload.error.message, payload.error.stack FROM Log WHERE entity.name LIKE '<svc>:prod%' SINCE 6 hours ago LIMIT 50"
   nrx query "SELECT count(*) FROM Log WHERE entity.name LIKE '<svc>:prod%' FACET \`payload.error.message\` SINCE 6 hours ago LIMIT 30"
   ```
   Faceted `count(*)` is approximate; use non-faceted for an exact total.
4. **Account-wide triage** (omit `-s`): rank, then drill.
   ```bash
   nrx query "SELECT count(*) FROM Log FACET entity.name SINCE 1 day ago LIMIT 100"
   nrx query "SELECT count(*) FROM Log WHERE level LIKE 'err%' FACET entity.name SINCE 6 hours ago LIMIT 30"
   nrx query "SELECT count(*) FROM Log WHERE entity.name = '<ent>' FACET message SINCE 6 hours ago LIMIT 30"
   ```
   Many high-traffic entities aren't curated (`swap-shopify-app`, `global-server`,
   `tax-calculation-service`, `returns-server`, `billing-server`) — find them via FACET, not `-s`.
5. **`changes` excludes `window-shop-*`**, so deploy-to-error correlation isn't possible
   there. Find an error's onset from logs instead — the first non-zero bucket:
   ```bash
   nrx query "SELECT count(*) FROM Log WHERE entity.name LIKE '<svc>:prod%' AND message = '<exact>' TIMESERIES 30 minutes SINCE 7 days ago"
   ```
6. **Broken vs noisy:** pair-equal counts across two messages (e.g. 7,140/7,140) = tight
   failing loop (real). High-volume WARN floods = usually cost/noise. Quantify before escalating.
