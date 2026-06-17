# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Keep it brief!

## 0.2.0 - 2026-06-17

### Added

- `--human` flag renders any data command's results as a readable table.

### Fixed

- `services` and `services list` now honor `-n`/`--limit`.

## 0.1.0 - 2026-06-17

### Added

- Find a service's logs and top grouped errors in New Relic by short service name, no NRQL required.
- Check a service's latency, health, and slowest traces, and list recent deploys to see what changed.
- Build shareable New Relic web links or run raw NRQL for anything the templates don't cover.
