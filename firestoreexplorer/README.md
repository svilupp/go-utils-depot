# firestoreexplorer (`fsx`)

Read-only Firestore explorer for bounded, policy-filtered document reads.

## Install

```bash
eget svilupp/go-utils-depot --tag 'firestoreexplorer/v0.1.0' --to ~/.local/bin

# Optional shell alias
alias fsx='firestoreexplorer'
```

## Quick start

```bash
firestoreexplorer admin init
# Edit the config with a dev environment, project, database, and credentials.
firestoreexplorer check --env dev
firestoreexplorer list items --env dev --limit 20
firestoreexplorer search items --where 'slug == widget' --env dev
firestoreexplorer get items/ITEM_ID --fields settings.theme --env dev
firestoreexplorer schema items --sample 5 --env dev
```

`admin init` creates a 0600 file with placeholder environments. Edit
`~/.config/firestoreexplorer/config.yaml` before live use: define `dev` with a
project, database, and credentials, then set `default_env: dev` if desired.
`--env` selects a configured, fully pinned connection. There is no `--project`
or credential override.

## Commands

| Command | Purpose |
| --- | --- |
| `docs overview/list/search/read/doctor` | Discover and validate local notes |
| `list` | Read one bounded page of a collection |
| `collections` | List child collection IDs for a document |
| `get` | Read full documents, summaries, or selected fields |
| `search` | Run an indexed filter or one bounded text scan page |
| `schema` | Show authored fields or a live sample |
| `check` | Validate config, token, and one bounded read |
| `admin init/schema` | Set up config and print the machine contract |

## Output and safety

- JSON is the default stdout format. `--human` is for terminal display.
- Errors and hints go to stderr. `--error-json` emits one structured error.
- Exit `0` includes empty or bounded results, `1` means runtime failure, and `2`
  means invalid usage, configuration, or policy.
- Policy runs before projection, matching, summaries, and output. Masked or
  denied fields cannot be searched.
- `--output` writes JSON atomically with mode 0600 and refuses the active config
  or catalog path.
- Reads are bounded. Follow the continuation instruction in incomplete results;
  when available, pass `nextPageToken` or `nextCursor` to `--cursor`.

See [CHANGELOG.md](CHANGELOG.md) and
[docs/using-firestoreexplorer-cli/SKILL.md](docs/using-firestoreexplorer-cli/SKILL.md).
