# sentryexplorer (`srx`)

Triage Sentry issues, errors, and releases from one Go binary.
`sentryexplorer` (alias `srx`) queries the Sentry REST API and is built for
agents: **valid JSON on stdout, human status on stderr**, with the full
contract self-described by `--help` and `srx schema`.

- **Curated projects** - target by short fuzzy name (`-p frontend`), not raw slugs.
- **Templated commands** - `issues`, `errors`, `spikes`, `issue`, `releases`
  wrap the right Sentry endpoints and pagination.
- **Strict output** - bare JSON arrays, `[]` on empty results, deterministic
  order, meaningful exit codes.

## Install

```bash
eget svilupp/go-utils-depot --tag 'sentryexplorer/' --to ~/.local/bin

# Optional: short alias
alias srx='sentryexplorer'
```

## Quick start

```bash
SENTRY_API_KEY=... srx init          # writes ~/.config/sentryexplorer/config.yaml (0600)
srx check                            # confirm auth + org
srx projects                         # curated inventory (offline)
srx issues -p frontend --since 7d    # unresolved issues, this project
srx errors -p frontend --since 24h   # dominant failures, sorted by frequency
```

If `srx` isn't aliased, call `sentryexplorer` directly.

## Commands

| Command | What it does |
|---------|--------------|
| `init` | Interactive config setup (writes config.yaml 0600, runs check) |
| `check` | Validate config + confirm auth against `/organizations/{org}/` |
| `projects` | Curated project list (offline, from config) |
| `projects list` | Live project list from the API, marking curated ones |
| `issues` | Unresolved issues across curated projects (or `-p`) |
| `issue <shortId-or-id>` | Issue detail + latest event summary (stack frames, tags) |
| `errors` | Top error groupings sorted by frequency (dominant failures) |
| `spikes` | events-stats time series per project, flagging heuristic spikes |
| `releases` | Recent releases per project (recent changes) |
| `query <path>` | Raw GET against an arbitrary `/api/0/` path (escape hatch) |
| `schema` | Machine-readable tool contract dump (offline) |

Run `srx <command> --help` for per-command flags and examples.

## Config

`~/.config/sentryexplorer/config.yaml` (see `config.example.yaml`):

```yaml
auth_token: ${SENTRY_API_KEY}
org: my-org
max_limit: 500
projects:
  - name: frontend
    slug: frontend-web
    id: "1000000000000001"
    description: Web frontend
  - name: backend
    slug: backend-api
    id: "1000000000000002"
    description: API backend
  - name: mobile
    slug: mobile-app
    id: "1000000000000003"
    description: Mobile app
```

The `projects` list is the curated inventory: the handful of projects you
care about, out of a whole Sentry org. Every data command sweeps this list
by default. `-p/--project` fuzzy-matches: exact name match first, then unique
substring over name/slug - e.g. `-p frontend` resolves to `frontend`, `-p api`
to `backend` (via slug `backend-api`). `${VAR}` in `auth_token` resolves from
the shell env, then from a `.env` file in the CWD (shell env wins).

`-S/--since` accepts Sentry's `statsPeriod` format everywhere it appears,
e.g. `24h`, `14d` (default `24h`) - not seconds.

For anything a typed command doesn't cover, `srx query <path>` hits the
Sentry API directly, e.g. `srx query organizations/<org>/projects/`.

## Output contract

- stdout: valid JSON by default, `[]` on empty results, never blank.
- stderr: human status/warnings/hints only (`hint:`/`warning:`/`error:`).
- `--human` (global) renders human-readable text instead of JSON, never
  touching the JSON path: an aligned table for narrow results, or wrapped
  record blocks for wide results (adapts to terminal width).
- Exit codes: `0` success (including empty results), `1` runtime error
  (API/auth/network), `2` usage error (bad flags, ambiguous/unknown project,
  wrong arity).

```bash
srx issues -p frontend                 # JSON (default; for agents/pipes)
srx issues -p frontend --human         # human-readable (for humans)
```

## For agents

The full reference - output contract, exit codes, project targeting,
workflow recipes - is in
[`docs/using-sentryexplorer-cli/SKILL.md`](docs/using-sentryexplorer-cli/SKILL.md).
Bootstrap with `srx schema` and `srx <cmd> --help` before composing queries.

See [CHANGELOG.md](./CHANGELOG.md) for what's new.
