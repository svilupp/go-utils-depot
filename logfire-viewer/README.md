# logfire-viewer

Local web viewer for AI conversation traces. Visual pair to [`logfire-trace`](../logfire-trace/) (`lft`).

## When to use it

You have AI agent traces — Logfire JSON, Firestore chat exports, Perseus run directories, or generic `[{role, content}]` arrays — and you want a browsable dashboard rather than CLI output. `logfire-viewer` (alias `lfv`) loads them from disk, fuses related records by `ConvKey`, and serves a local dashboard at `127.0.0.1:18081` plus a JSON/SSE API for agents.

- `lfv serve <paths>` -- start the dashboard on `127.0.0.1:18081`
- `lfv open <file>` -- open one or more files in the viewer
- `lfv dump ./runs` -- emit a fused JSON snapshot to stdout
- `lfv list ./runs --json` -- one row per detected file
- `lfv saved add <file> --note "..."` -- push traces into the saved-items inbox at `/saved`
- `lfv serve .replays/` -- ingest redacted `lft.replay.receipt/v2` attempt receipts (v1 remains readable); auto-clusters at `/replays`
- `lfv serve --evals <dir>` -- browse eval *definitions* (scenario + manifest TOMLs) at `/evals`; see [Eval configs](#eval-configs)
- Drop traces or whole folders onto the navbar dropzone, or `POST /api/ingest`
- `Jobs` tab runs `lft get` / `lft replay` as background subprocesses with live SSE output

## Install

```bash
eget svilupp/go-utils-depot --tag 'logfire-viewer/' --to ~/.local/bin

# Optional: one-time setup adds an `lfv` alias to your shell rc
logfire-viewer init
```

## Quick start

```bash
# Serve a directory of traces (no watching)
logfire-viewer serve testdata/raw

# Watch + auto-open the browser
logfire-viewer serve --open --watch ./tools/agents-testing/logs/20260427_155416

# Headless: pipe stdout, block on READY, then hit the API
logfire-viewer serve --quiet ./runs &
curl -s http://127.0.0.1:18081/api/runs | jq '.runs[].run_id'
```

Then open http://127.0.0.1:18081.

## Subcommands

| Command   | Description                                                        |
| --------- | ------------------------------------------------------------------ |
| `serve`   | Start a local web server to browse loaded conversations            |
| `open`    | Open one or more files in the viewer (alias for `serve --open`)    |
| `list`    | Print a table of detected files and their formats                  |
| `inspect` | Print the detected source format and a one-line summary for a file |
| `show`    | Pretty-print a conversation to the terminal (role-coloured)        |
| `dump`    | Fuse all detected sources and emit a JSON snapshot to stdout       |
| `init`    | Interactive setup; installs the `lfv` shell alias                  |
| `version` | Print the version (also `--version` / `-v`)                        |

`serve` flags: `--port` (default `18081`), `--open`, `--watch`, `--quiet`/`-q`, `--lft-bin`, `--evals <dir>`, `--evals-max-depth` (default `10`), `--evals-max-rundirs` (default `100`).

## Sources

Detected automatically:

- **Logfire trace** -- flat span arrays from `lft get <id>` or `replay_traces/*.json`
- **Firestore chat** -- exported `ai-chat` documents
- **Perseus scenario / summary / run directory** -- `{run}/summary.json` plus `{run}/conversations/*.json`
- **Replay session directory** -- a folder of `lft.replay.receipt/v1` files from `lft replay --output-dir <DIR>`; auto-clustered by `source_trace_id` × `input_sha`
- **Generic messages** -- plain `[{role, content}, ...]` arrays

Files larger than 50MB are skipped.

## HTTP API

| Endpoint                       | Returns                                          |
| ------------------------------ | ------------------------------------------------ |
| `GET /api/health`              | `{ok: true}`                                     |
| `GET /api/runs`                | All runs with summaries and tallies              |
| `GET /api/runs/{id}`           | Single run                                       |
| `GET /api/runs/{id}/s/{name}`  | Scenario summary + fused conversation + verdict  |
| `GET /api/conversations`       | All conversations (id, title, sources, turns)    |
| `GET /api/conversations/{id}`  | Full fused conversation                          |
| `GET /api/index.json`          | Flat search index of runs and scenarios          |
| `POST /api/reload`             | Re-scan the watched paths                        |
| `POST /api/load?path=<dir>`    | Add a new directory to the watched set           |
| `POST /api/ingest`             | Ad-hoc upload (multipart or JSON), not watched   |
| `POST /api/lft/fetch`          | Spawn `lft get` and ingest the result            |
| `POST /api/lft/replay`         | Spawn `lft replay`                               |
| `GET /api/jobs`                | Background lft jobs (newest first)               |
| `GET /api/jobs/{id}`           | Single job + buffered stdout/stderr              |
| `GET /api/jobs/{id}/output`    | SSE stream of job output (terminates on `done`)  |
| `POST /api/jobs/{id}/cancel`   | Cancel a running job                             |
| `POST /api/saved`              | Add a saved item (multipart or JSON)             |
| `GET /api/saved`               | List saved items                                 |
| `PATCH /api/saved/{id}`        | Update star, notes, tags, read state             |
| `DELETE /api/saved/{id}`       | Remove a saved item (also dismisses the SHA)     |
| `GET /api/saved/events`        | SSE stream of saved-item updates                 |
| `GET /llms.txt`                | Markdown agent guide (read this from an agent)   |
| `GET /openapi.json`            | OpenAPI 3.0 spec for the JSON API                |
| `GET /events`                  | SSE stream of store/event updates                |
| `GET /api/evals/specs`         | Eval specs, honouring the same filters as the UI |
| `GET /api/evals/specs/{path}`  | One spec plus the manifests referencing it       |
| `GET /api/evals/manifests`     | Manifests and their clusters                     |
| `GET /api/evals/rundirs`       | Discovered run dirs, paged (`?offset=&limit=`)   |
| `POST /api/evals/reload`       | Re-read the eval catalog (no restart)            |

The `/api/evals/*` routes exist only when `--evals` is set and the catalog is non-empty.

`serve --quiet` writes only `READY <url>` to stdout — block on that line before making API calls.

## UI

- `/` -- runs index with pass-rate strip and run rows
- `/runs/{id}` -- run detail with sticky filter row, dense toggle
- `/runs/{id}/s/{name}` -- scenario detail with verdict panel and `lft replay` command
- `/runs/compare?a=&b=` -- side-by-side run diff
- `/loose` -- conversations not tied to any run
- `/replays` -- replay sessions clustered by `source_trace_id` × `input_sha` with prompt-diff compare view
- `/saved` -- saved-items inbox with star, notes, tags, and live updates
- `/jobs` -- background lft jobs with status and live output
- `/evals` -- eval config explorer (only with `--evals`)
- ⌘K or `/` -- search palette; `?` -- help drawer
- Keys: `j`/`k` move row focus, `Enter` opens, `[`/`]` (or `h`/`l`) prev/next scenario, `f` focus filter, `1`-`4` cycle status, `g r` returns to runs index, `g e` jumps to the eval explorer

Localhost-only dev tool — no auth. Don't expose beyond `127.0.0.1`.

## Saved items inbox

A review queue for traces. Star a conversation in the UI, or push files in from the CLI:

```bash
# Push a file (works even if the trace isn't loaded yet)
logfire-viewer saved add path/to/trace.json --note "tool loop" --tag run-2026-04-29

# Walk the inbox
logfire-viewer saved list --unread
logfire-viewer saved read <id>
logfire-viewer saved rm   <id>
```

The CLI auto-discovers a running `logfire-viewer serve` via `~/.config/logfire-viewer/server.json`. Override with `--server URL` or `$LOGFIRE_VIEWER_URL`. Saved files live under `~/.config/logfire-viewer/saved_items/` with a 30-day retention sweep on startup.

## Replay sessions

Pair with `lft replay --output-dir <DIR>` (or the legacy `-O <DIR>` / `LFT_OUT`) to compare prompt iterations:

```bash
# Generate a few receipts varying flags
lft replay trace.json --output-dir .replays/
lft replay trace.json --output-dir .replays/ --temperature 0.7
lft replay trace.json --output-dir .replays/ --model claude-opus-4-7

# Browse them
logfire-viewer serve .replays/ --open
```

`/replays` clusters receipts by `source_trace_id` × `input_sha`. Same `input_sha` = noise samples; different `input_sha` under the same trace = a variant. Use the side-by-side compare view to diff two clusters.

`/replays/family/{hash}` collapses the noise dimension across sessions: every sample sharing the same shared input (system prompt + messages + tool definitions, regardless of model or sampling params) renders side-by-side so you can read N stochastic outputs in one view. Each variant in the session tree links to its family with a `▶ View all samples · N` button when 2+ samples exist.

## Eval configs

Everything above is about run *results*. `--evals` is the other half: a browser for the eval *definitions* — the scenario and manifest TOMLs themselves.

```bash
logfire-viewer serve --evals ~/code/my-monorepo/tools --open
# evals … — 1050 spec(s), 8 manifest(s), 100/669 run dir(s) in 164ms
```

Point it at anything — a repo root, a `config/` dir, a `logs/` dir. It walks the tree and recognizes files **by content, not by directory layout**, so no particular folder structure is required. If it finds nothing it recognizes, the section stays off: no nav link, no routes.

- `/evals` -- overview: category/subcategory counts, top asserted tools, orphan count, and the most recent run directories
- `/evals/specs` -- search and filter every spec by category, store, mode, tool, criterion, assertion type, or orphan status. Each row shows a one-line headline plus a fact strip of what the spec actually enforces. Criterion text is searchable via the `include criteria text` toggle (off by default — it's the bulk of the corpus and mostly boilerplate)
- `/evals/specs/{path}` -- resolved stores, personas, shared criteria, inherited sidecar flags, the assertion table, and which manifests reference this spec
- `/evals/manifests` -- near-identical manifests grouped into clusters: the shared case set once, then only the fields that differ between members. Beats diffing dozens of near-identical files by hand. `?view=flat` lists them individually

Run directories are listed newest-first and are **never parsed until you ask** — hit `load` on a row to pull one into the trace viewer. That keeps pointing at a repo root with gigabytes of logs instant.

Settings live in `~/.config/logfire-viewer/config.json` (`evals_dir`, `evals_max_depth`, `evals_max_rundirs`, `evals_skip_dirs`), written by `logfire-viewer init`. Precedence is **flag > `$LFV_EVALS_*` env > config file > default**. The skip list has sane defaults (`node_modules`, `.venv`, `.git`, build/cache dirs) and deliberately does *not* include `logs`.

Full agent guide: [docs/using-logfire-viewer/SKILL.md](docs/using-logfire-viewer/SKILL.md)
