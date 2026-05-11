# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, adapted for this repository.

## [0.6.0] - 2026-05-09

### Added

- Multi-workspace profiles in `~/.config/linear/config.yaml`. Select with `--profile`, `LINEAR_PROFILE`, `default_profile`, or sole-profile fallback.
- Workspace guard: mutations abort with `WORKSPACE_MISMATCH` if the profile's `workspace_key` doesn't match the API key's organization.
- `--error-json` flag: structured `{status, code, message, details}` errors on stderr with stable exit codes.
- `comment list`, `get`, `edit`, `delete` subcommands. `list` supports `--filter-prefix`, `--author`, `--limit`, `--json`.
- `profile list` and `profile show` for inspecting configured profiles.

### Changed

- `--assignee <name>` resolves through the active profile's `stakeholders` map first.

## [0.5.0] - 2026-05-09

### Breaking

- `linear init` now clears the legacy top-level `linear:` block after migrating its values into a profile (see `cmd/init.go:writeProfile`). Configs converge on the new profile-based schema; any tool that read fields directly out of the legacy block needs to read them out of the matching profile instead.

## [0.4.0] - 2026-03-11

### Added

- Added `linear update` for issue mutations from the CLI, including parent, state, priority, assignee, project, and label changes.
- Added machine-readable stdout modes:
  - `linear get --json`
  - `linear get --field <path>`
  - `linear create --json`
  - `linear update --json`
- Added parent-aware ticket creation with `linear create --parent <identifier-or-url>`.
- Added `--dry-run` support for `create` and `update`.

### Changed

- Expanded the internal issue model and GraphQL queries to include team, project, parent, label IDs, and richer mutation responses.
- Improved `linear get -s` summary output to include team, project, parent, and the internal issue UUID.
- Switched issue lookup to direct issue queries instead of search-based lookup for more reliable identifier resolution.

## [0.3.1] - 2026-03-11

### Added

- Documented the missing workflows discovered in real usage:
  - parent-child ticket creation
  - issue updates
  - machine-readable stdout output
  - richer issue metadata in `get`
  - optional batch ticket creation

### Changed

- Bumped the repo build version from `0.3.0` to `0.3.1` to reflect the planning/documentation release.
