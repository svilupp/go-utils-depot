# newrelicexplorer (`nrx`)

Find logs and errors in New Relic from one Go binary — built for humans and AI agents.

- **Curated services** — target by short fuzzy name (`-s agents`), not raw `entity.name`
- **Templated commands** — `logs`, `errors`, `latency`, `health`, `traces slow`, `changes`, `link` wrap the right NRQL (and avoid the `=`-is-case-sensitive trap)
- **Strict output** — valid JSON on stdout, human status on stderr; labeled units, ISO timestamps, deterministic order, meaningful exit codes

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
| `changes`       | Recent deploys / change events (account-wide; sparse; default 50/30d, truncates — use `-n 200`) |
| `link`          | Shareable NR web links for a service (permalink + filter + NRQL)        |
| `query`         | Execute raw NRQL for anything the templates don't cover                 |
| `services`      | Curated inventory; `services list` resolves to live `entity.name`(s)    |
| `schema --json` | Full machine-readable tool contract for agent bootstrap (offline)       |

Run `nrx <command> --help` for the per-command NRQL template and examples.

## For agents

The deep reference — output contract, exit codes, scoping gotchas, debugging
recipes — is in [`docs/SKILL.md`](docs/SKILL.md). Bootstrap with
`nrx schema --json` and `nrx <cmd> --help` before composing queries.

## Notes

- **Region:** EU only (`one.eu.newrelic.com`); US returns 403 (client retries once).
- **Curated services:** 17 curated services; 3 intentionally dark (non-reporting). The account ID is read from your config.
- **Gotcha:** the `ai-*` (Python/FastAPI) services log many real failures at
  **WARNING, not ERROR**, so `errors` can show `[]` while a service is failing —
  also run `nrx logs -s <svc> --level warn`. `health.errorRate` is Transaction-based
  and reads ~0% for worker/ingestion services; lead with `errors`/`logs` there.

See [CHANGELOG.md](./CHANGELOG.md) for what's new.
