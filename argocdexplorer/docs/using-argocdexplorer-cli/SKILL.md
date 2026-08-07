---
name: using-argocdexplorer-cli
description: >-
  Operate the argocdexplorer (acx) CLI to debug ArgoCD applications — health,
  sync status, resources, events, and deploy history — across environments.
  Read-only; no mutating calls. Covers the stdout-JSON / stderr-human
  contract, service fuzzy matching, the status/triage workflow, and the raw
  query escape hatch. Triggers: "acx", "argocdexplorer".
---

# Using the ArgoCD Explorer CLI (`acx`)

`acx` (binary `argocdexplorer`) is a **read-only** ArgoCD debugging tool:
**valid JSON on stdout, human status on stderr**. It cannot sync, delete,
rollback, or otherwise mutate cluster state — every request it issues is an
HTTP GET. If anything looks broken, run `acx check` first (config + auth
validation); if auth fails, see the project README.

**Never assume service names.** Every service/app name in this doc
(`my-service`, `prod-eu-my-service`, etc.) is a generic placeholder — run
`acx services --all` to discover the real live fleet, and `acx schema` for
the curated names/nicknames configured for this deployment.

## Output contract

Canonical pattern: `acx <cmd> ... 2>/dev/null | jq .`

- **stdout is valid JSON** for every subcommand's output — a bare array
  (`[]` on empty results, never blank) for list-shaped commands, or an
  object for `get`/`triage`/`check`/`schema`. `--help`/`--version` and a
  bare (no-subcommand) invocation are exempt and print human usage text
  instead.
- **stderr is human-only** — `error:`/`hint:`/`warning:` lines. Never parse it.
- **`--human`** (global) renders human-readable output — never use it when
  piping.
- **Exit codes**: `0` success, **including empty `[]`**; `1` runtime error
  (missing/rejected API key, API/network failure); `2` usage error (bad flag,
  unknown/ambiguous service) — caught before any API call.

## Quick-triage workflow

```bash
acx services --unhealthy                                # curated services currently broken, fleet-wide
acx status my-service                                   # one service, health/sync per environment
acx triage prod-eu-my-service                            # the one-shot: status+conditions+bad resources+events+revision
acx get <app>                                            # curated single-app summary (small)
acx resources <app> --unhealthy                          # which k8s resources are unhealthy, and their message
acx events <app> --warnings-only                         # recent Warning events
acx logs <app> --tail 100                                # container logs (bounded, one-shot fetch)
acx history <app> -n 5                                   # recent deploys + commit author/message/date
```

- **`triage`** is the one-shot: it combines the app's health/sync/
  conditions/last-operation with non-Healthy resource-tree nodes, recent
  Warning events, and revision metadata (author/message/date) in a single
  call — start here for "what's wrong with this app right now".
