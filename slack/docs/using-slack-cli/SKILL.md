---
name: using-slack-cli
description: Use the `slack` Go CLI to read, poll, and post Slack messages, and to inspect its own rate-limiter state. Use whenever a task involves interacting with Slack from the command line — checking channels for new messages, posting a status update, or DMing a user.
---

# using-slack-cli

A hand-rolled Slack Web API CLI, built for agent use: cheap local caching,
opt-in channel polling, and a persistent cross-process rate limiter so
repeated invocations never step on each other's 429s.

## Setup (one-time)

Needs `SLACK_API_KEY` (a user token). Run `slack config init` then
`slack auth test` once to write and verify
`~/.config/slack/config.yaml`. Full config reference (profiles,
`watch:`/`write:` options, logging) lives in the project README, not
here.

## Everyday commands

```bash
slack auth test                         # who am I? (auth.test)
slack channels list --json              # cached 1h; --refresh to bust
slack users list --json                 # cached 24h; --refresh to bust

slack read general --limit 20           # conversations.history
slack read general --thread 169...100   # conversations.replies
slack read general --oldest-first       # chronological instead of newest-first
slack read general --cursor <cursor>    # continue a paginated read (see the
                                         # stderr note when more is available)
slack read general --json | jq -r '.[] | "\(.user_name): \(.text)"'

slack send general "deploy finished"           # chat.postMessage
slack send general "see thread" --thread <ts>

slack dm alice "can you check this?"    # resolves by @name/email/U-id

slack watch add general                 # exact channel -> pin (also: config add-channel)
slack watch add "ac-*"                  # glob metachars -> pattern subscription
slack watch list --resolve              # what the next poll will actually visit
slack poll --json                       # only new messages since last poll
slack poll --refresh                    # re-fetch conversations.list before resolving patterns
slack poll --oldest-first=false         # newest-first (default is oldest-first)

slack mentions --user U08T71B5F0F --json  # new workspace-wide exact @mentions since last run

slack send partner-channel-qa "ok" --force  # override write.external=deny for a Slack Connect channel

slack logs path                         # where the ops log lives
slack logs tail -n 100                  # see what the CLI just did
```

`slack poll` is the agent-loop primitive: it checks the active profile's
resolved `watch:` set (see `slack watch list --resolve` and the README
for how it's built), and only ever prints messages newer than the last
invocation (state kept per-workspace in
`~/.cache/slack-cli/poll-state-<team>.json`, written atomically under a
file lock). Good pattern: run it on a schedule (cron / `watch`) and react
to whatever comes out. Output defaults to oldest-first (chronological),
since agents composing a transcript want reading order, not API order.
Externally shared (Slack Connect) channels are marked `ext_shared: true`
in JSON output and a `⇄ext` marker in text output. A resolved set over
~40 channels prints a stderr warning (Tier 3 pacing means a full sweep
takes roughly 1.2s/channel) suggesting `watch.exclude` entries.

A channel newly matching a pattern is auto-included on the next poll
after the 1h channels cache refreshes (or immediately with
`--refresh`); its last-seen is initialized on first sight -- a single
`limit=1` conversations.history call to grab the newest ts, *not* a full
pagination drain -- same as an explicitly pinned new channel. No
messages are printed and no backfill dump happens, which matters at
scale: with hundreds of watched channels, draining each one's entire
history on first sight would burn hours of Tier-3 rate budget before the
first poll even finishes.

A poll paginates through the full backlog since the last run for
channels that already have a last-seen entry (bounded, not just the
first page), and a failure on one configured channel doesn't abort the
others -- per-channel errors are reported (stderr, or the JSON output's
`errors` field) and the command only exits non-zero if every channel
failed.

#### Fast polling (default)

By default a poll cycle doesn't sweep every watched channel's history:
it first queries `search.messages` for anything newer than the oldest
last-seen watermark, then only calls `conversations.history` for
channels the detector flagged as dirty. On a quiet cycle with hundreds
of watched channels this turns a multi-minute Tier-3 sweep into a
handful of calls in a few seconds. `slack poll --json` reports which
path ran via `"mode": "fast"` or `"mode": "full"` (plus `"dirty": N` on
the fast path). `slack poll --full` forces a full sweep for one
invocation. Tuning knobs (`watch.fast`, `watch.reconcile_minutes`) are
in the README.

Because it's search-based, the detector also catches **thread replies**
that `conversations.history` itself can't return (non-broadcast replies
aren't in the parent channel's history): a match whose permalink carries
`?thread_ts=` is fetched via `conversations.replies` and delivered like
any other new message (JSON output gets a `"thread_ts"` field; text
output indents it with `↳`).

