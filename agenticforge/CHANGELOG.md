# Changelog

## 0.2.0 - 2026-09-15

### Added

- Guided, re-runnable `init`: checks for `eget` and a signed-in 1Password
  CLI, asks for your team's skill repository clone and skill destination
  (`claude`, `codex`, `pi`, `agent-playbooks`, or a custom folder), and
  keeps existing values on re-run.
- One-command setup via presets (`install --preset core`, `data`, `tracing`,
  `ai`, `all`): installs the CLIs, their 1Password-backed configs (existing
  files are never overwritten without `--overwrite-configs` and a backup), and
  their matching `using-<app>` skills from the skill repository.
- New `skill list` / `skill install` / `skill select` and `config list`
  commands to browse and pick skills and see which configs are managed.

## 0.1.0 - 2026-09-13

### Added

- Plan-first installation, update, synchronization, and removal for CLIs,
  configuration files, and agent skills.
- Catalog providers for downloads, Go modules, local builds, and fixtures.
- File, `op read`, and `op inject` configuration sources with resolved values
  kept out of Agenticforge's own config, state, plans, and logs.
- Explicit target paths, ownership state, conflict detection, locks, and
  recoverable backups.
- Machine-readable JSON output with human-readable tables and stable exit
  codes.
