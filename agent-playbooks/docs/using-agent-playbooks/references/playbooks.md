# Playbook retrieval reference

Read this for matching, output formats, large or batch reads, and harness variants.

## Finding and reading

```bash
agent-playbooks read <name> [<name> ...]
agent-playbooks search "<task>"
agent-playbooks index --scope project
agent-playbooks index --scope global
```

Use `read` for named skills. Prefer one invocation with multiple names whenever
the needed playbooks are known, for example `agent-playbooks read robot-mode
repo-map`. Results retain input order. Address-style references
(such as `playbook://NAME`) are optional agent-facing shorthand. Strip the
address prefix and pass the bare playbook name to the CLI; no specific prefix
is required.

For an unnamed task, `search` defaults to `--read auto`: a confident scoring hit
is automatically read and returned in `selected.content`. Consume that body
directly; a second `read` is unnecessary. Search abstains (`selected: null`)
when the evidence is ambiguous or too weak. A failed `read` lists up to three
candidates with suggested read commands; choose one from that list without
another search. The commands pin the resolved absolute config directory,
detected harness, effective scope, and selected absolute project when active.
Run the suggested command to preserve the catalog from another working
directory.

`read`, `load`, and `show` are aliases. `search` and `find` are aliases.
`list`, `ls`, and `index` are aliases.
`read --exact NAME` disables normalization, aliases, and repairs.
`search --read always` forces its top result and marks `resolution.forced`.
`search --read never` returns metadata and does not load a body.

## Output and bounded reads

- `read NAME` returns Markdown with `SKILL:` and `PATH:` headers.
- `read NAME --metadata` or `--json` returns a JSON array including `content`.
- `read NAME --metadata-only` returns that array without `content`.
- `search QUERY` returns an object with `query`, `harness`, `results`,
  `selected`, and `resolution`.
- `list`, `ls`, and `index` return the same JSON array. `--filter TEXT` matches
  a literal name or description substring; `--limit N` bounds the result.
  The default list is unlimited.
- Skill, read, search-result, resolution, and candidate records include
  `scope: project|global`. Existing `shadowed` values remain strings.
- `--human` and `--json` conflict. `--error-json` writes one structured error
  object to stderr.

Use `read NAME --outline` before a large skill. It returns stable section IDs,
sizes, and the full-file hash. `--section ID` returns that section and its
descendants with a visible partial marker. Pass the outline hash with
`--if-hash` to reject a changed file. `--max-bytes N` rejects oversized output
without truncating instructions. Reads with several names are atomic by
default. Use `--json --keep-going` for ordered per-name results when partial
success is useful.

## Harness variants

`--harness`, environment markers, parent-process detection, then `general`
selects the harness. `SKILL.<harness>.md` replaces the generic body. Generic
frontmatter supplies name, description, and aliases for every variant. Claude
command frontmatter may also declare aliases. Run `agent-playbooks schema` for
the machine contract and `agent-playbooks tip` for built-in guidance.
