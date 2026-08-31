# CLI output contract

`logfire-trace` emits one JSON value on stdout for data commands by default.
Diagnostics, save confirmations, linked-fetch notes, and replay receipt paths
go to stderr. Pass `--human` for terminal-oriented output; `--width COLUMNS`
controls width-sensitive views and never changes the JSON or saved artifact.

## Fetch and query

- `get TRACE_ID` emits the selected span array. `--all` controls whether the
  saved and emitted trace includes non-AI spans.
- `get --chat`, `get --user`, and `get -c` emit the existing resolved chat
  object.
- `query SQL` emits an array of row objects. `query --human` renders a stable,
  width-aware table with sorted columns.
- `profiles` and `config` emit the existing profile document. Use
  `profiles --human` for the terminal table.

Successful fetches always save JSON. The path is printed as an absolute
`Saved: ...` line on stderr. Choose a destination with `--output FILE`, then
`--output-dir DIR`, then config `output_dir`; the fallback is `./logs/` under
the current working directory. Linked captures use the same directory.

## Replay reports

- A live replay emits the existing aggregate `ReplayOutput` object. Its
  per-attempt receipts are written independently.
- `--list-replay-spans` emits an array of `ReplaySpanSummary` objects. Each row
  includes stable `span_id`/`trace_id` values and selection metadata.
- `--inspect` emits an `Inspection` object.
- `--turns` emits an object containing `source`, `selected_span`, `candidates`,
  `turn_graph`, and `suggestions`.
- `--dry-run` emits the existing provenance object with `preflight`, `source`,
  `config`, and `would_call` sections, plus `inspection`, the effective
  `request`, and `steps` for a forward replay plan.

For replay reports, `--output FILE` saves the same JSON document while stdout
continues to emit JSON (or the `--human` rendering). Receipt `--output-dir`
settings do not create directories during inspection or dry-run.

Use `--human` with these modes for readable reports; `--width COLUMNS` and
`--no-color` control terminal rendering only. Width resolves from the explicit
flag, terminal size, `COLUMNS`, then a 100-column fallback. Inspection, turns,
candidate discovery, and dry-run do not call a provider or create receipts.

Live receipt paths use `--output-dir`, then `LFT_OUTPUT_DIR`, then config
`replay_output_dir`, and finally `./logs/replay/`. Receipt files keep the
`lft.replay.receipt/v2` schema and are written once per provider attempt,
including failures and timeouts.

## Save once, analyze repeatedly

Prefer an explicit output flag for an investigation:

```bash
logfire-trace get "$TRACE_ID" --all --output-dir logs/investigation/ > /dev/null
logfire-trace replay "logs/investigation/trace_${TRACE_ID}.json" --inspect | jq '{replayable, selected_span}'
```

Reuse the local path for inspection, replay, and `logfire-viewer`; passing the
remote ID again downloads a new snapshot.
