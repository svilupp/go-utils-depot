# Changelog

## 0.8.1 - 2026-10-21

### Changed

- Shortened the loader skill around playbook retrieval, repository references, and subagent selection; moved setup and advanced details into references.
- Router synchronization installs and checks the skill's bundled references alongside its entrypoint.

## 0.8.0 - 2026-10-21

### Added

- Global repository mappings with aliases, descriptions, and optional work/personal swimlanes.
- `tip repos [QUERY]` for the full map or exact/substring name and alias matches, including `repo://` references.
- Router guidance that triggers on `repo://` references and directs agents to verify targets and local instructions.

### Changed

- Project skill-folder discovery is enabled by default, with global defaults and project overrides.
- Implicit project discovery scans from the Git worktree root.

### Fixed

- A bare `~` config path now expands to the home directory.

## 0.7.0 - 2026-10-20

### Added

- Catalog scopes, the `index` alias, and project/global JSON provenance.
- Opt-in bounded project skill-folder discovery with exclusions and safe pruning.
- Suggested read commands preserve config, harness, scope, and project context.

### Changed

- Clarified CLI help and guides with verified examples and discovery defaults.


All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Keep it brief!

## 0.6.0 - 2026-09-26

### Added

- Project discovery for Claude and Codex roots, multiple custom roots, predictable skill selection, invocation-linked feedback, and bounded reads.

## 0.5.0 - 2026-09-26

### Added

- Shared read/search resolution for exact names, normalized names, aliases, configured conventions, and confidence-gated lexical matches. Ambiguous reads return candidates with recovery commands.
- `load`, `show`, and `find` aliases; explicit JSON and structured errors; list filtering and limits; idempotent initialization.
- Declared aliases on Claude command frontmatter, preserving historical command repairs as one-call resolutions.
- Project-local native roots and `.agent-playbooks.yaml` manifests with worktree boundaries, precedence, and source provenance.
- Bounded invocation JSONL records, feedback by invocation ID, `admin stats`, and locked feedback appends.
- Body-free metadata, stable outlines and section reads, hash guards, output budgets, and explicit partial batch reads.
- Router drift diagnostics and guarded `admin sync-router` previews and updates.
- A synthetic retrieval evaluation with all 30 audited queries, held-out task diagnostics,
  crowded-catalog distractors, four harness metadata variants, and forced-read metrics.

### Changed

- Lexical search uses inverse-frequency weighting and explicit abstention for broad or weak queries.
- `read --metadata` is documented as a JSON array that includes the body; `--metadata-only` omits it.

## 0.4.0 - 2026-09-23

### Added

- `read` repairs missing names using configurable prefix/suffix conventions (e.g. `dbexplorer` → `using-dbexplorer-cli`), then tries confidence-gated search. Repairs are announced on stderr; ambiguous conventions never auto-read.

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
