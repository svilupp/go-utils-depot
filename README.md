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
