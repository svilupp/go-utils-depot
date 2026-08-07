# argocdexplorer (`acx`)

Agent-facing, **read-only** ArgoCD explorer. A single Go binary that queries
the ArgoCD REST API with GET requests only — no command in this repo can
sync, delete, rollback, or otherwise mutate anything in your cluster.

## Install

```bash
eget svilupp/go-utils-depot --tag 'argocdexplorer/' --to ~/.local/bin

# Optional: short alias
alias acx='argocdexplorer'
```

## Auth

An ArgoCD **API key is the one and only auth method** — generate one in
ArgoCD (Settings → Accounts → Generate Token; it does not expire), then
run:

```bash
acx init
```

`init` prompts for the key (hidden input) and the server host — there is
no shipped default; provide your real ArgoCD host, e.g. `argocd.example.com`
— then writes `~/.config/argocdexplorer/config.yaml` (mode 0600) and runs
`acx check`.

You can instead hand-edit the config directly — see `config.example.yaml`.
The `api_key` field accepts either a literal key or a `${ENV_VAR}`
reference (e.g. `api_key: ${ARGOCD_API_KEY}`), resolved at load time. A
`.env` file in the current directory is auto-loaded before resolution, and
an already-exported shell variable always wins over it. With no `api_key`
configured, every command fails fast with a clear "no api_key configured"
message.

Each curated `services:` entry can carry an optional, entirely explicit
`nickname` — a short handle (e.g. `agents`) resolved before falling back to
substring matching over `name`. There is no autogeneration: a service with
no `nickname:` set simply has none. Run `acx schema` to see the full
inventory with its configured nicknames.

Never assume your fleet's service names — run `acx services --all` to
discover the real live application list, and `acx schema` for the curated
inventory.

### Targeting: nicknames everywhere

Every app-taking command (`get`, `status`, `triage`, `events`, `logs`,
`history`, `resources`) accepts either the exact ArgoCD application name or
a curated service name/nickname. A service target always needs `--env` too
— acx never guesses which environment you meant — and prints a
`resolved: <input> (service <name>) + --env <env> -> <app>` notice on
stderr so it's never a silent substitution. Passing a service without
`--env` is a usage error (exit 2) listing the per-environment application
names; passing `--env` alongside an exact app name is also a usage error
(there's no environment left to resolve).

```bash
acx logs gateway --env prod-eu --since 1d --tail 200
```

## Quick triage

```bash
acx check                                    # config + auth sanity check
acx services --unhealthy                     # curated services currently unhealthy or out of sync
acx status my-service                        # one service, every environment
acx triage prod-eu-my-service                # the one-shot debugging view
acx get <app>                                # curated single-app summary
acx history <app> -n 5                       # recent deploys + commit metadata
acx resources <app> --unhealthy              # which resources are unhealthy, and why
acx events <app> --warnings-only             # recent k8s Warning events
acx logs <app> --tail 100                    # container logs (bounded, one-shot fetch)
acx schema                                   # full machine-readable contract
```

`acx logs <app>` is the fastest way to get pod logs, period — one bounded
GET, no `kubectl` context switch and no SSO dance. Key flags: `--tail`
(lines, min 1, default 100), `--filter` (server-side, case-insensitive
substring), `--since` (time window), `--pod`/`--container` (pin a
specific one), `--previous` (crashed/restarted instance). **Footgun:**
`--tail` truncates the raw log *before* `--filter` runs, so a small
`--tail` combined with `--filter` can silently return `[]` even when
matches exist further back — always pair `--filter` with a large `--tail`
(500+). `<app>` accepts either the exact ArgoCD app name or a curated
service/nickname (with `--env`) — see "Targeting" below. `--since` also
accepts a day unit, e.g. `--since 1d`.

### Triage examples

```bash
# curated unhealthy apps, scoped to one region
acx apps --env prod-eu --unhealthy 2>/dev/null | jq .
acx apps --env prod-us --unhealthy 2>/dev/null | jq .

# chained: find the worst app, triage it, then pull filtered logs
app=$(acx apps --unhealthy 2>/dev/null | jq -r '.[0].name')
acx triage "$app" 2>/dev/null | jq '{health, sync}'
acx logs "$app" --since 1h --filter error --tail 500 2>/dev/null | jq .
```

`services` (aliases: `apps`, `list`) defaults to a **curated, fleet-filtered
view**: only applications that actually correspond to a configured service
are shown, matched case-insensitively at a strict boundary (exact
env-pattern expansion, a `-`+service suffix, or an exact name match) --
not a free-form substring anywhere in the name, so a configured
`my-service` won't also match `...-my-service-tenant-a`.
Pass `--all` to see the full ArgoCD fleet, including anything not in
your curated list. With no `services:` configured, there's nothing to
filter to, so `acx services` returns an empty list (`[]`) and prints a
stderr hint pointing at configuring `services:` or passing `--all`.

## Output contract

- stdout is valid JSON for every subcommand's output — `[]` on empty
  results, never prose. `--help`/`--version` and a bare (no-subcommand)
  invocation are exempt and print human usage text instead.
- stderr carries human status/warnings/hints only.
- `--human` renders a human-friendly, width-aware terminal table instead
  of JSON — use it when a person is reading the output directly, never
  when piping to `jq` or another program (agents/scripts should always use
  the default JSON). Example pair:

  ```bash
  acx apps --unhealthy 2>/dev/null                # JSON: [{"env":"dev",...}, ...]
  acx apps --unhealthy --human 2>/dev/null         # table: NAME  ENV  HEALTH  SYNC
  ```
- Exit codes: `0` success (including empty `[]`), `1` runtime error
  (API/auth/network), `2` usage error (bad flags, unknown/ambiguous
  service, wrong arity).

See `docs/using-argocdexplorer-cli/SKILL.md` for the full agent playbook.
