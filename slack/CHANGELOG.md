# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, adapted for this repository.

## [0.4.0] - 2026-10-23

### Added

- Read-only `dm-activity` discovery with explicit incomplete-coverage reporting.
- Scoped polling with activity-completeness and old-thread hints, reducing
  history scans while retaining periodic exact reconciliation.

## [0.3.0] - 2026-09-27

### Added

- Scoped polling from a fixed conversation timestamp, with thread coverage
  checks and checkpoint protection.
- Journaled sends with durable operation keys, identity validation, and
  inspectable receipts. Ambiguous sends do not silently retry.

## [0.2.0] - 2026-08-03

### Added

- Added `slack mentions` — incremental workspace-wide mention polling for a
  user (requires user token with `search:read`).

## [0.1.0]

### Added

- Initial release: auth, channels, read, send, dm, poll, watch, users,
  limits, logs, config.
