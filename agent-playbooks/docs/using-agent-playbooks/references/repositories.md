# Repository map reference

Read this to configure repository entries or understand filtering and output.

```bash
agent-playbooks tip repos
agent-playbooks tip repos app
agent-playbooks tip repos example
agent-playbooks tip repos --human
```

Treat address-style references as shorthand: strip `repo://` and query the
bare name or alias. The CLI also accepts that prefix case-insensitively.
Case-insensitive
exact names and aliases match first; otherwise literal substring matching
searches names and aliases only. All matches are returned. Choose the target
from the returned entries or clarify when ambiguous. Unknown queries return
`repos: {}` with guidance and exit 0. Blank queries, empty references, other
URI schemes, and path/query/fragment suffixes are usage errors (exit 2).
Surrounding whitespace is trimmed; identifiers then reject whitespace, control
characters, and `:`, `/`, `\`, `?`, `#`.

The global `config.yaml` map is independent of skill-root scope and project
discovery. Each canonical name has a required `path`, optional `aliases` and
`description`, and optional `swimlane: work|personal`. Config names and aliases
follow the query identifier rules. Use aliases such as `app` for
`example-app`, `api` for `example-api`, or `worker` for `background-worker`.
Paths support `~/`, absolute paths, or paths relative to the config directory;
they may name module directories. The command expands paths without checking
their existence. Verify the target and read its local instructions before
working there.

The default map is empty. If `repos` is absent, the tip returns configuration
guidance; add the map to the existing version 1 config. Run `admin init` first
if config is missing.

## Configuration example

Add this to the existing global `config.yaml`:

```yaml
repos:
  example-app:
    path: ~/code/example-app
    aliases: [app]
    description: Example application
    swimlane: work
  background-worker:
    path: ~/code/tools/worker
    aliases: [worker]
    swimlane: personal
```

JSON retains the tip envelope (`name`, `description`, `harness`, `content`)
and adds `repos`, keyed by canonical name with expanded paths. `--human` lists
entries in name order. A reference identifies a configured project, not a file:
write “`README.md` in `repo://app`.”
