# Setup and discovery

Read this when initializing the CLI, configuring roots, or diagnosing missing skills.

## Initialization and scope

```bash
agent-playbooks admin init
agent-playbooks admin doctor
```

Initialization is safe to repeat. `--repair-shell-alias` explicitly adds the
optional `apb` alias. `admin doctor` reports effective roots, malformed skills,
duplicates, variant drift, and router drift.

`--project PATH` selects the project location. `--scope` selects roots before
merging, de-duplication, and ranking. `--project PATH` alone still includes
personal and global roots; add `--scope project` to exclude them:

| Scope | Roots |
|---|---|
| `all` (default) | Project, then personal and global |
| `project` | Project only |
| `global` | Personal and global only |

```bash
agent-playbooks index --project /path/to/repo --scope project
agent-playbooks read NAME --project /path/to/repo --scope project
agent-playbooks search "<task>" --scope global
```

`--global` aliases `--scope global`. Global scope conflicts with `--project`;
`--global` also conflicts with explicit `--scope all` or `--scope project`.
These combinations and invalid scopes exit with usage code 2.

An isolated config (`--config-dir` or `PLAYBOOKS_CONFIG_DIR`) keeps implicit
project discovery disabled under scope `all`, including explicit `--scope all`.
Pass `--project PATH` or `--scope project` to enable it.

## Project discovery

From the working directory, the CLI selects the nearest Git worktree root,
even below a nested manifest or native root. Outside Git it uses the working
directory. `--project PATH` selects an explicit location and its manifest.
It scans `.claude/skills`, `.claude/commands`, `.agents/skills`, and
`.codex/skills` there when present. Global defaults include the same paths
under `~`.

Add custom or additional project folders to `.agent-playbooks.yaml`. Its
`roots` list can contain multiple entries; use `kind: skills` for directories
with `SKILL.md` files and `kind: commands` for Markdown command files. Example:

```yaml
version: 1
roots:
  - name: team-skills
    path: playbooks
    kind: skills
    recursive: true
  - name: cursor-commands
    path: .cursor/commands
    kind: commands
    recursive: true
```

Manifest paths are relative to the project and must stay inside it after
symlink resolution. Cursor `.mdc` rules are not read as Markdown commands.
Use the project manifest for repository roots and `config.yaml` for personal
roots.

Native roots and recursive folder discovery need no manifest. Discovery is
enabled by default. Global `config.yaml` supplies discovery defaults; the
selected project's `.agent-playbooks.yaml` overrides individual fields.
Omitted settings inherit; lists replace inherited lists, and `exclude: []`
clears inherited exclusions. `enabled: false` disables auto-discovery only,
not explicit or native roots. For example, in global `config.yaml`:

```yaml
discovery:
  enabled: true
  directory_names: [skills]
  max_depth: 4
```

Discovery defaults to exact directory basename `skills` and depth 4, with the
project at depth 0. For example,
`project-guides/topics/<topic>/skills/<skill>/SKILL.md` fits the default depth: its
`skills` root is at depth 4. Each auto root loads only direct
`<child>/SKILL.md` skills; child inspection is separate from root search depth.
For a root at `skills/`, `max_depth: 1` includes `skills/review/SKILL.md` but
does not recursively load `skills/team/review/SKILL.md`.

| Setting | Default | Meaning |
|---|---|---|
| `enabled` | `true` | Enable bounded recursive folder discovery |
| `directory_names` | `[skills]` | Nonempty exact basenames, without paths or patterns |
| `max_depth` | `4` | Depth of the root directory, from `0` to `16`; project is `0` |
| `exclude` | `[]` | Literal auto-discovery subtree paths relative to the project; absolute or escaping paths are rejected |

Auto root and direct-child checks prune symlink directories, nested `.git`
files/directories, Git-ignored directories, excludes, and these names: `.git`,
`node_modules`, `vendor`, `.venv`, `venv`, `__pycache__`, `.cache`, `.next`,
`.nuxt`, `dist`, `build`, `target`, `coverage`. Git inspection failures are
errors. Outside Git, fixed-name and exclude checks still apply.

Precedence is explicit manifest roots, native roots, then auto roots sorted by
relative path. Global roots follow when included by the scope. Earlier roots
win physical-root duplicates and skill name collisions. Native order is
`.claude/skills`, `.codex/skills`, `.agents/skills`, then `.claude/commands`.
Auto-discovery pruning and excludes do not filter explicit or native roots;
those keep their configured recursion.

Inspect discovery without creating a manifest:

```bash
agent-playbooks index --project . --scope project
agent-playbooks admin doctor --project . --scope project --human
```

## Synchronize the loader skill

The binary bundles `SKILL.md` and its reference pages. Preview before applying:

```bash
agent-playbooks admin sync-router --target ~/.claude/skills/using-agent-playbooks/SKILL.md
agent-playbooks admin sync-router --target ~/.claude/skills/using-agent-playbooks/SKILL.md --apply
```

Use the equivalent `~/.codex/skills/using-agent-playbooks/SKILL.md` target for
Codex. Sync installs the entrypoint and bundled references, preserving unrelated
files.
Locally modified owned files require `--force`, which backs them up before
replacement. `admin doctor` reports drift in the loader and its references.
