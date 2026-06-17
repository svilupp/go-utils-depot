# newrelicexplorer (`nrx`)

Find logs and errors in New Relic from one Go binary. `newrelicexplorer` (alias
`nrx`) queries NerdGraph/NRQL for the EU account and is built for agents: **valid
JSON on stdout, human status on stderr**, with the full contract self-described
by `--help` and `nrx schema --json`.

- **Curated services** - target by short fuzzy name (`-s agents`), not raw `entity.name`.
- **Templated commands** - `logs`, `errors`, `latency`, `health`, `traces slow`,
  `changes`, `link` wrap the right NRQL (and avoid the `=`-is-case-sensitive trap).
- **Strict output** - bare JSON arrays, labeled units, ISO timestamps, deterministic
  order, meaningful exit codes.

## Install

```bash
eget svilupp/go-utils-depot --tag 'newrelicexplorer/' --to ~/.local/bin

# Optional: short alias
alias nrx='newrelicexplorer'
```

## Quick start

```bash
NEW_RELIC_API_KEY=... nrx init   # writes ~/.config/newrelicexplorer/config.yaml (0600), offers `nrx` alias
nrx check                        # confirm auth + account + region
nrx services                     # curated inventory (offline)
nrx logs -s agents --level error --since 1h
nrx errors -s checkout --since 6h
nrx logs -s agents --level error --since 1h --human   # same query, readable table
```

If `nrx` isn't aliased, call `newrelicexplorer` directly.

## Commands

| Command         | What it does                                                            |
| --------------- | ----------------------------------------------------------------------- |
| `init`          | Interactive config setup (hidden API key, 0600, offers `nrx` alias)     |
| `check`         | Validate config + region + auth (runs `SELECT 1`)                       |
| `logs`          | Flagship: find a log that says X, or an error log, for a service        |
| `errors`        | Top error messages for a service, grouped by message (FACET)            |
| `latency`       | Latency percentiles over time (`duration` in **seconds**)               |
| `health`        | One-shot throughput / error rate / RPM / latency snapshot               |
| `traces slow`   | Slowest spans above a threshold (`duration.ms` in **milliseconds**)     |
| `changes`       | Recent deploys / change events (account-wide; sparse; default 50/30d, truncates - use `-n 200`) |
| `link`          | Shareable NR web links for a service (permalink + filter + NRQL)        |
| `query`         | Execute raw NRQL for anything the templates don't cover                 |
| `services`      | Curated inventory; `services list` resolves to live `entity.name`(s)    |
| `schema --json` | Full machine-readable tool contract for agent bootstrap (offline)       |

Run `nrx <command> --help` for the per-command NRQL template and examples.

## Human-readable output

JSON on stdout is the default (the agent contract). The global `--human` flag
renders an aligned table instead, on every data command: `logs`, `errors`,
`services`, `services list`, `latency`, `health`, `traces slow`, `changes`,
`link`, `query`. Nested values (e.g. `percentile.duration`) render as `key=value`
in a cell; `link` renders a FIELD/VALUE table. `--human` doesn't apply to
`init`/`check` (own output) or `schema` (use `--json`).

```bash
nrx services                                          # JSON (default; for agents/pipes)
nrx services --human                                  # aligned table (for humans)
nrx logs -s agents --level error --since 1h --human   # table of matching logs
nrx health -s agents --human                          # snapshot as a readable table
```

`-n`/`--limit` applies to `services` and `services list` too.

## For agents

The full reference - output contract, exit codes, scoping gotchas, debugging
recipes - is in
[`docs/using-new-relic-explorer-cli/SKILL.md`](docs/using-new-relic-explorer-cli/SKILL.md).
Bootstrap with `nrx schema --json` and `nrx <cmd> --help` before composing queries.

## Notes

- **Region:** EU only (`one.eu.newrelic.com`); US returns 403 (client retries once).
- **Curated services:** 17 curated services; 3 intentionally dark (non-reporting). The account ID is read from your config.
- **Gotcha:** the `ai-*` (Python/FastAPI) services log many real failures at
  **WARNING, not ERROR**, so `errors` can show `[]` while a service is failing -
  also run `nrx logs -s <svc> --level warn`. `health.errorRate` is Transaction-based
  and reads ~0% for worker/ingestion services; lead with `errors`/`logs` there.

See [CHANGELOG.md](./CHANGELOG.md) for what's new.
