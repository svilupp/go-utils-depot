# dbexplorer (`dbx`)

CLI for finding database definitions and running parameterized, read-only SQL
against PostgreSQL and BigQuery.

## Install

```bash
eget svilupp/go-utils-depot --tag 'dbexplorer/v0.1.0' --to ~/.local/bin

# Optional shell alias
alias dbx='dbexplorer'
```

## Quick start

```bash
dbexplorer admin init
# Edit the config with your endpoints, credentials, and knowledge directory.
# These examples assume an endpoint named primary and a source named main.
dbexplorer inspect sources
dbexplorer docs search 'tasks by project' --source main --limit 3
dbexplorer docs read main:tasks/examples/recent-tasks.sql --human
dbexplorer query --endpoint primary --human --file - \
  --params '[{"position":1,"type":"text","value":"open"}]' <<'SQL'
SELECT id, state
FROM tasks
WHERE state = $1::text
ORDER BY id
LIMIT 20
SQL
```

The docs catalog is configured by the user. `docs read` returns recipe text; it
does not create a local SQL file. Copy SQL into a file or use a quoted heredoc
with `query --file`.

## Commands

| Command | Purpose |
| --- | --- |
| `docs overview/search/list/read/doctor` | Discover and validate local database notes |
| `inspect sources` | List configured endpoints and documentation sources |
| `inspect check/describe/catalog/sample` | Check access or resolve schema questions |
| `query` | Run bounded, parameterized, read-only SQL |
| `admin` | Set up configuration and maintain local state |

Use `query --check` for a cost estimate before expensive SQL. Limits, timeouts,
cache settings, and activity logging are configured in the private config.
Tunnels and cloud authentication stay outside the CLI.

## Output and safety

- JSON is the default stdout format. `--human` prints readable notes or TSV.
- Errors and hints go to stderr. `--error-json` emits one structured error.
- Exit `0` means success, `1` means runtime failure, and `2` means invalid
  usage or configuration.
- SQL is read-only, logged, and capped when it has no outer `LIMIT`.
- Parameters stay separate from SQL. Use placeholders and `--params` for user
  values.

See [CHANGELOG.md](CHANGELOG.md) and
[docs/using-dbexplorer-cli/SKILL.md](docs/using-dbexplorer-cli/SKILL.md).

For catalog maintainers, see
[docs/authoring-dbexplorer-knowledge/SKILL.md](docs/authoring-dbexplorer-knowledge/SKILL.md).
