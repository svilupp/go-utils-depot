---
name: using-sentryexplorer-cli
description: >-
  Operate the sentryexplorer (srx) CLI to triage errors and issues in Sentry
  across the curated projects configured in ~/.config/sentryexplorer. Covers
  the stdout-JSON / stderr-human contract, curated-project fuzzy matching,
  the issues/errors/spikes/issue/releases workflow, and the raw query escape
  hatch. Triggers: "srx", "sentryexplorer", "Sentry errors", "check Sentry".
---

# Using the Sentry Explorer CLI (`srx`)

`srx` (binary `sentryexplorer`) triages Sentry issues/errors/releases across
a curated set of projects: **valid JSON on stdout, human status on stderr**.
`srx --help` lists the configured projects; `srx schema` dumps the full
machine-readable contract offline. If anything looks broken, run `srx check`
(config + auth validation) first.

**Curated projects are per-user config, not fixed.** Every install has its own
list (in `~/.config/sentryexplorer/config.yaml`). The placeholder inventory uses
names (`frontend`, `backend`, `mobile`) with slugs (`frontend-web`, `backend-api`,
`mobile-app`). Examples assume such projects exist. Before first use, discover
the actual names and substitute them:

```bash
srx projects          # curated list: name, slug, description (offline)
srx --help            # also prints the configured projects inline
```

## Output contract

Canonical pattern: `srx <cmd> ... 2>/dev/null | jq .`

- **stdout is valid JSON, always** — a bare array (`[]` on empty results,
  never blank), or an object for `schema`/`issue`/`check`-style detail
  commands.
- **stderr is human-only** — `error:`/`hint:`/`warning:` lines. Never parse it.
- **`--human`** (global) renders a table for humans — never use it when piping.
- **Exit codes**: `0` success, **including empty `[]`**; `1` runtime error
  (API/auth/network); `2` usage error (bad flag, unknown/ambiguous project) —
  caught before any API call.

## Quick-triage workflow

(substitute your real project names from `srx projects`)

```bash
srx issues -p frontend --since 7d            # unresolved issues, this project, sorted by freq
srx errors -p frontend --since 24h           # "dominant failures" view
srx spikes -p frontend --since 24h           # is volume increasing? (heuristic 2x-average flag)
srx issue FRONTEND-WEB-12                    # drill in: exception, tags, stack info
srx releases -p backend -n 5                 # recent deploys, to correlate with a spike/issue
```

- **`issues`** vs **`errors`**: both list `is:unresolved` sorted by `freq`
  over `--since`. Start with `errors` for "what's breaking"; use
  `issues --sort date` for what's newest, `issues --all` for full pagination.
- **`spikes`** splits the `--since` window in half and flags `spike:true`
  when the second-half average exceeds 2x the first-half — a **heuristic
  hint, not a statistical verdict**.
- **`issue <shortId-or-id>`** takes a shortId (`FRONTEND-WEB-12`) or numeric
  id. **Some shortIds 404**; on 404, retry with the numeric `id` field from
  the `issues`/`errors` output. Detail includes `latestEvent` (exception
  type/value, tags, `topFrames`).
- **`releases`** — newest-first, with `newGroups` (issues first seen in that
  release). Empty `[]` is normal.

## Project targeting (fuzzy match)

`-p/--project` fuzzy-matches curated project name/slug — a unique prefix like
`-p frontend` resolves. Omit `-p` to sweep **all curated projects** in one
call. Unknown/ambiguous → **exit 2** with a candidate list on stderr; read
the suggestions, don't retry blindly. `srx projects` shows the curated list
offline; `srx projects list` shows the whole org live and marks curated ones.

## Time window & pagination

- `-S/--since` — Sentry `statsPeriod` format: `24h`, `7d`, `14d` (default
  `24h`).
- `-n/--limit` — max rows, clamped to the configured `max_limit`.
- `--all` (`issues` only) — follow Link-header pagination up to `max_limit`.

## Escape hatch: raw `query`

For anything not covered by a typed subcommand:

```bash
srx query organizations/<org>/projects/
srx query /projects/<org>/<project>/issues/ \
  --param query=is:unresolved --param statsPeriod=14d
```

`--param k=v` is repeatable; output is the raw JSON response verbatim (no
pagination, no shape guarantees) — prefer typed commands when they exist.

## Pitfalls

- **Empty `[]` is not an error** (exit 0) — a quiet project. Widen `--since`
  before assuming a broken query.
- **Some shortId lookups 404** — fall back to the numeric `id`.
- **403 / scope errors** exit `1` — the token is read-scoped; admin-only
  endpoints via raw `query` (e.g. audit logs) will 403.
- **Never print the auth token** (config file, `${SENTRY_API_KEY}`) in
  output or logs.
