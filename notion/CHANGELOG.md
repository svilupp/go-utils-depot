# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Keep it brief!

## [0.3.0] - 2026-07-07

### Added
- `notion comment list` now works with hosted MCP (`mcp_oauth`) profiles and can pull page discussions, including `--include-all-blocks`, `--include-resolved`, and `--discussion-id`.

## [0.2.0] - 2026-06-23

### Fixed
- Hosted MCP commands (`search`, `page get`, `mcp tools`, `mcp fetch`) no longer fail with `initialize response missing Mcp-Session-Id header`. The MCP session id is now treated as optional, so stateless MCP servers (including Notion's hosted MCP) work again.

## [0.1.0] - 2026-03-08

### Added
- First release: full Notion API surface, multi-workspace profiles, hosted MCP parity
