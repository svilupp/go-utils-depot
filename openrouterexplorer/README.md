# openrouterexplorer (`orx`)

Browse the OpenRouter model catalog under a saved price/privacy **policy**, read
the true per-call cost and which provider served a request, and run completions
through that policy from one Go binary. `openrouterexplorer` (alias `orx`) talks
the public OpenRouter REST API directly and is built for agents: **valid JSON on
stdout, human status on stderr**, with the full contract self-described by
`--help` and `orx schema --json`.

- **Two-layer policy** - one YAML intent compiles to both a catalog filter
  (`GET /models`) and a request-side `provider{}` routing object (the "no
  training" switch lives here).
- **True cost accounting** - `orx gen <id>` returns `total_cost`,
  `provider_name`, and `data_region` for any non-fusion generation.
- **Strict output** - bare JSON arrays, object for single records, labeled
  units, deterministic order, meaningful exit codes.

## Install

```bash
eget svilupp/go-utils-depot --tag 'openrouterexplorer/' --to ~/.local/bin

# Optional: short alias
alias orx='openrouterexplorer'
```

Verify with `orx --version`.

## Quick start

```bash
export OPENROUTER_API_KEY=sk-or-...
orx init                          # writes ~/.config/openrouterexplorer/config.yaml (0600), offers `orx` alias
orx check                         # free preflight: validates config + auth (cheap GET /credits)
orx models 2>/dev/null | jq       # the catalog as JSON
```

If `orx` isn't aliased, call `openrouterexplorer` directly.

## Output contract

Canonical pattern: `orx <cmd> ... 2>/dev/null | jq .`

- **stdout is always valid JSON.** List commands emit a bare array (`[]` when
  empty); single-record commands (`model`, `credits`, `gen`, `schema`, `check`,
  `init`, and the billable `chat`/`fusion`/`replay`) emit an object. One encode
  choke point - never blank, never truncated silently.
- **stderr is human-only**, prefixed `request:` / `note:` / `warning:` / `hint:`
  / `error:`. It echoes the resolved backend request (compiled query string for
  `models`, the `provider`/`plugins` object for `chat`/`fusion`). **Never parse
  stderr.**
- **`--human`** (global) renders human-readable stdout for a terminal - an
  aligned table for arrays, key/value lines for a single object. Reading only:
  JSON stays the default agent contract, so don't parse `--human` output.
- Honors `NO_COLOR` and `--no-color`; colorizes stderr only on a real TTY.

```bash
orx credits --human          # remaining / total_credits / total_usage as key/value lines
orx rankings -n 5 --human    # an aligned leaderboard table
```

### Exit codes

Branch on these.

| Code | Meaning | Examples |
| ---- | ------- | -------- |
| `0`  | Success, including an empty `[]` | a result, or over-constrained filters that legitimately match nothing |
| `1`  | Runtime failure | API / auth / billing / network / no route |
| `2`  | Usage error | bad or missing flag, bad arity, unknown slug, price-scale typo, missing `--yes` on a billable command |

Every input is validated at the command boundary **before any API call**, so
every exit-2 path makes **zero API calls** - a bad flag never bills.

## Commands

`[$]` = billable inference (requires `--yes`; supports `--dry-run`). Everything
else is free (read-only).

| Command | Cost | What it does |
| ------- | ---- | ------------ |
| `models [query]` | free | List/filter the catalog (`GET /models`); `--count` returns cardinality |
| `model <slug>` | free | Full detail for one model; accepts `author/slug` and `:variant` (resolves to base) |
| `endpoints <slug>` | free | Per-provider endpoints for a model: price, latency, throughput, health (no data-policy field) |
| `providers` | free | Provider directory: HQ country, datacenters, policy-doc URLs (no training flag) |
| `credits` | free | `{total_credits, total_usage, remaining}` |
| `rankings [--days N]` | free | Token-share leaderboard - orx group-sums the recent daily series client-side |
| `benchmarks` | free | External leaderboard scores (usually redundant; scores inline in `model`) |
| `gen <id>` | free | Per-call accounting: `total_cost`, `provider_name`, `data_region`, tokens, latency |
| `schema --json` | free | Offline machine-readable contract (no API call) for agent bootstrap |
| `check` | free | Validate config + auth (`GET /credits`); echo the compiled catalog/routing filters |
| `init` | free | Write/preserve config (hidden token input, 0600), offer the `orx` alias |
| `chat <slug> "msg"` | `[$]` | One completion through the policy's provider routing |
| `fusion "msg"` | `[$]` | Multi-model fusion (`openrouter/fusion`): a panel answers, a judge synthesizes |
| `replay <trace\|chat>` | `[$]` | Build the provider/fusion object, hand off to `logfire-trace replay --provider openrouter` |

Run `orx <command> --help` for the per-command request template, flag units, and
examples.

### Global flags

| Flag | Effect |
| ---- | ------ |
| `--profile` / `-p` | Config profile to use (default `default_profile`) |
| `--policy` | Named policy to compile (default `defaults.default_policy`) |
| `--limit` / `-n` | Max rows to print (`0` = no client-side limit) |
| `--refresh` | Bust the catalog cache before reading |
| `--human` | Render stdout as a table/key-value for terminals (not for parsing) |
| `--no-color` | Disable ANSI color on stderr (also honors `NO_COLOR`) |
| `--dry-run` | Billable commands only: print the compiled request, send nothing |
| `--yes` | Billable commands only: confirm and actually send |

### Examples

```bash
# Cheap, tool-capable models under a policy - just the ids
orx models --policy cheap-safe --sort pricing-low-to-high 2>/dev/null | jq -r '.[].id'

# The true cost of one call and which provider served it
orx gen <generation_id> 2>/dev/null | jq '{cost: .total_cost, provider: .provider_name, region: .data_region}'

# Compile a chat under the default policy and send NOTHING (free preview)
orx chat deepseek/deepseek-chat "ping" --dry-run 2>/dev/null | jq .
```

## Three price scales (read this before filtering)

> **Warning - three different price scales. Do not mix them.**
>
> | Source | Scale | Form |
> | ------ | ----- | ---- |
> | model `pricing.*` (reported per model) | **$ per TOKEN** | STRINGS, e.g. `"0.0000004"` |
> | catalog filter flags `--max-price-completion`, `--min-price` (and `catalog.*` in config) | **$ per MILLION tokens** | NUMBERS |
> | policy `routing.max_price.*` -> `provider.max_price` in the chat body | **$ per MILLION tokens** | sent as STRINGS on the wire |
>
> The flags and config fields you set are **$ per million tokens**. A value under
> `0.001` is almost certainly a `$/token` figure - multiply by `1e6`. orx rejects
> such values with exit 2 before any API call.

## Policy: one intent, two layers

A named policy in your config compiles to two API layers (plus an optional
fusion preset), selected with `--policy NAME`:

- **Layer A - catalog prefilter** (`catalog:` -> `GET /models` query): *surface
  only models worth considering.* Affects what you **browse**.
- **Layer B - request-time routing** (`routing:` -> the `provider{}` object in
  `POST /chat/completions`): *bind the actual route.* Affects what **runs**.
  This is where **"no training"** is enforced via `routing.data_collection:
  deny` - because that posture is not readable anywhere in the API.

`data_collection: deny` is **enforce-only**: the router binds it, but no
response or generation field reports it back, so orx enforces and trusts - it
never fabricates a "does not train" badge.

See [`openrouterexplorer.example.yaml`](openrouterexplorer.example.yaml) for the
fully annotated starter config (this is what `orx init` seeds).

## For agents

The full reference - output contract, exit-code branching, the two-layer policy
engine, the `logfire-trace` replay loop, and gotchas - is in
[`docs/using-openrouterexplorer-cli/SKILL.md`](docs/using-openrouterexplorer-cli/SKILL.md).
Bootstrap with `orx schema --json` and `orx <cmd> --help` before composing
commands; `orx schema --json` is generated from the same builders the runtime
uses, so it cannot drift.

## Notes

- **Fusion generation ids 404 for ~5 minutes.** Read fusion cost from the chat
  response `usage.cost`, not from `orx gen <id>`. Non-fusion gen ids resolve
  immediately.
- **Credits are eventually consistent.** `GET /credits.total_usage` lags ~1
  call; trust the chat response `usage.cost` over an immediate `orx credits`
  re-read.
- **`replay` execs an external binary.** It hands off to `logfire-trace replay
  --provider openrouter`; if the `logfire-trace` CLI is not on `PATH`, `replay
  --yes` exits 1. Install the logfire-trace CLI before a real replay. `--dry-run`
  just prints the planned invocation and execs nothing.
- **`rankings` is a recent daily window.** OpenRouter's analytics endpoint serves
  a raw per-day x model series over a recent window; `--days N` requests the
  lookback (start = today - N, end = today, UTC) but the API returns what it has.
  orx groups by model, sums prompt + completion tokens, and ranks by tokens.
- **Data policy is enforce-only, not observable.** `data_collection: deny` is
  bound and trusted; there is no field or badge anywhere in REST that confirms a
  provider does not train.
- **Provider names are case-sensitive display names** (`Anthropic`, `Groq`,
  `Mistral`), not slugs - both `--providers` and `routing.only/ignore` want
  these.
- **`output_modalities` defaults to `text`** - image/audio/embedding models are
  hidden unless you set it explicitly.
- **`category` and `supported_parameters` are mutually exclusive on `/models`.**
  OpenRouter returns HTTP 400 if both are sent, so orx pre-empts it with a clean
  exit 2 (zero API calls). The seeded `balanced`/`cheap-safe` catalogs filter by
  `category`; tool-capability is enforced at the routing layer via
  `routing.require_parameters`, not in the catalog.

See [CHANGELOG.md](./CHANGELOG.md) for what's new.
