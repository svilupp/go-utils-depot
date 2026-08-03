# slack

A Go CLI for the Slack Web API, built agent-first: cached reads, opt-in
channel polling, and a persistent cross-process rate limiter so repeated
short-lived invocations never trip Slack's per-workspace/per-method
budgets.

The HTTP client is hand-rolled (no `slack-go` dependency) — see
`internal/slackx/`.

## Install

```bash
eget svilupp/go-utils-depot --tag 'slack/' --to ~/.local/bin
```

## Quick start

```bash
export SLACK_API_KEY=xoxp-...   # user token
slack config init
slack auth test
slack channels list
slack config add-channel general
slack poll
```

See [`docs/using-slack-cli/SKILL.md`](docs/using-slack-cli/SKILL.md) for the full command reference and
agent-oriented usage notes, and [`docs/research.md`](docs/research.md)
for the rate-limiting design this CLI implements.

## Commands

| Command | Description |
|---|---|
| `slack auth test` | Verify the token, print team/user identity |
| `slack channels list` | List conversations (cached 1h) |
| `slack users list` | List workspace users (cached 24h) |
| `slack read <channel>` | Read history or a thread's replies |
| `slack send <channel> <text>` | Post a message |
| `slack dm <user> <text>` | Open (or reuse) a DM and send |
| `slack poll` | Print new messages in the resolved watch set since last poll (fast, `search.messages`-based dirty-channel detection by default; `--full` forces a legacy full sweep) |
| `slack mentions --user <id>` | Print new workspace-wide exact `<@USER_ID>` mentions of a user since the last run (`search.messages`-based, requires `search:read` scope) |
| `slack watch list [--resolve]` | Show watch config, or the concrete resolved channel set |
| `slack watch add`/`remove <pattern-or-channel>` | Add/remove a name glob (pattern) or exact channel (pin) |
| `slack limits status` | Inspect the persisted rate-limiter state |
| `slack config ...` | init / show / add-channel / remove-channel (legacy aliases for `watch add`/`remove`) |
| `slack logs path` / `slack logs tail` | Inspect the ops/debug log |

Every read/write command supports `--json` for machine-readable output
and every command supports `--error-json` for a stable error envelope on
failure (see `internal/errs`). Exit codes: `1` internal, `2` unauthorized,
`3` not found, `4` rate limited, `5` config invalid, `8` validation error
(bad flags/args, including cobra's own unknown-command/unknown-flag
errors), `9` upstream unavailable (retryable), `10` write blocked (send/dm
refused by the `write:` policy -- see below). `read`/`poll` support
`--oldest-first`/`--cursor` for chronological output and pagination.

## Configuration

`~/.config/slack/config.yaml` (0700 dir / 0600 file):

```yaml
default_profile: default
profiles:
  default:
    api_key: ${SLACK_API_KEY}
    watch:
      channels:                 # explicit pins (id/name), always polled
        - id: C0123
          name: general
      patterns: ["proj-*", "*team*"]  # name globs
      exclude: ["proj-archive-*", "inc-*", "temp-*"] # globs, subtracted
                                 # (matches name or channel ID, case-
                                 #  insensitive; also filters ims/mpims --
                                 #  e.g. a DM's ID. Pins always win.)
      ims: true                 # include all DMs in poll (default false)
      mpims: false
      member_only: true         # default true: skip pattern matches you're not a member of
      fast: true                 # default true: use the search.messages dirty-channel detector
      reconcile_minutes: 60      # how often the fast path falls back to a full sweep anyway
    write:
      external: deny            # deny (default) | allow -- Slack Connect channels
      blocklist: []             # globs; never postable, even with --force
      allowlist: []             # if non-empty, ONLY these are postable
```

