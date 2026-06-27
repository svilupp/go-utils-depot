# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Keep it brief!

## 0.1.0 - 2026-06-27

### Added

- Browse and filter the OpenRouter model catalog under a saved price/privacy policy — one YAML intent compiles to both a catalog filter (`GET /models`) and a request-side `provider` routing object (including the "no training" switch).
- Read true per-call cost, serving provider, and data region with `gen <id>`; inspect `model`, `endpoints`, `providers`, `credits`, `rankings`, and `benchmarks`.
- Send policy-routed `chat` and multi-model `fusion` completions (billable, `--yes`/`--dry-run` guarded); `replay` recorded conversations against OpenRouter by handing off to the logfire-trace CLI.
- Strict agent contract: JSON on stdout, human status on stderr, exit codes 0/1/2, an offline `schema --json` machine contract, and a `--human` table mode.