- **`status <service>`** resolves a curated service name (fuzzy: exact name
  first, then unique substring) and reports health/sync for every
  configured environment in one array. **Absent environments are
  `present:false`, not an error** — not every service is deployed
  everywhere. When the constructed app name 404s/403s, `status` also
  falls back to a full app-list scan for exactly one
  `{env-prefix}...-{service}` match (dev app names embed an arbitrary
  ApplicationSet slug the naive pattern can't predict) — the row's `app`
  field reflects whichever name was actually resolved.
- **`services`** (aliases: `apps`, `list`) is the projected list. By
  default it's filtered to curated services — rows whose application
  name matches a configured service (config.yaml's `services:` list) at
  a strict, case-insensitive boundary: exact env-pattern expansion, a
  `-`+service suffix, or an exact name match — NOT a free-form substring
  anywhere in the name (a configured `my-service` won't also
  match `...-my-service-tenant-a`) — pass `--all` to see the full fleet instead, including
  applications that aren't in your curated list; when no services are
  curated (no config, or an empty `services:` list) there's nothing to
  filter to, so the result is an empty list (`[]`) plus a stderr hint
  pointing at configuring `services:` or passing `--all`. `--env` filters by application-name PREFIX
  (case-insensitive, client-side — env isn't a server-side ArgoCD
  property; "prod" matches `prod-*` but not `other-prod` or names that
  merely contain "prod" mid-name), `--project`
  filters server-side (repeatable), `--unhealthy` keeps only
  health!=Healthy or sync!=Synced.

## Logs

```bash
acx logs <app>                                            # last 100 lines, all pods/containers
acx logs <app> --tail 20                                  # fewer lines
acx logs <app> --filter error --since 1h                  # server-side substring filter + time window
acx logs <app> --pod <pod> --container <container>        # pin to a specific pod/container
acx logs <app> --previous                                 # the crashed/restarted container instance
```

`logs` is a **bounded, one-shot fetch** — it always sends `follow=false`
and never streams; it's not a `kubectl logs -f` replacement. Omit `--pod`
to fetch across all of the app's pods, omit `--container` to let ArgoCD
pick. Rows are `{"time", "pod", "content"}`; an empty result (e.g. an
overly specific `--filter`) is `[]`, exit 0, not an error. `<app>` accepts
a curated service/nickname too (with `--env`) — see "Targeting" below.
`--since` accepts a day unit too, e.g. `--since 1d`.

- **`--filter` is server-side, case-insensitive, literal substring** — not
  regex; `.` and `*` match themselves, not "any char"/"repeat".
- **Order of operations footgun**: ArgoCD applies `--tail` (tailLines) to
  the RAW log first, THEN applies `--filter` within that truncated window.
  `--filter error --tail 5` can return `[]` even when errors exist further
  back in the log. **Always pair `--filter` with a large `--tail` (500+)**;
  raise it further if you expect matches and get none.
- `--tail` must be >= 1 (0/negative is a usage error, exit 2); an explicit
  `-n/--limit` only caps rows further if it's set *lower* than `--tail`.
- With multiple pods, logs from all of them are merged and globally
  time-ordered; a stale/wrong `--pod` name silently returns `[]`, not an
  error.
- **Apps with no running pods** (OutOfSync, scaled to zero, Job-only) make
  the ArgoCD logs endpoint hang until acx's ~30s timeout — check
  `acx resources <app>` first, or narrow with `--pod`/`--since` to avoid
  the stall.
- A wrong `--container` is a clean error, exit 1 (not a silent empty
  result). Some services run a `cloud-sql-proxy` sidecar — use
  `--container` to target the app container specifically there.
- `--previous` fetches the previous (crashed/restarted) container
  instance — pair with `--pod` after spotting a crash-looping pod via
  `acx resources <app> --unhealthy`.

### Log formats

Most Node services emit structured JSON (pino): numeric `level` (30=info,
40=warn, 50=error), `time` (ms epoch), `req{method,url}`, and a `payload`
carrying `trace_id`/`span_id`. Some Python services emit structured logs
(`event`, `level`, `logger`) instead, and a few additionally mix in plain
SQL/uvicorn text lines alongside their structured ones — check a sample
line before assuming pino JSON.

### Finding problems fast

Issue-class filter cheat sheet (always with `--since` + a large `--tail`;
`--filter` is case-insensitive so one casing suffices):

| symptom | `--filter` |
|---|---|
| crash | `panic` (or add `--previous`) |
| timeout | `deadline`, `timeout` |
| connection failure | `econnrefused`, `connection reset` |
| memory kill | `oomkilled` (cross-check `acx events`) |
| auth failure | `401`, `403` |
| server error | `500` |

Best jq recipes against pino/JSON log content:

```bash
# errors/warnings only
acx logs <app> --tail 500 2>/dev/null | jq -r '.[].content | fromjson? | select(.level >= 40) | .msg'

# HTTP requests
acx logs <app> --tail 500 2>/dev/null | jq -r '.[].content | fromjson? | .req | select(.) | "\(.method) \(.url)"'

# trace correlation
acx logs <app> --tail 500 2>/dev/null | jq -r '.[].content | fromjson? | .payload.trace_id | select(.)'

# rows per pod (spot an imbalanced/crash-looping pod)
acx logs <app> --tail 500 2>/dev/null | jq -r '.[].pod' | sort | uniq -c
```

### Searching for errors

**`--filter error` is NOT a reliable generic sweep on our pino/JSON logs — it
both over- and under-matches.** Tested on production Node services with a
single fetch (`--tail 2000`, immediately compared, since the tail window
keeps moving on live pods):

- Over-match: on one service, `--filter error` returned dozens of rows
  with `level:50` in that window — but only because the framework's
  exception payload always embeds keys like `error.stack`/`error.message`/
  `errorCode`, not because "error" appears in the message text.
- Under-match (the real gap): on another service, a `level:40` (warn) row
  with an authentication-related message contains no literal "error"
  substring anywhere and is silently missed by `--filter error`, while it
  IS caught by `select(.level>=40)`.
- **The reliable generic sweep is the numeric pino level via jq, not
  `--filter error`.**

```bash
# 1. Reliable generic sweep: numeric level, not text (works for all pino/JSON services)
acx logs <app> --since 1h --tail 1000 2>/dev/null | jq -r '.[].content | fromjson? | select(.level>=40) | "\((.time/1000|todate)) \(.level) \(.message)"'

# 2. Specific-error drill-down: distinctive substring narrows fast and precisely
acx logs <app> --since 6h --tail 500 --filter "id-token-expired" 2>/dev/null | jq length

# 3. Narrow to one request via trace_id (near-exact match, tiny result)
acx logs <app> --since 1h --tail 500 --filter "<trace.id-value>" 2>/dev/null | jq -r '.[].content | fromjson? | {time,level,message}'

# 4. Two-stage pattern: server-side substring cuts volume, jq imposes structure/level threshold
acx logs <app> --since 6h --tail 2000 --filter error 2>/dev/null | jq -r '.[].content | fromjson? | select(.level>=40) | "\(.time) \(.message)"'

# 5. Traceback / stack trace retrieval (a Python API service): one row per physical line
acx logs <app> --since 72h --tail 3000 --filter Traceback 2>/dev/null | jq -r '.[].pod, .[].time'   # locate the pod + rough timestamp
acx logs <app> --since 72h --tail 3000 --pod <pod-from-above> 2>/dev/null \
  | jq -r '.[] | select(.time>="<ts-5s>" and .time<="<ts+30s>") | .content'   # re-fetch that pod, narrow --since to the window, read unfiltered for full context

# 6. Crash-restart logs
acx logs <app> --pod <pod> --previous 2>/dev/null
```

Empty output from the sweep (recipe #1) is normal and healthy — no warn/error rows in the window, exit 0. If you expect errors, widen `--since` (e.g. `24h`) or try a busier app before concluding the pipeline is broken.

- A `--filter` hit only gives you one line at a time; for multi-line Python
  tracebacks, use the hit's `pod` + `time` to re-fetch that single pod
  **without** `--filter` and slice by a tight `--since`/time-range in jq —
  don't rely on `--filter Traceback` alone, it only returns the header line.
- `--previous` cleanly returns a content row like `"previous terminated
  container ... not found"` (not an error, exit 0) when the pod hasn't
  actually restarted — e.g. an `ErrImagePull`/`ImagePullBackOff` pod that
  never started a container has no previous instance to show.
- Because `acx logs` is a **one-shot fetch against a live, moving tail**,
  don't compare two separate invocations (one filtered, one not) as if
  they saw the same window — fetch once, save to a file, and run multiple
  jq queries against that single snapshot instead.

Playbooks:

1. **Anything broken?** `acx services --unhealthy` -> `acx triage <worst-app>` -> `acx logs <app> --since 1h --filter error --tail 500`
2. **Service erroring in prod:** `acx status <nickname>` -> pick the prod row's `app` -> `acx triage <app>` -> filtered logs -> `acx events <app> --warnings-only`
3. **What changed:** `acx history <app>` (deploy author/message/date) -> `acx logs <app> --since` around the deploy time
4. **Crash-loop:** `acx resources <app> --unhealthy` -> `acx logs <app> --pod <pod> --previous`
5. **Env comparison:** `app=$(acx status search 2>/dev/null | jq -r '.[] | select(.environment=="prod-eu") | .app')` then run any `<app>` command against it

## Targeting: app names vs. service names

Every app-taking command (`get`, `status`, `triage`, `events`, `logs`,
`history`, `resources`) accepts either identifier in its `<app>`
argument:

- **The exact ArgoCD application name**, e.g. `prod-eu-my-service`. Get it
  from `acx services` (aliased as `acx apps`/`acx list`). Passing `--env`
  alongside a literal app name is a usage error (exit 2) — there's no
  environment left to resolve.
- **A curated service name or nickname** (e.g. `my-service`, or its
  nickname `search`) — resolved against
  `~/.config/argocdexplorer/config.yaml`'s `services:` list in order:
  exact name -> exact nickname -> unique case-insensitive substring over
  name+nickname. A nickname is a plain optional config field — there is no
  autogeneration; a service with no `nickname:` set simply has none. Run
  `acx schema` to see every curated service's configured nickname. If no
  services are curated, the literal input is trusted as-is, and
  `acx services` shows the full fleet by default.

  **A service target always requires `--env` too** — acx never guesses
  which environment you meant. Omit it and you get a usage error (exit 2)
  listing the per-environment application names, so you can pick one or
  fall back to a literal app name. `--env` resolves against configured
  environment names (exact match, or a unique case-insensitive substring —
  `prod` is ambiguous between `prod-eu`/`prod-us`, exit 2; `eu` or
  `prod-eu` is unique).

  **Resolution is never silent.** Whenever a service+`--env` target
  actually resolves to a different application name, acx prints a
  `resolved: <input> (service <name>) + --env <env> -> <app>` line on
  stderr, and `get`/`triage` additionally add a `"resolved":
  {"input", "service", "environment", "app"}` field to their JSON object.
  Array-shaped commands (`events`/`logs`/`history`/`resources`) only get
  the stderr notice — row shape is unchanged.

  ```bash
  acx logs gateway --env prod-eu --since 1d --tail 200
  ```

Naming convention (per environment, from `environments:` patterns — edit
these to match your fleet): `dev-<service>-<service>` as the naive default
pattern (though real dev app names embed an arbitrary ApplicationSet slug,
e.g. `dev-abc12-my-service` — resolution falls back to a full app-list scan
for exactly one `dev-...-<service>` match), `uat-<service>`,
`prod-eu-<service>`, `prod-us-<service>`.

## Escape hatch: raw `query`

For anything not covered by a typed subcommand:

```bash
acx query /api/v1/applications/<app>/manifests
acx query /api/v1/projects --param name=my-project
```

`--param k=v` is repeatable; output is the response body decoded and
re-encoded as JSON (not a byte-for-byte passthrough). The client only ever
issues GET; `query` additionally refuses paths containing `/sync`,
`/rollback`, `/delete`, `/terminate` as a defensive belt-and-suspenders
(exit 2).

## Pitfalls

- **Empty `[]` is not an error** (exit 0) — e.g. a service with no Warning
  events recently.
- **`{"items": null}`** from `services` on a query that matches nothing is
  normal, handled transparently — never surfaces as an error or a crash.
- **Multi-source apps**: `status.sync.revision` (string) may instead be
  `status.sync.revisions` ([]string) for multi-source applications; every
  command that reads a revision handles both shapes.
- **`fields` projection on the list endpoint (`/api/v1/applications`) must
  request `items.status.health`, NOT the deeper `items.status.health.status`.**
  The deeper projection silently drops the health field entirely on this
  ArgoCD version — no error, just missing data. Relevant if you use the
  `query` escape hatch against the list endpoint directly.
- **Auth failures**: `acx check` reports config + auth problems clearly on
  stderr.
- **Never print the API key** in output or logs; no command ever echoes it.
- This binary is structurally read-only — if you need to actually sync/
  rollback/delete something, use the real `argocd` CLI, not `acx`.
