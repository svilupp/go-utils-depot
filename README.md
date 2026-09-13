# go-utils-depot

Go CLI utilities. Pre-built binaries for macOS, Linux, and Windows.

## Install

Grab any tool with [eget](https://github.com/zyedidia/eget):

```bash
# Install eget first (if you don't have it)
brew install eget  # or see https://github.com/zyedidia/eget#install

# Install a tool
eget svilupp/go-utils-depot --tag 'sotto/v0.3.0' --to ~/.local/bin
```

Make sure `~/.local/bin` is in your `PATH`:

```bash
# Add to your shell profile (~/.zshrc, ~/.bashrc, etc.)
export PATH="$HOME/.local/bin:$PATH"
```

## Tools

| Tool | Description | Install |
|------|-------------|---------|
| [sotto](sotto/) | Local-first encrypted secrets CLI | `eget svilupp/go-utils-depot --tag 'sotto/v0.3.0'` |
| [notion](notion/) | Notion API CLI with profiles and OAuth | `eget svilupp/go-utils-depot --tag 'notion/v0.3.0'` |
| [linear](linear/) | Linear API CLI for tickets and comments | `eget svilupp/go-utils-depot --tag 'linear/v0.15.0'` |
| [wipd](wipd/) | Per-folder task tracker for AI agents | `eget svilupp/go-utils-depot --tag 'wipd/v0.1.0'` |
| [logfire-trace](logfire-trace/) | Logfire trace downloader, viewer, and AI conversation replayer | `eget svilupp/go-utils-depot --tag 'logfire-trace/v0.17.0'` |
| [logfire-viewer](logfire-viewer/) | Local web dashboard for AI conversation traces with multi-source fusion, plus an eval scenario/manifest config explorer | `eget svilupp/go-utils-depot --tag 'logfire-viewer/0.5.0'` |
| [newrelicexplorer](newrelicexplorer/) | New Relic logs & errors CLI (NRQL/NerdGraph, EU) | `eget svilupp/go-utils-depot --tag 'newrelicexplorer/v0.2.0'` |
| [sentryexplorer](sentryexplorer/) | Sentry issues & errors CLI (curated projects) | `eget svilupp/go-utils-depot --tag 'sentryexplorer/v0.3.0'` |
| [openrouterexplorer](openrouterexplorer/) | OpenRouter catalog, pricing & policy-routed chat CLI | `eget svilupp/go-utils-depot --tag 'openrouterexplorer/v0.2.0'` |
| [agent-playbooks](agent-playbooks/) | Portable, harness-aware guidance CLI for coding agents | `eget svilupp/go-utils-depot --tag 'agent-playbooks/v0.3.0'` |
| [slack](slack/) | Slack Web API CLI: cached reads, channel polling, rate-limited | `eget svilupp/go-utils-depot --tag 'slack/v0.2.0'` |
| [argocdexplorer](argocdexplorer/) | Read-only ArgoCD explorer CLI (health, sync, logs, triage) | `eget svilupp/go-utils-depot --tag 'argocdexplorer/v0.1.0'` |
| [lightdashctl](lightdashctl/) | Lightdash discovery, query, and content-as-code CLI (`ldc`) | `eget svilupp/go-utils-depot --tag 'lightdashctl/v0.1.0'` |
| [dbexplorer](dbexplorer/) | Read-only PostgreSQL and BigQuery query and catalog CLI (`dbx`) | `eget svilupp/go-utils-depot --tag 'dbexplorer/v0.1.0'` |
| [firestoreexplorer](firestoreexplorer/) | Read-only, policy-filtered Firestore explorer (`fsx`) | `eget svilupp/go-utils-depot --tag 'firestoreexplorer/v0.1.0'` |
| [agenticforge](agenticforge/) | Plan-first installer for CLIs, configs, and agent skills (`agf`) | `eget svilupp/go-utils-depot --tag 'agenticforge/v0.1.0'` |

## Updating

Use the release tag for the version you want:

```bash
eget svilupp/go-utils-depot --tag 'sotto/v0.3.0' --to ~/.local/bin
```

## Platforms

Tools are built for these platforms where the source module supports them:

| OS | Architecture |
|----|-------------|
| macOS | Intel (amd64), Apple Silicon (arm64) |
| Linux | amd64, arm64 |
| Windows | amd64 |

`lightdashctl` and `dbexplorer` currently ship macOS and Linux binaries only.
