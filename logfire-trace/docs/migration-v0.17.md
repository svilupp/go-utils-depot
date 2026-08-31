# Migrating to logfire-trace 0.17

Version 0.17 makes saved JSON the normal investigation workflow. A successful
`get` writes its capture under `./logs/` and emits the same JSON on stdout;
the absolute saved path is reported on stderr. Use `--output FILE` or
`--output-dir DIR` to select a case folder, then reuse that local file for
inspection, replay, and `logfire-viewer`.

The two destinations are independent and configurable:

```yaml
output_dir: logs
replay_output_dir: logs/replay
```

Live replay attempts now write one receipt per provider attempt under
`./logs/replay/`, or under `replay_output_dir`. Replay `--output-dir` (and
`LFT_OUTPUT_DIR`) overrides the receipt directory; replay `--output FILE`
continues to mean the aggregate result file and may be used alongside it.

The breaking changes are:

- `get --stdout` is retained as a deprecated JSON alias, but it now saves a
  capture too. Use an explicit `--output-dir` when choosing where that file
  should live.
- `--html` and `--open` were removed from `logfire-trace`. Use `--human` and
  shell redirection for text, or open the saved JSON in `logfire-viewer`.
- Replay candidate lists, turn reports, inspections, and dry-runs now emit
  JSON by default. Pass `--human` for terminal reports; `--json` remains a
  deprecated compatibility alias where it existed.
- Live replay receipt persistence is no longer opt-in. Set
  `replay_output_dir`, replay `--output-dir`, or `LFT_OUTPUT_DIR` when the
  default location is unsuitable.

Receipt schema `lft.replay.receipt/v2` is unchanged and remains readable by the
viewer. Existing captures are not moved or deleted. Repeating a remote trace
ID still downloads a new snapshot; use the saved path for repeated analysis.
