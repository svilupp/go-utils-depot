# Changelog

## 0.2.0 - 2026-09-27

### Added

- Targeted relation discovery with `inspect catalog --match` and clearer
  task-oriented help for documentation, queries, and schema inspection.
- More resilient knowledge indexing: damaged notes are reported and skipped
  without hiding healthy documents; doctor reports link and header issues.
- More precise search ranking, query parameter validation, and recovery hints.

### Fixed

- PostgreSQL numeric values render as decimal strings, BigQuery FLOAT64 values
  decode correctly, and query duration and UTC timestamps are reported accurately.
- Local documentation reads no longer require a writable activity log.

## 0.1.0 - 2026-09-13

### Added

- Discover, search, read, and validate a configured database knowledge catalog.
- Inspect configured endpoints, relation metadata, samples, and access checks.
- Run parameterized, read-only PostgreSQL and BigQuery SQL with outer limits,
  timeout controls, cost checks, and BigQuery job resumption.
- Record database activity locally with log rotation, bounded caches, and
  validation receipts.
- Emit machine-readable JSON with human-readable output, structured errors,
  hints, and stable exit codes.
