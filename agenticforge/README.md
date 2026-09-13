# agenticforge (`agf`)

Plan-first CLI for installing and synchronizing team CLIs, configuration, and
agent skills from explicit catalogs and sources.

## Install

```bash
eget svilupp/go-utils-depot --tag 'agenticforge/v0.1.0' --to ~/.local/bin

# Optional shell alias
alias agf='agenticforge'
```

## Quick start

```bash
agenticforge init
agenticforge targets list --human
agenticforge plan --operation sync --dry-run --human
agenticforge sync --non-interactive --yes
agenticforge status --human
```

The default data root is `~/.local/share/agenticforge`. The first sync installs
the bundled guidance skill; external apps stay unselected until a catalog and
preset choose them.

## Commands

| Command | Purpose |
| --- | --- |
| `init` | Write a credential-free config |
| `plan` | Preview resource destinations, actions, provider requirements, and conflicts |
| `install` | Select and install a catalog preset |
| `sync` | Install missing resources and update selected resources |
| `update` | Update resources that are already selected and installed |
| `status/doctor` | Inspect state, sources, providers, and conflicts |
| `targets` | Configure and list skill destinations |
| `sources` | Add and inspect local or Git skill sources |
| `schema` | Print the machine-readable command contract |
| `admin remove` | Preview and remove owned resources with a backup |

## Safety model

- Install, sync, update, and resource removal are plan-first. Interactive
  approval defaults to No; non-interactive mutations require `--yes`.
- Configuration commands can write without prompting. Preview them with
  `--dry-run` when the command supports it. Set binary and config destinations
  through `init --bin-dir/--config-dir` or YAML.
- Target paths come from configuration. Defaults stay below Agenticforge's data
  root and do not write native agent folders or shell files.
- Unmanaged files and locally changed managed files are conflicts. `--yes` does
  not override them.
- Removal is limited to the ownership ledger and moves active files to a
  private backup before removal.
- Secret sources can use files, `op read`, or `op inject`. Resolved values may
  be written to managed config destinations and remain in recoverable backups;
  they are excluded from Agenticforge's own config, ownership state, plans, and
  logs.

## Output

JSON is the default stdout format. `--human` renders terminal tables and
progress. Prompts, warnings, and diagnostics go to stderr.

Exit `0` means the plan or operation completed, `1` is a runtime or provider
failure, `2` is invalid usage or configuration, and `3` is a conflict,
approval, or lock failure.

See [CHANGELOG.md](CHANGELOG.md) and
[docs/using-agenticforge/SKILL.md](docs/using-agenticforge/SKILL.md).