The legacy flat `channels:` list (as shown in older configs) still works
unchanged -- it's read as `watch.channels`. Having both `channels:` and a
`watch:` section on the same profile is a config error (move channels
under `watch.channels`). `slack config add-channel`/`remove-channel`
remain as aliases for `slack watch add`/`remove <exact-id-or-name>`
(they don't accept glob patterns).

Profile precedence: `--profile` > `SLACK_PROFILE` env > `default_profile`
> the sole profile if only one exists.

### Fast polling

By default `slack poll` runs a fast path: it queries `search.messages`
(a cheap detector, ~1-2 Tier-2 calls) to find which watched channels have
new activity since the last poll, then only calls `conversations.history`
for those "dirty" channels -- instead of sweeping every watched channel
every cycle. On a quiet cycle across hundreds of channels this turns a
multi-minute Tier-3 sweep into a handful of calls and a few seconds. See
[`docs/FAST_POLL_FINDINGS.md`](docs/FAST_POLL_FINDINGS.md) for the
empirical findings behind this design.

A few things to know:

- **`--full`** forces a full sweep for one invocation, bypassing the
  detector entirely.
- **`watch.fast: false`** disables the fast path for a profile
  permanently (defaults to `true`).
- **`watch.reconcile_minutes`** (default `60`) is how often the fast path
  runs a full sweep anyway, to catch anything `search.messages` might
  have missed (edited/late-indexed messages, clock skew). Persisted as
  `last_full_sweep` in the poll-state cache.
- If the detector call fails (e.g. the token is missing a `search:read*`
  scope), `poll` logs a warning to stderr and the oplog, then falls back
  to a full sweep transparently -- it never fails the whole poll just
  because search is unavailable.
- `slack poll --json` includes `"mode": "fast"` or `"mode": "full"` (plus
  a `"dirty"` count on the fast path) so you can see which path ran.
- **`--state-file /absolute/path`** uses an explicit poll checkpoint instead
  of the shared CLI cache. Durable orchestrators use this to stage a checkpoint
  and commit it with their own event store; ordinary interactive polling should
  keep using the default shared cache.
- The detector is search-based, so it also catches **thread replies** in
  a channel even though `conversations.history` itself doesn't return
  non-broadcast replies: a match whose permalink carries `?thread_ts=`
  is fetched via `conversations.replies` and delivered like any other
  new message, tagged with a `"thread_ts"` field in JSON output (and a
  `↳` prefix in text output). A separate `detector_seen` watermark is
  persisted per channel in the poll-state cache alongside `last_seen`,
  so a channel whose only new activity is a thread reply doesn't
  re-flag dirty forever once that reply has been delivered.
- If the search page cap is exhausted before the detector reaches its
  watermark (a very bursty cycle), it degrades to a full sweep for that
  cycle rather than reporting a partial dirty set.

### Mentions

`slack mentions --user <id>` finds new workspace-wide exact `<@USER_ID>`
mentions of a user since the last run, via `search.messages` -- not just
the resolved watch set `poll` covers. It requires a user token / app with
the `search:read` scope; a bot token without that scope returns a clear
error instead of crashing.

```bash
slack mentions --user U08T71B5F0F --json
slack mentions --user U08T71B5F0F --state-file /var/lib/postak/slack-mentions.json --json
```

- Like `slack poll`, the first run for a given user never backfills: it
  seeds a cursor from the newest existing mention (or now, if none) and
  returns zero results.
- Each run pages at most 5 pages / 500 matches; if the delta since the
  last run exceeds that cap, the output reports `"truncated": true` and
  deliberately does **not** advance the cursor, so the next run re-covers
  the same window instead of silently skipping mentions.
- The cursor persists to `~/.cache/slack-cli/mentions-state-<team>-<user>.json`
  (written atomically), or an explicit `--state-file` path.
- The `after:` search bound is clamped to 30 days back, so a long-stale
  cursor can't force a multi-month paginated sweep before the page cap
  kicks in.
- Broadcast tokens (`<!channel>`, `<!here>`, `<!subteam^...>`) and any
  other inexact hit are excluded: every match is re-verified with a
  literal substring check against the exact `<@USER_ID>` token before
  being returned.
- Output is oldest-first, matching `poll`'s chronological convention.

### Write safety (Slack Connect)

`send`/`dm` resolve the target channel's Slack-Connect sharing flags
(native `is_ext_shared`/`is_pending_ext_shared` detection -- channel names
are not a reliable signal) before posting, and refuse by default:

```bash
slack send partner-channel-qa "ok to ship"          # refused: externally shared
slack send partner-channel-qa "ok to ship" --force   # posts anyway
```

`write.blocklist` entries are never postable, even with `--force`.
`write.allowlist`, if non-empty, restricts posting to matches (overridable
with `--force`). Set `write.external: allow` to disable the Slack-Connect
check entirely. See `docs/POLLING_DESIGN.md` for the full design.

## Ops log

Enable a rotating NDJSON audit log at `~/.config/slack/logs/ops.log`
with `--debug`, `SLACK_DEBUG=1`, or `logging: {enabled: true}` in the
config file:

```yaml
logging:
  enabled: true    # writes (send/dm/config mutations) + errors, always
  level: ops       # or "debug" to also expand successful reads per-channel
  max_size_mb: 5
  max_files: 3
```

```bash
SLACK_DEBUG=1 slack auth test
slack logs tail -n 50
```

Writes and errors are always logged in full (message text truncated to
200 chars, token never logged); successful reads collapse to one
summary line unless `level: debug`. See
[`docs/using-slack-cli/SKILL.md`](docs/using-slack-cli/SKILL.md#ops-log) for the record shapes.
Implementation: `internal/oplog/`.

## Rate limiting

Every outgoing request is paced through a GCRA limiter persisted at
`~/.cache/slack-cli/ratelimit.json` and guarded by a file lock, so two
separate CLI invocations (e.g. two cron jobs) never both burst through
Slack's budget. `chat.postMessage` is keyed per-channel (Slack's own
~1msg/sec/channel limit); everything else is keyed per-workspace-per-method.
`slack limits status` inspects the persisted state.

On a 429 the CLI retries automatically using the server's `Retry-After`
plus jitter. If `conversations.history`/`replies` is capped to 15
messages/req at 1 req/min (unapproved/non-internal Slack app), the CLI
detects this at runtime and persists the detected tier so pacing actually
slows down, warning once per key.

## Caching

`channels-<team>.json`, `users-<team>.json`, and `poll-state-<team>.json`
under `~/.cache/slack-cli` are keyed per workspace (team ID), resolved
once via `auth.test`, so multiple profiles/workspaces sharing one
`~/.cache/slack-cli` don't cross-poison each other's name -> ID
resolution. Channels are cached 1h, users 24h; pass `--refresh` to bust
a cache early.

## Development

```bash
make check   # fmt, vet, lint, test -race, build
make learn   # run the read-only learning tests against the real Slack API
             # using SLACK_API_KEY from .env (never posts messages)
```

`make setup` installs `golangci-lint` and `goimports` if you don't have
them.

## Layout

```
main.go                     thin entrypoint
cmd/                        one file per command (cobra), thin
internal/config/            profile-based YAML config
internal/errs/               structured errors -> exit codes
internal/cache/              shared ~/.cache/slack-cli dir helper
internal/oplog/               rotating NDJSON ops/debug log (send/dm/errors)
internal/slackx/             hand-rolled Slack HTTP client
  client.go                  Client interface + RealClient
  transport.go                rate-limiting http.RoundTripper
  tiers.go                    method -> tier table, limiter key derivation
  pager.go                    cursor pagination helper
  localcache.go                channels/users/poll-state on-disk caches
  limiter/                    persistent GCRA rate limiter (gofrs/flock)
```
