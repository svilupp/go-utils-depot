# Changelog

## 0.2.0 - 2026-10-18

### Added

- Named authentication profiles reusable across pinned environments while
  preserving inline service-account configuration.
- Explicit `access_token` profiles with `token_env` for externally minted OAuth
  tokens or bearer placeholders. Only the selected live environment
  reads its variable; missing tokens fail without service-account fallback.
- Setup documentation for named profiles, external token injection, and token
  lifetime limits.

### Fixed

- Require string token-variable names and reject invalid token control bytes
  before making requests, with credential-free authentication errors.
- Report the selected authentication mode in JSON and human `check` output.

### Changed

- Replace organization-specific examples in bundled help and configuration with
  generic placeholders.

## 0.1.0 - 2026-09-13

### Added

- Read-only Firestore commands for listing collections, reading documents,
  searching indexed fields, scanning one bounded page, and listing children.
- Authored documentation and schema samples for unknown collections and fields.
- Configured environments with pinned connections, field policy filtering,
  masking, redaction, pagination metadata, limits, and atomic artifacts.
- Emit machine-readable JSON with human-readable output, structured errors,
  hints, and stable exit codes.
