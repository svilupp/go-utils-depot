---
name: using-dbexplorer-cli
description: Use dbexplorer (dbx) to find database meanings and run bounded, parameterized, read-only SQL against PostgreSQL and BigQuery. Covers catalog search, schema inspection, output contracts, and recovery.
---

# Answer database questions with dbx

Use `dbexplorer` in scripts and agent commands. `dbx` is an optional shell
alias.

Choose the shortest path that answers the question. Run known SQL directly. For
unfamiliar data, search the configured notes and read the relevant recipe before
querying. Use schema inspection only to resolve a specific uncertainty.

| Task | Start with |
| --- | --- |
| Run known SQL | `dbexplorer query 'SELECT id, state FROM tasks LIMIT 5' --endpoint primary --human` |
| Find a table or join | `dbexplorer docs search 'task totals' --source main --limit 3` |
| Read a recipe | `dbexplorer docs read main:tasks/examples/recent-tasks.sql --human` |
| Learn an unfamiliar source | `dbexplorer docs overview --source analytics --human` |
| Check columns or joins | `dbexplorer inspect describe public.tasks --endpoint primary --human` |
| Find an endpoint | `dbexplorer inspect sources` |

`docs read` takes a `source:path` ref. Live commands take `--endpoint`. Notes
are configured outside the depot and may use any source names.

## Parameterized SQL

Keep user values out of the SQL string. Use a quoted heredoc when SQL contains
quotes, placeholders, or BigQuery backticks.

```bash
dbexplorer query --endpoint primary --human --file - \
  --params '[{"position":1,"type":"text","value":"open"}]' <<'SQL'
SELECT id, state
FROM tasks
WHERE state = $1::text
ORDER BY id
LIMIT 20
SQL
```

BigQuery named parameters use the same separation:

```bash
dbexplorer query --endpoint analytics --file - \
  --params '[{"name":"days","type":"INT64","value":7}]' <<'SQL'
SELECT project_id, COUNT(*) AS task_count
FROM `project.dataset.tasks`
WHERE created_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL @days DAY)
GROUP BY project_id
ORDER BY task_count DESC
LIMIT 50
SQL
```

Use `query --check` for a cost estimate. If the query has no outer `LIMIT`, the
CLI injects the configured cap. `--limit` overrides the row cap and `--timeout`
overrides the deadline. Config supplies defaults, ceilings, and other limits.

## Output contract

- stdout is JSON by default. `--human` prints display-only notes or TSV rows.
- stderr carries `error: [CODE] ...` and `hint:` lines.
- `--error-json` emits one structured error object.
- Exit `0` includes empty or bounded results, `1` is a runtime failure, and `2`
  is a usage or configuration error.
- Large integers and decimals are JSON strings so precision is preserved.
- A result with `input_complete: null` may have more rows beyond the cap.

Keep SQL, parameters, endpoint, and source selection explicit. The CLI does not
load `.env` files. Credentials belong in the private config; tunnels and cloud
authentication are managed outside the CLI.

## Recovery

| Signal | Next step |
| --- | --- |
| Empty docs search or list | Broaden the search or inspect the source overview |
| Unknown relation or column | Run `inspect describe` or `inspect catalog` |
| Empty catalog | Check glob syntax, endpoint, filters, and metadata freshness |
| Parameter or placeholder error | Read `dbexplorer query --help` and keep the dialect consistent |
| Connection or auth failure | Run `dbexplorer inspect check --endpoint ENDPOINT` |
| Query cap or timeout | Explain the bound, narrow the query, or adjust config |
| Recipe ref passed to `--file` | Read it first, then pass local SQL to `--file` |

Use `dbexplorer docs doctor --source main` after editing catalog notes. Use
`dbexplorer admin` for setup and local maintenance.
