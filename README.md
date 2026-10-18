# go-utils-depot

Go CLI utilities. Pre-built binaries for macOS, Linux, and Windows.

## Install

Grab any tool with [eget](https://github.com/zyedidia/eget):

```bash
# Install eget first (if you don't have it)
brew install eget  # or see https://github.com/zyedidia/eget#install

# Install a tool
eget svilupp/go-utils-depot --tag 'sotto/' --to ~/.local/bin
```

Make sure `~/.local/bin` is in your `PATH`:

```bash
# Add to your shell profile (~/.zshrc, ~/.bashrc, etc.)
export PATH="$HOME/.local/bin:$PATH"
```

## Tools

| Tool | Description | Install |
|------|-------------|---------|
| [sotto](sotto/) | Local-first encrypted secrets CLI | `eget svilupp/go-utils-depot --tag 'sotto/' --to ~/.local/bin` |
| [notion](notion/) | Notion API CLI with profiles and OAuth | `eget svilupp/go-utils-depot --tag 'notion/' --to ~/.local/bin` |
| [linear](linear/) | Linear API CLI for tickets and comments | `eget svilupp/go-utils-depot --tag 'linear/' --to ~/.local/bin` |
| [wipd](wipd/) | Per-folder task tracker for AI agents | `eget svilupp/go-utils-depot --tag 'wipd/' --to ~/.local/bin` |
| [logfire-trace](logfire-trace/) | Logfire trace downloader, viewer, and AI conversation replayer | `eget svilupp/go-utils-depot --tag 'logfire-trace/' --to ~/.local/bin` |
| [logfire-viewer](logfire-viewer/) | Local web dashboard for AI conversation traces with multi-source fusion, plus an eval scenario/manifest config explorer | `eget svilupp/go-utils-depot --tag 'logfire-viewer/' --to ~/.local/bin` |
| [newrelicexplorer](newrelicexplorer/) | New Relic logs & errors CLI (NRQL/NerdGraph, EU) | `eget svilupp/go-utils-depot --tag 'newrelicexplorer/' --to ~/.local/bin` |
| [sentryexplorer](sentryexplorer/) | Sentry issues & errors CLI (curated projects) | `eget svilupp/go-utils-depot --tag 'sentryexplorer/' --to ~/.local/bin` |
| [openrouterexplorer](openrouterexplorer/) | OpenRouter catalog, pricing & policy-routed chat CLI | `eget svilupp/go-utils-depot --tag 'openrouterexplorer/' --to ~/.local/bin` |
| [agent-playbooks](agent-playbooks/) | Portable, harness-aware guidance CLI for coding agents | `eget svilupp/go-utils-depot --tag 'agent-playbooks/' --to ~/.local/bin` |
| [slack](slack/) | Slack Web API CLI: cached reads, channel polling, rate-limited | `eget svilupp/go-utils-depot --tag 'slack/' --to ~/.local/bin` |
| [argocdexplorer](argocdexplorer/) | Read-only ArgoCD explorer CLI (health, sync, logs, triage) | `eget svilupp/go-utils-depot --tag 'argocdexplorer/' --to ~/.local/bin` |
| [lightdashctl](lightdashctl/) | Lightdash discovery, query, and content-as-code CLI (`ldc`) | `eget svilupp/go-utils-depot --tag 'lightdashctl/' --to ~/.local/bin` |
| [dbexplorer](dbexplorer/) | Read-only PostgreSQL and BigQuery CLI with named auth profiles (`dbx`) | `eget svilupp/go-utils-depot --tag 'dbexplorer/' --to ~/.local/bin` |
| [firestoreexplorer](firestoreexplorer/) | Read-only, policy-filtered Firestore explorer with named auth profiles (`fsx`) | `eget svilupp/go-utils-depot --tag 'firestoreexplorer/' --to ~/.local/bin` |
| [agenticforge](agenticforge/) | Plan-first installer for CLIs, configs, and agent skills (`agf`) | `eget svilupp/go-utils-depot --tag 'agenticforge/' --to ~/.local/bin` |
| [revlet](revlet/) | Browser document review, batch annotation, and optional AI assistance | `eget svilupp/go-utils-depot --tag 'revlet/' --file 'revlet' --to ~/.local/bin` |

## Updating

Re-run the install command to get the latest release. A tag ending in `/`
resolves to the newest version of that tool; pin an exact version by
appending it:

```bash
eget svilupp/go-utils-depot --tag 'sotto/' --to ~/.local/bin        # latest
eget svilupp/go-utils-depot --tag 'sotto/v0.3.0' --to ~/.local/bin  # pinned
```

## Platforms

Tools are built for these platforms where the source module supports them:

| OS | Architecture |
|----|-------------|
| macOS | Intel (amd64), Apple Silicon (arm64) |
| Linux | amd64, arm64 |
| Windows | amd64 |

`lightdashctl` and `dbexplorer` currently ship macOS and Linux binaries only.
Revlet's live-browser mode requires extracting its complete platform archive;
see [Revlet installation](revlet/#install).
