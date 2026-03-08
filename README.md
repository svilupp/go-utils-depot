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
| [logfire-trace](logfire-trace/) | Logfire trace downloader, viewer, and AI conversation replayer | `eget svilupp/go-utils-depot --tag 'logfire-trace/*'` |

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

