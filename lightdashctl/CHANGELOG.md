# Changelog

## 0.2.0 - 2026-09-27

### Changed

- Added the `new`, `pull`, `status`, `apply`, and `delete` bundle workflow.
- Kept the former `build` commands and `docs copy` as deprecated aliases.
- Added `--check-data` on apply, complete CSV result export, and improved
  publication recovery and capability errors.

## 0.1.0 - 2026-09-13

### Added

- Discover Lightdash content, projects, spaces, dashboards, charts, explores,
  and fields by exact or searchable references.
- Read and search a configured local documentation catalog, including metric
  notes and content-as-code templates.
- Compile and run metric queries, saved charts, and dashboards with bounded
  results and async status recovery.
- Validate, preview, and apply native chart and dashboard bundles.
- Emit machine-readable JSON with human-readable terminal output, structured
  errors, hints, and stable exit codes.