If `search.messages` itself fails (missing `search:read*` scope, rate
limited, etc.), `poll` logs a warning to stderr and the oplog and
transparently falls back to a full sweep for that cycle -- it never
fails the whole poll just because the detector is unavailable. See
`docs/FAST_POLL_FINDINGS.md` for the empirical API research behind this.

`slack watch add <ref>` (and its deprecated alias `slack config
add-channel <ref>`) requires `<ref>` to actually resolve against the
cached channel list, or to already look like a real conversation ID
(`C`/`G`/`D`-prefixed) -- it refuses to silently store an unresolved name
as if it were an ID, which would make polling quietly fail on every run.
A `<ref>` containing glob metacharacters (`* ? [`) is instead stored as a
`watch.patterns` entry, resolved fresh against the cache on every poll.

### Mentions

`slack mentions --user U08T71B5F0F --json` finds new workspace-wide exact
`<@USER_ID>` mentions of a user since the last run, via `search.messages`
-- anywhere the token can search, not just the resolved `watch:` set
`poll` covers. It requires a user token / app with the `search:read`
scope; a bot token without that scope returns a clear error instead of
crashing (`slack auth test` shows the current token).

Like `poll`, the first run for a given `--user` never backfills: it seeds
a cursor from the newest existing mention (or now, if none) and returns
zero results. A cursor is persisted per team+user at
`~/.cache/slack-cli/mentions-state-<team>-<user>.json` (written
atomically), or an explicit `--state-file /absolute/path`. Each run pages
at most 5 pages / 500 matches; if the delta since the last run exceeds
that cap, the output reports `"truncated": true` and deliberately does
**not** advance the cursor, so the next run re-covers the same window
instead of silently skipping mentions. Output is oldest-first, matching
`poll`'s chronological convention.

```bash
slack mentions --user U08T71B5F0F --json
slack mentions --user U08T71B5F0F --state-file /var/lib/postak/slack-mentions.json --json
```

### Write safety (Slack Connect)

`send`/`dm` resolve the target channel's native Slack-Connect sharing
flags before posting, and refuse by default (`write.external: deny`):

```bash
slack send partner-channel-qa "ok to ship"          # refused, exit 10 (WRITE_BLOCKED)
slack send partner-channel-qa "ok to ship" --force   # posts anyway
```

`write.blocklist` globs are never postable, even with `--force`.
`write.allowlist`, if non-empty, restricts posting to matches
(overridable with `--force`). `write.external: allow` disables the
Slack-Connect check entirely. Blocked attempts are logged to the ops log
as `{"op":"send","ok":false,"blocked":"external", ...}` (or `dm`). See
`docs/POLLING_DESIGN.md` §0.2 for why channel *names* aren't a reliable
external-share signal.

## Ops log

When enabled, every invocation appends compact NDJSON records to
`~/.config/slack/logs/ops.log` (0700 dir, 0600 files, size-rotated), so
you (or another agent) can later audit what the CLI wrote and to whom,
and see every failure.

```bash
slack --debug auth test          # enable for this invocation only
SLACK_DEBUG=1 slack poll         # enable for this shell/process
slack logs path                  # print the log file path
slack logs tail                  # last 50 lines
slack logs tail -n 200 --json    # last 200 lines as a JSON array
```

