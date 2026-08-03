# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Keep it brief!

## 0.3.0 - 2026-08-02

### Added

- `admin doctor` issues carry a `severity` (`error`|`advisory`); status is `ok`/`warning`
  (exit 0)/`error` (exit 1).
- `--human` output groups issues errors-first with a `N errors, M advisories` summary line.
- New `duplicate-root` error: two configured roots resolving to the same physical directory.
- Discovery caps walk-depth at 64, surfacing a `root-read-error` warning on deep nesting (does
  not address symlink cycles).
- `Audit.Warnings` is now structured (`code` + `message`): `invalid-frontmatter`,
  `variant-mismatch`, `root-read-error`, `invalid-skill` fallback.
- A root whose Stat/ReadDir fails for a reason other than "does not exist" now surfaces as a
  single `unreadable-root` error instead of `missing-root` plus a duplicate warning.

### Changed

- `duplicate` fires only when the shadowed file's content hash differs from the winner's;
  identical mirrors across roots are now silent.
- `high-native-exposure` is computed from the deduplicated skill list, not raw per-root counts,
  and names a few example skills.
- `admin doctor` consumes `Exists`/`ReadErr` from discovery instead of re-reading each root.
- Native-root names now live once in `internal/config` (`config.IsNativeRoot`).
- Description/skill-size thresholds are named constants: `library.MaxDescriptionBytes`,
  `library.RecommendedDescriptionBytes`, `library.RecommendedSkillBytes`.

## 0.2.0 - 2026-07-13

### Added

- `read` and search auto-read output now show the skill's PATH so relative file references can be resolved.
- Improved search scoring with titles properly weighted and camelCase term matching; more permissive auto-read (e.g., single-match queries auto-read).
- `init` now adds an `apb` shell alias to your zshrc.
- `search --human` output is now clearly structured into a `RESULTS` list (with full descriptions word-wrapped onto aligned continuation lines instead of truncated) and a labeled `BEST MATCH (auto-read)` section, with a hint to run `read` when there's no confident match.
- Discovery no longer prints a warning on every command for symlinked files that resolve outside a configured root; these are still safely excluded, and now surfaced (once) via `admin doctor` instead of on every `search`/`list`.

## 0.1.0 - 2026-07-11

### Added

- Discover, list, search, and read portable skills with automatic Claude, Codex, Pi, or general variant selection.
- Create initial skills, record attributable JSONL feedback, and load concise subagent and skill-authoring guidance.
- Emit JSON by default with human-readable output available through `--human`.
- Add recursive command-root discovery, deterministic root precedence, harness detection, and the offline machine-readable schema.
- Add `admin doctor` diagnostics and configurable subagent model-role tips.
