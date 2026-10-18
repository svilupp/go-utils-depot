# Agenticforge

`agenticforge` (`agf`) is a self-contained Go/Cobra CLI for installing and
maintaining a team’s agent-facing toolchain:

- app CLIs into a configured `bin_dir`;
- CLI configuration into a configured `config_dir`, including content read from
  1Password with `op read` or `op inject`;
- Markdown skills into one or more named, fully configurable targets.

## Install

```bash
eget svilupp/go-utils-depot --tag 'agenticforge/' --to ~/.local/bin
```

The binary ships its help, schema, release catalog, and the
`using-agenticforge` skill. Managed CLI configs default to `~/.config`, and
installed binaries default to `~/.local/bin`. Skill destinations are selected
during `init`, so a setup can use agent-playbooks, Claude, Codex, Pi, or an
isolated folder.

## Safety model

All mutation paths are explicit in YAML. The separate `bin_dir`, `config_dir`,
`skills.targets.*.path`, source, cache, backup, state, lock, and shell `rc_file`
settings can each be redirected to a temporary directory for tests or to an
administrative layout. `--config` and `--catalog` override them for one run.

Install/update are plan-first operations. `self update` stages the latest
published release, backs up the current binary, and activates it in
`paths.bin_dir`. For managed resource installation, update, and removal,
unmanaged files and locally changed managed files are conflicts; `--yes`
approves only the displayed operation. An existing unmanaged or locally
modified config is a conflict (exit 3) unless `--overwrite-configs` is set;
interactively that also requires typing `overwrite` at a second prompt, and
non-interactively it needs both `--yes` and `--overwrite-configs`. `--yes`
counts as approval for both confirmations; without `--yes` in a terminal you
must confirm the plan and then type `overwrite`. The previous file is always
backed up first. `self update` is the dedicated
binary replacement exception and backs up the exact configured target before
activation. Its release channel is GitHub releases on `svilupp/go-utils-depot`,
filtered to non-draft, non-prerelease tags matching `agenticforge/*`.
Removal is restricted to the ownership ledger and moves files to a
recoverable backup directory before deleting their active paths.

JSON is the default stdout contract. Human tables require `--human`; prompts
and diagnostics go to stderr. `schema_version`, `status`, `resources`, and
structured `error` fields are stable automation boundaries. The envelope's
`command` field is always the fully-qualified `cmd.CommandPath()` (e.g.
`agenticforge skill install`), never a short or aliased form.

`admin plan` defaults to `--operation install`, so it reports already-managed
resources as `unchanged`, matching `install --dry-run`. Pass `--operation
update` to preview a refresh instead; because there is no content diff, every
managed resource under `update` reports `update` regardless of whether its
content actually changed.

## Quick start

`init` has two hard prerequisites, checked before anything else:

- `eget` on `PATH` (used by `self update` and app installs). Missing it exits
  2 with an install hint (`brew install eget`).
- The 1Password CLI signed in for the configured account. `init` checks
  `op whoami` (`--account <account>` is added only when `auth.onepassword.account`
  is set); in a terminal it prints the sign-in command (`eval $(op signin)`,
  or `eval $(op signin --account <name>)` once an account is configured) and
  loops, re-checking after each Enter, until it passes or you abort.
  Non-interactively a failed check exits 3.

```sh
go build -o agenticforge .
brew install eget                                 # required by init and self update
eval $(op signin)                                 # required by init

# init verifies eget/1Password, requires a local skill repository clone
# (a git checkout containing a skills/ folder), and asks where skills
# should be installed.
./agenticforge init
~/.local/bin/agenticforge install --preset core
~/.local/bin/agenticforge status --human
~/.local/bin/agenticforge update
~/.local/bin/agenticforge self update --yes       # refresh Agenticforge itself
```

Fresh configuration selects no external apps until you choose a preset or app.
The built-in catalog contains pinned release providers. Beyond the `init`
gate above, install/update also stop before mutation when they would install
or refresh CLI resources, or apply an `op-read`/`op-inject` config, without a
ready 1Password session; follow the printed sign-in command, then rerun the
printed configs-only command. Unknown command names exit 2 (usage), not 1.

`init` is safe to re-run: it loads the existing config as the baseline, shows
and defaults every prompt to the current value, and writes nothing when
nothing changed. Pass `--force --yes` to reset to defaults first instead of
merging onto the existing config.

```sh
./agenticforge --catalog agenticforge.example.catalog.yaml \
  --config agenticforge.example.yaml \
  admin plan --operation update --dry-run --human
```

## Presets

