# Changelog

## 0.2.0 - 2026-10-18

### Added

- Human annotation batches with document comments, item notes, custom enums,
  ordered ratings, selection, manifest grouping, durable resume, and JSON or CSV
  export. Typed annotation needs no model provider.
- Optional manual or automatic AI follow-ups scoped to the saved batch item.
  Human notes persist independently of follow-up failures.
- Private rotating operation diagnostics and a content-free diagnostics export.

### Changed

- Raise the per-artifact document and replacement limit to 15 MiB and load
  selected document content in pages.
- Add public depot documentation and five-platform release bundles containing
  the pinned live-browser helper, dependencies, licenses, and usage skill.

### Fixed

- Update the pinned Go toolchain to 1.27.2 and `golang.org/x/net` to 0.60.0
  to address the release vulnerability scan.

## 0.1.0 - 2026-10-04

### Added

- Anchored Markdown and isolated HTML review, read-only website snapshots, and
  live Chromium evidence capture.
- Cloop-managed Codex, Claude Code, and Pi review children; typed and voice
  comments, scoped proposals, conflict checks, durable resume, and bounded handoffs.
- Light and dark themes, keyboard submission, optional dictation on selection,
  and configurable Codex scheduling tiers.
- Explicit live-tab selection, masked screenshots, bounded metadata recording,
  and detached historical review without website writes.
