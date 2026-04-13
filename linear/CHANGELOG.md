# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Keep it brief!

## [0.4.0] - 2026-03-11

### Added
- `linear update` for issue mutations (parent, state, priority, assignee, project, labels)
- Machine-readable stdout modes: `linear get --json`, `linear get --field <path>`, `linear create --json`, `linear update --json`
- Parent-aware ticket creation with `linear create --parent <identifier-or-url>`
- `--dry-run` support for `create` and `update`

### Changed
- Expanded internal issue model and GraphQL queries to include team, project, parent, and label IDs
- `linear get -s` summary now shows team, project, parent, and internal UUID
- Switched issue lookup to direct issue queries for more reliable identifier resolution

## [0.3.0] - 2026-03-08

### Added
- First release: get, create, comment with summary/JSON output