A preset is a named bundle of catalog apps. `install --preset <name>` applies
one, and presets are additive: installing a second preset (or an individual
app) adds to the current selection rather than replacing it. Every applied
preset name is persisted into `selection.presets` in the config, so later
`update` and `admin plan` runs keep expanding the same set. Installing an app
(directly or through a preset) also auto-installs its `using-<app>` skill
when `skills.auto_install_app_skills` is enabled (the default).

```sh
agenticforge install --preset core
```

| Preset | Description | Apps |
| --- | --- | --- |
| `core` | Daily team tools. | `agent-playbooks`, `linear`, `newrelicexplorer`, `sentryexplorer`, `logfire-trace`, `argocdexplorer` |
| `data` | Core tools plus database explorers. | `core` apps plus `dbexplorer`, `firestoreexplorer`, `lightdashctl` |
| `tracing` | Core tools plus Logfire tools. | `core` apps plus `logfire-viewer` |
| `ai` | Core and data tools plus the Logfire viewer. | `core` apps plus `data` apps plus `logfire-viewer` |
| `all` | Every app in the built-in catalog. | every app listed in the Built-in catalog table below |

### Built-in catalog

| App | Description |
| --- | --- |
| `agent-playbooks` | Discover and load agent guidance. |
| `linear` | Read and manage Linear issues and comments. |
| `newrelicexplorer` | Query New Relic logs, errors, health, and traces. |
| `sentryexplorer` | Inspect Sentry issues and events. |
| `dbexplorer` | Read-only database exploration. |
| `firestoreexplorer` | Read-only Firestore exploration. |
| `logfire-trace` | Fetch, inspect, and replay Logfire traces. |
| `logfire-viewer` | Browse local Logfire trace and conversation records. |
| `argocdexplorer` | Read-only Argo CD inspection. |
| `lightdashctl` | Discover, query, and manage Lightdash content. |
| `openrouterexplorer` | Inspect OpenRouter models and route policy-aware chat. |

## Temporary E2E setup

Keep local and administrative installations untouched by routing every target to
one disposable root:

