# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Keep it brief!

## [0.3.0] - 2026-03-08

### Added
- `sotto unlock` / `sotto lock` — session daemon holds passphrase in memory for non-interactive access (TTL-bounded, Unix socket)
- `sotto search <term>` — case-insensitive key name search using metadata index (no passphrase needed)
- Bulk set: `sotto set --file secrets.json` and `sotto set --stdin-json` for atomic multi-key writes
- Profile dump: `sotto get --profile work` dumps all keys (supports `--format json`, `--format env`, table)
- Tag filtering: `sotto list --tag ci,deploy` (OR matching)
- Key suggestions on not-found errors from metadata index
- `--quiet` / `-q` global flag to suppress warnings
- `--format env` output format
- Metadata index (`vault.index.json`) for passphrase-free `list` and `search`
- Session status in `sotto status` output
- Delete feedback shows resolved `sotto://` reference

## [0.2.0] - 2026-03-08

### Added
- First release: encrypted local vault, profile/project scoping, ephemeral tokens, subprocess injection
