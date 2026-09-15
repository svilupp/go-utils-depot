---
name: using-agenticforge
description: Install, update, inspect, and remove team CLIs, configs, and agent skills with Agenticforge (agf). Use for team developer setup and maintenance, not for operating the installed tools themselves.
---

# Using Agenticforge

Use `agenticforge` for the executable name. `agf` is an optional interactive-shell alias and may not exist in scripts or agent subprocesses.

## Start here

1. Run `agenticforge init` once (rerun any time to update). It requires
   `eget` on `PATH` and a signed-in 1Password CLI, requires a local clone of
   your team's skill repository (a git checkout containing a `skills/`
   folder, registered as source `team-skills`), and asks which skill
   destination to use: `claude`,
   `codex`, `pi`, `agent-playbooks`, or `custom=/abs/path`. Rerunning prefills
   every prompt with the current value; Enter keeps it, and nothing is
   written when nothing changed.
2. Run `agenticforge install --preset <name>` to install selected tools.
3. Run `agenticforge status` to check the installed files.
4. Run `agenticforge update` to update installed tools.
5. Run `agenticforge self update --yes` to update Agenticforge itself.
6. Use `agenticforge skill list`, `skill install <id...>`, and `skill select`
   to inspect and choose skills from the catalog or the configured
   `skills.source` repository (default `team-skills`).

`update` installs missing selected resources and refreshes existing ones. There
is no separate `sync` command.

Use `--human` for terminal output. JSON is the default for scripts. Use
`--non-interactive --yes` only for an explicitly authorized mutation.

## Advanced commands

- `admin`: `plan`, `doctor`, `apps`, `presets`, `remove`
- `config`: `show`, `path`, `validate`, `targets`, `sources`, `shell`, `completion`
- `agent`: `schema`, `skill`, `version`

Read `agenticforge <command> --help` before using an advanced command.

## Paths and credentials

- Treat all configured paths as the mutation scope: `paths.bin_dir`,
  `paths.config_dir`, skill target paths, data, cache, source, backup, state,
  lock, and shell `rc_file` paths.
- Fresh setups put managed CLI configs under `~/.config` and binaries under
  `~/.local/bin`; keep the configured paths authoritative.
- If `~/.local/bin` is not on `PATH`, follow the post-install shell-profile
  instruction before invoking an installed CLI.
- `self update` stages the latest release, backs up the current binary, and
  activates it in the configured `paths.bin_dir`.
- Before a mutation that installs or updates CLI resources, or includes an
  `op-read` or `op-inject` config, Agenticforge checks that `op` is available
  and signed in. Follow its sign-in prompt. If login is deferred, run the
  printed configs-only command after logging in.
- `agenticforge config list` shows the built-in id -> 1Password item +
  destination mapping (`internal/opconfigs/opconfigs.yaml`) without resolving
  any secret. `agenticforge install <app>` resolves the mapped value with
  `op read` and writes the config; it never prints the resolved value.
- An `op read`/`op inject` result that is empty or whitespace-only, or a
  config body that parses to an empty/null YAML or JSON document, is rejected
  before anything is staged or written; the destination stays untouched and
  the resource reports `failed`. The error never includes the ref or any
  resolved bytes.
- `configs.<id>.destination` in the Agenticforge config overrides one config
  resource's path (still relative to `paths.config_dir`) without moving
  everything else; use `paths.config_dir` itself for a whole-tree relocation
  when testing safely.
- Skill installation uses the configured local skill-repository source (the
  required team skill-repository clone, registered as `team-skills`
  unless overridden). Never invent a repository URL or silently substitute a
  native target. Dotfiles and dotdirs (`.env*`, `.git`, etc.) are never
  copied from a skill's source tree.
- With `skills.auto_install_app_skills` enabled (default), every selected app
  also auto-plans its `using-<app-id>`/`using-<app-id>-cli` skill from the
  configured skill source (hyphen-insensitive match); a missing source or no
  match is silently tolerated. Pass `--no-skills` on `install`/`update`/
  `admin plan` to skip that for one run, or set
  `skills.auto_install_app_skills: false` to disable it. `admin remove <app>
  --with-skills` removes the auto-discovered skill too.
- If a provider or source reports an authentication failure, ask the user to complete the corresponding 1Password or GitHub login flow and retry; never guess credentials.
- Never request, print, or copy resolved secrets into chat, logs, plans, or state.

## Conflicts and removal

- For resource installation, update, and removal, a pre-existing unmanaged file
  or locally modified managed file is a conflict. Report the exact path and stop.
- Config conflicts can be overwritten only with `--overwrite-configs` (plus
  `--yes` and, interactively, typing `overwrite` at a second confirmation).
  `--yes` counts as approval for both confirmations; without `--yes` in a
  terminal you must confirm the plan and then type `overwrite`. The previous
  file is always backed up first.
- `self update` is the dedicated binary replacement exception: it accepts only
  the exact configured target, asks for confirmation, and backs up the current
  regular file before activation. It does not use the ownership ledger. Its
  release channel is GitHub releases on `svilupp/go-utils-depot`, filtered to
  non-draft, non-prerelease tags matching `agenticforge/*`.
- Do not use a broad force flag, delete the state file, or overwrite a conflict to make a command pass.
- Preview `agenticforge admin remove ... --dry-run --human` before removal.
- App removal retains shared configs and skills unless the user explicitly requests their removal.
- Agenticforge removes only files in its ownership ledger and keeps recoverable backups under the configured backup directory. There is currently no automatic restore command; inspect that directory before pruning it.

Do not use this skill to operate Linear, New Relic, Sentry, database, Firestore, Logfire, or Argo CD commands. Use the skill for the installed tool when the task is about one of those services.