Config-file logging options (`logging.enabled`, `logging.level`,
rotation size/count) are in the README.

Record shapes (one compact JSON object per line -- useful for an agent
grepping/parsing the log):

```json
{"op":"send","ch":"C0123","name":"general","ok":true,"ts":"1784...","text":"first 200 chars...","ext":false,"t":"..."}
{"op":"dm","user_id":"U0123","name":"alice","ch":"D0456","ok":true,"ts":"...","text":"...","t":"..."}
{"op":"poll","ok":true,"chs":12,"new":3,"errs":0,"dur_ms":2100,"mode":"fast","dirty":2,"t":"..."}
{"op":"poll.detect","ok":false,"err":"missing_scope","t":"..."}
{"op":"poll.ch","ch":"C0999","ok":false,"err":"missing_scope","code":"UNAUTHORIZED","t":"..."}
{"op":"read","ch":"C0123","ok":true,"n":50,"t":"..."}
{"op":"channels.list","ok":true,"n":42,"cache":"hit","t":"..."}
{"op":"config.add_channel","ch":"C0123","name":"general","profile":"default","ok":true,"t":"..."}
{"op":"cli.error","cmd":"send","ok":false,"err":"...","code":"VALIDATION_ERROR","exit":8,"t":"..."}
```

Rules: write ops (`send`, `dm`, `config init`/`add-channel`/`remove-
channel`) are always logged in full, with message text truncated to 200
runes; the token/Authorization header is never logged; a failed read
channel is always logged expanded (`poll.ch` with `ok:false`), while a
successful read collapses to one summary record unless `level: debug`.
Logging is best-effort and can never fail a command -- a log write error
is swallowed silently and the command's real result/exit code is
unaffected.

## Rate limiting

If a command seems to hang, it's very likely waiting inside the
persistent cross-process limiter, not the network -- check it instead of
assuming a network stall:

```bash
slack limits status
slack limits status --json | jq '.[] | select(.cooldown_active)'
```

On a 429, the CLI already retries with the server's `Retry-After` plus
jitter — don't add your own retry loop around `slack` invocations. See
the README for the limiter's persisted-state path and per-channel vs.
per-workspace keying.

## Errors for scripting

Every command supports `--error-json`, which emits a stable JSON envelope
to stderr on failure instead of prose:

```bash
slack read bogus-channel --error-json
# {"status":"error","code":"NOT_FOUND","message":"channel \"bogus-channel\" not found", ...}
```

Exit codes: `1` internal, `2` unauthorized, `3` not found, `4` rate
limited, `5` config invalid, `8` validation error, `9` upstream
unavailable (retryable), `10` write blocked (send/dm refused by the
`write:` policy).

## Gotchas

- `conversations.history`/`replies` may be capped to 15 messages/req at
  1 req/min if the Slack app isn't Marketplace-approved and isn't an
  internal custom app for your workspace. If you see a loud once-per-key
  warning about this, narrow with `--since`/`--limit`, or install as an
  internal app.
- A Slack `missing_scope` error (and similar auth errors: revoked token,
  deactivated account, wrong token type) exits `2` (UNAUTHORIZED) with
  the specific scope Slack says is needed vs. what the token has, plus
  the fix: add the scope under OAuth & Permissions and reinstall the app.
- Channel/user references accept an ID (`C0123`, `U0123`), a bare name
  (`general`, `alice`), `#name`, `@name`, or (for `dm`) an email — the
  CLI resolves against the local cache first.
- Caches are keyed per workspace (team ID) so multiple profiles sharing
  one `~/.cache/slack-cli` don't cross-poison each other's name -> ID
  resolution; use `--refresh` to bust a stale one.
- Cobra-level errors (unknown command, bad flags, wrong arg count) exit
  `8` (VALIDATION_ERROR), same as other input-validation failures, per
  the documented exit-code contract.