`--data-dir` alone relocates every data-derived path (`cache_dir`, `skills_dir`,
`source_dir`, `backup_dir`, `state_file`, `lock_file`) under the new root, as
long as they are still at their defaults; pass the more specific flags only
for paths outside the data root (`--bin-dir`/`--config-dir` default under the
user's home) or to override one path independently.

```sh
tmp_dir="$(mktemp -d)"
./agenticforge init --config "$tmp_dir/config.yaml" \
  --data-dir "$tmp_dir/data" \
  --bin-dir "$tmp_dir/bin" \
  --config-dir "$tmp_dir/config-target" \
  --rc-file "$tmp_dir/shellrc" \
  --catalog "$PWD/agenticforge.example.catalog.yaml"

./agenticforge --config "$tmp_dir/config.yaml" \
  install --preset core --dry-run --human
./agenticforge --config "$tmp_dir/config.yaml" \
  install --preset core --non-interactive --yes
./agenticforge --config "$tmp_dir/config.yaml" \
  update --non-interactive --yes
```

For an even smaller fixture, use a catalog whose provider is `fixture` or
`local-build`, a `file` config source, and a local skill source. The test suite
uses that pattern and verifies create, update, local-conflict, and removal
behavior without network access or secret resolution.

## Skill targets

Target IDs are stable names. Interactive `init` offers these destinations and
stores the selected path in the config:

```yaml
skills:
  default_targets: [safe]
  targets:
    safe:
      harness: general
      kind: skills
      enabled: true
      path: /path/to/skills-repo/skills
    claude:
      harness: claude
      kind: skills
      enabled: true
      path: ~/.claude/skills
    codex:
      harness: codex
      kind: skills
      enabled: true
      path: ~/.codex/skills
    pi:
      harness: pi
      kind: skills
      enabled: true
      path: ~/.pi/agent/skills
    agent-playbooks:
      harness: general
      kind: playbooks
      enabled: true
      path: ~/.config/agent-playbooks/skills
```

For `skills` targets, `SKILL.<harness>.md` is selected when present and
installed as `SKILL.md`; generic skills keep their generic body. `playbooks`
targets preserve the source tree. A custom target is added with:

```sh
agenticforge config targets set review --path ./example-skill-target \
  --harness general --kind skills --enable --default
```

## 1Password, config installs, and skill repositories

Catalog config resources use one of these source kinds:

```yaml
source: {kind: op-read, ref: op://ExampleVault/ExampleItem/config}
source: {kind: op-inject, path: fixtures/newrelic.yaml.tpl}
source: {kind: file, path: fixtures/newrelic.yaml}
```

The built-in catalog ships 1Password-backed config resources for the pinned
CLIs; the mapping lives in `internal/opconfigs/opconfigs.yaml`, an embedded,
editable file that maps a CLI ID to a 1Password item link and a destination
path. To add a config for a new CLI, append an entry there with:

```yaml
entries:
  - id: my-cli               # matches the catalog app ID
    item_link: "https://start.1password.com/open/i?..."  # the item's "Copy Link" URL
    destination: my-cli/config.yaml   # relative to paths.config_dir
    field: notesPlain         # optional; defaults to notesPlain
```

The account, vault, and item ID are all parsed from `item_link`, so no other
field is needed. `agenticforge config list` prints the mapping (ID,
destination, item link, managed/installed status) without ever resolving a
secret. `agenticforge install <app>` resolves and writes the mapped config
with `op read`. Agenticforge invokes the installed `op` CLI and never saves
the returned value in config, state, plans, or logs. CLI mutations and
mutations using 1Password-backed configs perform a readiness check first.
An `op read`/`op inject` response that is empty or whitespace-only is
rejected before anything is staged or activated, with a generic "1Password
returned no content for the config" error that never includes the ref or any
resolved bytes; the same applies to a config body that parses to an empty or
null YAML/JSON document. The destination is left untouched and the operation
reports the resource as `failed`.

A config's destination normally comes from the catalog/opconfigs entry
(relative to `paths.config_dir`). `configs.<id>.destination` in the
Agenticforge config overrides one resource's path without moving anything
else:

```yaml
configs:
  logfire-trace:
    destination: logfire-trace/config.yaml
```

For safe local testing of the whole tree at once, point `paths.config_dir`
(or `--config-dir`/`--data-dir`) at a disposable directory instead of
overriding every entry.

`agenticforge skill select` is an exact-set operation: a skill you leave
unchecked (or omit from `--ids`) is dropped from `selection.extra_skills`
only. Its installed files stay in place until `agenticforge admin remove
skill <id> <target>` removes them; `admin` is the only command group that
removes resources. `admin remove skill <id> <target>` drops the skill from
`selection.extra_skills` only once no other target still owns it in the
ownership ledger; otherwise it warns on stderr and leaves the selection
unchanged.

A local clone of your team's skill repository is required: it is the raw
source of every skill and must contain a `skills/` folder (any git
repository laid out that way works). `init` registers it as a `local` source
(default ID `team-skills`, override with `--skill-source-id`, which also sets
`skills.source` and is prefilled from the existing config on a re-run so it
never registers a duplicate source under a different name); in a terminal it
loops until a valid path is given, non-interactively it requires
`--skill-source-dir`:

```sh
agenticforge init --skill-source-dir /path/to/skills-repo \
  --skill-target claude
agenticforge config sources add team-skills --local /path/to/skills-repo
```

Skill destinations are one of `claude`, `codex`, `pi`, `agent-playbooks`, or
`custom=/abs/path`. `skills.source` in the config selects which registered
source ID `skill install`/`skill select` discover from (default
`team-skills`). Use `agenticforge skill list` to see catalog and discovered
repository skills with installed/selected state, `agenticforge skill install
<id...>` to select and apply specific IDs, and `agenticforge skill select` for
an interactive, prefilled multi-select. `agenticforge agent skill ...` is
kept working as an alias of `agenticforge skill ...`. Installed non-catalog skills are
recorded in `selection.extra_skills`. Dotfiles and dotdirs (`.env*`, `.git`,
etc.) in a skill's source tree are never copied to a destination.

When `skills.auto_install_app_skills` is enabled (the default), every
installed or updated app also gets its `using-<app-id>` (or
`using-<app-id>-cli`) skill added to the plan automatically, discovered from
the configured skill source (matched with hyphens ignored on both sides, so
`using-new-relic-explorer-cli` matches `newrelicexplorer`). When both
`using-<app-id>` and `using-<app-id>-cli` exist for the same app, only the
more specific `-cli` skill is installed. A missing source or no matching
skill is tolerated silently. Pass `--no-skills` on `install`/`update`/
`admin plan` to skip auto-discovery for one run, or set
`skills.auto_install_app_skills: false` to disable it permanently. Explicit
catalog `app.Skills` and `selection.extra_skills` entries are unaffected
either way, and an auto-discovered skill is deduped against an explicit one
with the same ID. `admin remove <app> --with-skills` removes the
app's auto-discovered skill too, alongside its catalog-declared skills, unless
that skill is also held in `selection.extra_skills` or still auto-matched by
another selected app, in which case it is kept and a warning is printed.

## Development

This folder is an independent Go module. Run checks from here:

```sh
make setup       # install the pinned golangci-lint tool if needed
make check       # fmt check, vet, lint, race tests, build, docs check
make install     # install only the agenticforge binary
```

`docs/using-agenticforge/SKILL.md` is checked byte-for-byte against the
embedded skill so the installed self-guidance cannot drift from the source
documentation.
