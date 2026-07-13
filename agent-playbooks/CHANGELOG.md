# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Keep it brief!

## 0.2.0 - 2026-07-13

### Added

- `read` and search auto-read output now show the skill's PATH so relative file references can be resolved.
- Improved search scoring with titles properly weighted and camelCase term matching; more permissive auto-read (e.g., single-match queries auto-read).

## 0.1.0 - 2026-07-11

### Added

- Discover, list, search, and read portable skills with automatic Claude, Codex, Pi, or general variant selection.
- Create initial skills, record attributable JSONL feedback, and load concise subagent and skill-authoring guidance.
- Emit JSON by default with human-readable output available through `--human`.
- Add recursive command-root discovery, deterministic root precedence, harness detection, and the offline machine-readable schema.
- Add `admin doctor` diagnostics and configurable subagent model-role tips.
