---
name: using-openrouterexplorer-cli
description: >-
  Operate the openrouterexplorer (orx) CLI to explore and act on OpenRouter:
  browse and search the model catalog, compare model pricing and context
  windows, list providers and per-model endpoints, check the credit balance, and
  pull usage rankings and benchmarks; send chat or multi-model fusion
  completions through a saved policy that compiles to OpenRouter's provider
  routing (price ceilings, "no training"/data_collection, region, required
  parameters); and replay recorded production traces against OpenRouter via
  logfire-trace.
  Use when working with openrouterexplorer or orx, OpenRouter models/pricing,
  deciding which model or provider on OpenRouter to use, defining an OpenRouter
  routing policy, or sending OpenRouter chat/fusion requests.
---

# Using the OpenRouter Explorer CLI (`orx`)

`openrouterexplorer` (alias `orx`) is a thin, REST-direct wrapper around a subset
of the OpenRouter API, built for agents. It browses the model catalog and
compiles a saved YAML **policy** to OpenRouter's two layers: **Layer A — catalog
filters** (`GET /models`) and **Layer B — a request-side `provider` routing
object** embedded in `POST /chat/completions`, plus an optional **fusion** preset.
It also closes the `logfire-trace` replay loop by routing recorded
conversations through OpenRouter. If `orx` isn't aliased, run `openrouterexplorer`.

## Setup (once)

```bash
export OPENROUTER_API_KEY=sk-or-...
orx init     # write ~/.config/openrouterexplorer/config.yaml (0600), seed starter policies, offer the `orx` alias
orx check    # free preflight: validate config + auth, echo the compiled policy
```

`init` is env-first (stores the `${OPENROUTER_API_KEY}` reference when the env var
is set; otherwise `--api-key <literal>` or a hidden paste) and seeds the starter
policies `balanced`, `cheap-safe`, `deep`. The annotated starter config is
`openrouterexplorer.example.yaml`; select a policy with `--policy NAME`.

## Output contract (the agent rules)

Canonical idiom: `orx <cmd> 2>/dev/null | jq`

- **stdout is always valid JSON.** Row commands emit a bare array (`[]` when
  empty, never blank); single-record commands emit an object.
- **stderr is human-only**, prefixed `request:` / `note:` / `warning:` / `hint:`
  / `error:`. **Never parse stderr.**
- **Exit codes** (branch on these): `0` success incl. empty `[]`; `1` runtime
  (auth/credits/rate-limit/no-route/network/bad-config); `2` usage (bad flag,
  bad arity, unknown slug/enum, price-scale typo, billable without `--yes`).
  **Every exit-2 path is validated before any API call — it makes zero API calls.**
- **`--human`** renders an aligned table for reading only — do **not** parse it.

## Commands

`[$]` = billable inference. Everything else is free (read-only). Run
`orx <cmd> --help` for flags, the compiled request shape, and examples.

| Command | What it does |
|---|---|
| `orx models [query]` | list/search the catalog under the policy's Layer-A filters |
| `orx model <slug>` | full detail for one model (pricing, context, modalities, params) |
| `orx endpoints <slug>` | per-provider endpoints: price, latency, throughput, uptime, quant |
| `orx providers` | providers: HQ country, datacenter regions, policy-doc URLs |
| `orx rankings` | token-share leaderboard aggregated from the daily series |
| `orx benchmarks` | external benchmark leaderboards (also inline in `model`/`models`) |
| `orx credits` | account balance `{total_credits, total_usage, remaining}` |
| `orx gen <id>` | per-call accounting: `total_cost`, `provider_name`, `data_region`, tokens |
| `orx check` | validate config + auth; echo the compiled catalog + routing |
| `orx init` | write config, seed policies, offer alias (no API call) |
| `orx schema --json` | offline machine contract (no API call, no config) |
| `orx chat <slug> "msg"` | `[$]` one completion via the policy-routed `provider` object |
| `orx fusion "msg"` | `[$]` multi-model panel + judge via `openrouter/fusion` |
| `orx replay <trace\|chat>` | `[$]` hand off to `logfire-trace replay --provider openrouter` |

## Gotchas

- **Three price scales — the #1 mistake.** `model.pricing.*` = **$/token STRING**;
  catalog `?max_price`/`?min_price` (the `--max-price-completion`/`--min-price`
  flags) = **$/M NUMBER**; `provider.max_price.*` = **$/M STRING**. Convert
  $/token → $/M with ×1e6. A $/M flag that is non-zero but `< 0.001` is rejected
  as a likely $/token typo (exit 2).
- **`/models` rejects `category` + `supported_parameters` together** → clean exit
  2, zero API calls. Filter by `category` in the catalog and enforce tool
  capability at request time via `routing.require_parameters`.
- **Billable guard.** `chat`/`fusion`/`replay` require `--yes` to send; without it
  (and without `--dry-run`) → exit 2, zero requests. `--dry-run` prints the
  compiled request/invocation and sends nothing — use it to verify a policy.
- **Fusion cost.** Fusion generation ids **404 for ~5 min** — read cost from the
  chat response `usage` (`usage.cost`), not `orx gen`.
- **Credits are eventually consistent** (`total_usage` lags ~1 call) — trust a
  chat response's `usage.cost` for an immediate per-call figure.
- **`data_collection: deny` is the "no training" switch** — enforce-and-trust: the
  router binds it, but no field/badge reports it back (there is no
  training/retention field in `/providers` or `/endpoints`).
- **`output_modalities` defaults to `text`** — image/audio/embedding models are
  hidden unless you set it explicitly. Easy silent miss.
- **`replay` hands off to `logfire-trace`** — the `logfire-trace` CLI must be
  installed and on `PATH`, or `replay --yes` exits 1.

Authoritative machine contract: `orx schema --json`. Per-command detail:
`orx <command> --help`.
