# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Keep it brief!

## [0.2.0] - 2026-03-08

### Added
- First release
- Encrypted local vault (age + scrypt)
- Profile/project/global scoping with dotted project inheritance
- Context detection from flags, env, and `.sotto.toml`
- Commands: init, set, get, del, list, status, env, import, wrap
- Ephemeral tokens (sottok_*) with TTL and use limits
- Node abstraction with local and remote-ready config
- Subprocess secret injection via `sotto env --`
