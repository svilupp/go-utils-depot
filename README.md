# go-utils-depot

Go CLI utilities. Pre-built binaries for macOS, Linux, and Windows.

## Install

Grab any tool with [eget](https://github.com/zyedidia/eget):

```bash
# Install eget first (if you don't have it)
brew install eget  # or see https://github.com/zyedidia/eget#install

# Install a tool
eget svilupp/go-utils-depot --tag 'sotto/*' --to ~/.local/bin
```

Make sure `~/.local/bin` is in your `PATH`:

```bash
# Add to your shell profile (~/.zshrc, ~/.bashrc, etc.)
export PATH="$HOME/.local/bin:$PATH"
```

## Tools

| Tool | Description | Install |
|------|-------------|---------|
| [sotto](sotto/) | Local-first encrypted secrets CLI | `eget svilupp/go-utils-depot --tag 'sotto/*'` |
| [notion](notion/) | Notion API CLI with profiles and OAuth | `eget svilupp/go-utils-depot --tag 'notion/*'` |
| [linear](linear/) | Linear API CLI for tickets and comments | `eget svilupp/go-utils-depot --tag 'linear/*'` |
| [wipd](wipd/) | Per-folder task tracker for AI agents | `eget svilupp/go-utils-depot --tag 'wipd/*'` |

## Updating

Run the same `eget` command again to get the latest release:

```bash
eget svilupp/go-utils-depot --tag 'sotto/*' --to ~/.local/bin
```

## Platforms

All tools are built for:

| OS | Architecture |
|----|-------------|
| macOS | Intel (amd64), Apple Silicon (arm64) |
| Linux | amd64, arm64 |
| Windows | amd64 |

## Adding a new tool

Each tool gets its own folder with docs:

```
<tool>/
├── README.md               # What it is, when to use it, install, quick start
├── CHANGELOG.md             # Keep a Changelog format
└── docs/
    ├── SKILL.md             # Full usage guide (all commands, workflows, examples)
    └── <other>.md           # Additional reference docs as needed
```

Steps:

1. Create `<tool>/README.md` and `<tool>/docs/SKILL.md` (copy from source, fix install line to use eget)
2. Add the tool to the table above
3. Commit and push

## Releasing a version

Binaries are cross-compiled locally and uploaded via `gh`:

```bash
./scripts/release.sh <source-dir> <tool> <version>

# Examples
./scripts/release.sh ../path-to-source/sotto sotto v0.2.0
./scripts/release.sh ../path-to-source/notion notion v0.1.0
./scripts/release.sh ../path-to-source/linear linear v0.3.0
```

This builds static binaries for all 5 platforms, packages them, generates checksums, and creates a GitHub release tagged `<tool>/<version>`.

Requires `go` and `gh` (authenticated to the svilupp account).
