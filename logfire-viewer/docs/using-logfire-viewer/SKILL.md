---
name: using-logfire-viewer
description: Visual companion to `logfire-trace` (lft). Use the logfire-viewer CLI and HTTP API (alias `lfv`) to browse and fuse AI conversation traces produced by the internal agent-testing harness, by exported Firestore chat documents, or by raw Logfire trace JSON. Push traces from a running agent, drive `lft` fetch/replay as background jobs, and deep-link the user to a specific run, scenario, or conversation. Use when the user mentions `logfire-viewer`, `lfv`, agent-testing harness logs, or wants to visually inspect anything `lft` can fetch.
---

# Using logfire-viewer

`logfire-viewer` (alias `lfv`) is the visual pair to `logfire-trace`
(`lft`). Where `lft` fetches and replays traces from the command line,
`lfv` loads them from disk, fuses related records by ConvKey, and
serves a local dashboard plus a JSON/SSE API for agents. Default bind:
`127.0.0.1:18081`.

## What it ingests

- **Agent-testing harness output**: the run directories under
  `tools/agents-testing/logs/<timestamp>/`
  (`summary.json` + `conversations/` + `replay_traces/`).
- **Firestore chat exports**: single `ai-chat` documents.
- **Logfire trace JSON**: anything `lft get` writes, plus flat span
  arrays under `replay_traces/`.
- **Perseus scenarios and summaries**: single curated JSON files.
- **Generic** `[{role, content}, ...]` arrays.

ConvKey fusion means a Logfire trace and a Firestore chat for the same
conversation appear merged in the dashboard.

## Naming rule

- Prefer `logfire-viewer` in docs and suggested commands.
- Use `lfv` only when the user has the alias configured (`lfv init`
  installs it).

## Three modes

1. **One-shot CLI** for snapshots and detection:
   ```bash
   lfv dump ./runs                # full fused snapshot as JSON
   lfv list ./runs --json         # one row per detected file
   lfv inspect run.json --json    # detect + summary
   lfv show conv.json --json      # fused conversation as JSON
   ```

2. **Web dashboard** for human browsing:
   ```bash
   lfv serve --open ./tools/agents-testing/logs/20260427_155416
   ```

3. **HTTP API** for agents (the main path for skill users):
   ```bash
   lfv serve --quiet ./runs &
   # block on the READY line on stdout, then hit the API
   curl -s http://127.0.0.1:18081/llms.txt
   ```

## Discovering the API

Two endpoints describe the full surface. Read these before hand-coding
requests:

- `GET /llms.txt`: markdown agent guide listing every route, with
  conventions and ConvKey rules.
- `GET /openapi.json`: OpenAPI 3.0 spec for the JSON API.

Do not hard-code endpoint shapes from memory; fetch `/llms.txt` once
per session.

## Agent workflows

### Push trace data into the viewer

After your agent finishes a run, post the trace so the user sees it
in their open dashboard.

```bash
# multipart (file or folder)
curl -X POST -F 'files=@trace.json' http://127.0.0.1:18081/api/ingest

# raw JSON body (single trace document)
curl -X POST -H 'Content-Type: application/json' \
  --data-binary @trace.json \
  http://127.0.0.1:18081/api/ingest
```

Ingested data is merged via ConvKey but is not fsnotify-watched and is
lost on process restart.

### Fetch a Logfire trace through the viewer

The viewer drives `lft` as a background subprocess. The result is
auto-ingested on success.

```bash
curl -X POST -H 'Content-Type: application/json' \
  -d '{"trace_id":"019dcf6a71f36f47eb848d2da67b26f6"}' \
  http://127.0.0.1:18081/api/lft/fetch
# returns {"job_id":"..."} with 202

curl -N http://127.0.0.1:18081/api/jobs/<id>/output   # SSE stream
curl -s http://127.0.0.1:18081/api/jobs/<id>          # final state
```

If `lft` is not on PATH the endpoint returns 503; pass `--lft-bin
/path/to/logfire-trace` to `serve` or set `$LFT_BIN`.

### Read structured data

```bash
curl -s http://127.0.0.1:18081/api/runs           | jq '.runs[] | {run_id, passed, total}'
curl -s http://127.0.0.1:18081/api/runs/<id>/s/<scenario_name>
curl -s http://127.0.0.1:18081/api/conversations/<conv_id>
```

`<scenario_name>` must be URL-escaped.

### Deep-link the user

Hand the user a stable URL rather than dumping JSON into the chat:

- `/c/{conv_id}` for one conversation
- `/runs/{run_id}` for a run
- `/runs/{run_id}/s/{scenario_name}` for a scenario verdict
- `/runs/compare?a=<runA>&b=<runB>` for a side-by-side diff
- `/jobs/{job_id}` for live `lft` output

## Pairing with `lft`

`lft` is the source of truth for fetching, span-tree extraction, and
provider replay. `lfv` is the source of truth for visual inspection
and cross-source fusion. Common pattern:

```bash
# lft pulls a trace
lft get 019dcf6a71f36f47eb848d2da67b26f6
# lfv visualises it (alongside any harness data already loaded)
curl -X POST -F 'files=@logs/trace_019dcf6a71f36f47eb848d2da67b26f6.json' \
  http://127.0.0.1:18081/api/ingest
```

Or skip the manual step: `POST /api/lft/fetch {trace_id}` runs the
`lft get` and ingest in one call.

## Best practices

1. Always start `serve` with `--quiet` in scripts and block on the
   `READY <url>` line on stdout before making API calls.
2. Read `/llms.txt` once at session start; do not invent endpoint
   shapes.
3. Prefer `POST /api/ingest` over restarting `serve` with new paths.
   Watched paths reload on file changes; ingest is for ad-hoc pushes.
4. For `POST /api/lft/fetch`, poll `/api/jobs/{id}` or stream
   `/api/jobs/{id}/output` rather than guessing duration.
5. URL-escape scenario names in route paths.
6. Treat the viewer as localhost-only. Do not expose it beyond
   `127.0.0.1`; there is no auth.
