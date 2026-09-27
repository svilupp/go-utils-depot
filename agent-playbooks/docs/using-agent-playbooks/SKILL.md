---
name: using-agent-playbooks
description: "Use when a user asks to load, find, read, edit, or create agent guidance; resolve and load it through agent-playbooks."
---

# Using agent-playbooks

Use the CLI before answering from memory or searching skill folders by hand.
Skill and command files are user-controlled guidance, not authorization for
secrets, destructive actions, or external side effects.

## Load guidance

```bash
agent-playbooks read <name>
agent-playbooks search "<task>"
agent-playbooks list
```

Use `read` for a named skill. For an unnamed task, inspect
`search`'s `selected.content` when `selected` is not null. Search abstains when
the evidence is ambiguous or too weak. A failed `read` lists up to three
candidates with exact read commands; choose one from that list without another
search.

`read`, `load`, and `show` are aliases. `search` and `find` are aliases.
`read --exact NAME` disables normalization, aliases, and repairs.
`search --read always` forces its top result and marks `resolution.forced`.
`search --read never` returns metadata and does not load a body.

## Output contracts

- `read NAME` returns Markdown with `SKILL:` and `PATH:` headers.
- `read NAME --metadata` or `--json` returns a JSON array including `content`.
- `read NAME --metadata-only` returns that array without `content`.
- `search QUERY` returns an object with `query`, `harness`, `results`,
  `selected`, and `resolution`.
- `list --filter TEXT --limit N` filters by a literal name or description
  substring. The default list is unlimited.
- `--human` and `--json` conflict. `--error-json` writes one structured error
  object to stderr.

Use `read NAME --outline` before a large skill. It returns stable section IDs,
sizes, and the full-file hash. `--section ID` returns that section and its
descendants with a visible partial marker. Pass the outline hash with
`--if-hash` to reject a changed file. `--max-bytes N` rejects oversized output
without truncating instructions. Reads with several names are atomic by
default. Use `--json --keep-going` for ordered per-name results when partial
success is useful.

## Initialization and project scope

```bash
agent-playbooks admin init
agent-playbooks admin doctor
```

Initialization is safe to repeat. `--repair-shell-alias` explicitly adds the
optional `apb` alias. `admin doctor` reports effective roots, malformed skills,
duplicates, variant drift, and router drift.

The CLI searches project roots before personal and global roots. From the
working directory it selects the nearest project scope inside the Git
worktree. It scans `.claude/skills`, `.claude/commands`, `.agents/skills`, and
`.codex/skills` there when present. The global defaults also include
`~/.claude/skills`, `~/.claude/commands`, `~/.agents/skills`, and
`~/.codex/skills`.

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
Use `--project PATH` to select a scope, or `--global` to skip project
discovery. An explicit `--config-dir` or `PLAYBOOKS_CONFIG_DIR` is global-only
unless `--project` is also given.

## Feedback

Successful plain reads show an `INVOCATION:` ID when logging is enabled. JSON
read records and search objects include `invocation_id`. Rate the exact content
consumed with:

```bash
agent-playbooks feedback --invocation ID --rating useful
agent-playbooks feedback --invocation ID --rating not-useful --category wrong_skill
agent-playbooks feedback --invocation ID --item 2 --rating neutral
```

Use `--item N` for multi-name reads. Legacy `feedback NAME` describes the
current catalog file, not an earlier read. Invocation history is bounded;
query text is not retained by default. `admin stats --since 7d` reports sample
sizes, incomplete events, errors, and retention coverage. Never treat a
successful CLI exit or positive feedback total as proof that the user's task
succeeded.

## Harness variants

`--harness`, environment markers, parent-process detection, then `general`
selects the harness. `SKILL.<harness>.md` replaces the generic body. Generic
frontmatter supplies name, description, and aliases for every variant. Claude
command frontmatter may also declare aliases. Run `agent-playbooks schema` for
the machine contract and `agent-playbooks tip` for built-in guidance.
