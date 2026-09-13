---
name: using-agenticforge
description: Install, update, inspect, and remove team CLIs, configs, and agent skills with Agenticforge (agf). Use for setup and maintenance, not for operating an installed tool.
---

# Use Agenticforge

Use `agenticforge` in scripts. `agf` is an optional shell alias.

## Discovery

- Read `agenticforge --help` for the quick start.
- Run `agenticforge init` on a new machine.
- Run `agenticforge schema` when constructing automation.
- Use `agenticforge status` or `agenticforge doctor` for inspection.

The first `sync --non-interactive --yes` installs only the bundled guidance
skill until an app preset is selected.

## Install and update

1. Configure app providers in a catalog.
2. Preview a preset:
   `agenticforge --catalog /path/to/catalog.yaml install --preset NAME --dry-run --human`.
3. Select the preset after reviewing the plan:
   `agenticforge --catalog /path/to/catalog.yaml install --preset NAME --non-interactive --yes`.
4. Use `agenticforge sync` to install missing selected resources and update
   managed resources.
5. Use `agenticforge update` only for resources already selected and installed.
6. Parse the JSON result. A partial result is not success.

Use `--non-interactive --yes` only for an explicitly authorized bounded
mutation. `--dry-run` must not write persistent state or retrieve secret values.
The `--catalog` flag applies to one invocation. Set `catalog: /path/to/catalog.yaml`
in Agenticforge's config, or repeat `--catalog /path/to/catalog.yaml` on later
`sync` and `update` commands.

## Paths and credentials

Review resource destinations and the configured cache, source, backup, state,
lock, and preference paths. Install also saves selections in the Agenticforge
config. Do not substitute a native agent path when the config names an explicit
target.

If a provider or source reports an authentication failure, complete that
provider's login flow and retry. Never guess credentials or print resolved
secrets. File, `op read`, and `op inject` sources keep resolved values out of
Agenticforge's own config, state, plans, and logs; managed destination files may
contain them and can remain in backups.

## Conflicts and removal

- An unmanaged file or locally changed managed file is a conflict. Report its
  path and stop.
- Do not use a broad force flag, delete state, or overwrite a conflict.
- Preview `agenticforge admin remove ... --dry-run --human` before removal.
- Removal is limited to files in the ownership ledger and creates a recoverable
  backup. Inspect the backup before pruning it.

## Output

JSON is the default stdout format. Use `--human` for terminal tables and
progress. Prompts and diagnostics go to stderr. Exit `3` means a conflict,
approval, or lock failure; inspect the structured result before retrying.

Use the installed tool's own documentation for operating a selected CLI.
