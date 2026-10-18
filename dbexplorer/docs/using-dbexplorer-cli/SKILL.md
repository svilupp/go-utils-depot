---
name: using-dbexplorer-cli
description: Use dbexplorer (dbx) to find database meanings and run bounded, parameterized, read-only SQL against PostgreSQL and BigQuery. Covers catalog search, schema inspection, authentication profiles, evidence reuse, and recovery.
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
| Match relations | `dbexplorer inspect catalog --endpoint primary --match 'public.task*'` |

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
load `.env` files. Service-account credentials belong in private config; external
token profiles contain only a variable name. Tunnels and token provisioning stay external.

## Authentication and evidence reuse

`--endpoint` selects the database target and Google identity together. Named
`auth_profiles` are selected by `connection.auth: {profile: NAME}` on a source
or endpoint. Endpoint auth replaces inherited auth atomically. Existing ADC and
inline service-account config remain supported; permission failures do not retry
with another identity.

For externally supplied bearer tokens, use `mode: access_token` and
`token_env: DBX_GOOGLE_TOKEN` in a named profile or inline auth. Only the selected
live target reads the variable. Missing or malformed values fail with `AUTH`;
there is no ADC fallback or token refresh. Have the trusted launcher provision
or renew the token without printing it. `inspect sources` remains credential-free.

BigQuery evidence and job receipts are scoped by credentials, target, profile,
and policy. Change `access.revision` or clear caches after IAM revocation; a cache
hit does not recheck remote IAM. Old unscoped job receipts cannot resume.
`access_token` and ADC providers without stable credential material bypass
persistent caches and cannot resume jobs across commands. Rerun the original
bounded query when a receipt cannot be resumed.

The tool's README includes complete authentication configuration examples.

## Recovery

| Signal | Next step |
| --- | --- |
| Empty docs search or list | Broaden the search or inspect the source overview |
| Unknown relation or column | Run `inspect describe` or `inspect catalog` |
| Empty catalog | Check `--match` glob syntax, endpoint, filters, and metadata freshness |
| Parameter or placeholder error | Read `dbexplorer query --help` and keep the dialect consistent |
| Connection or auth failure | Run `dbexplorer inspect check --endpoint ENDPOINT`; renew injected tokens through the launcher |
| Query cap or timeout | Explain the bound, narrow the query, or adjust config |
| Recipe ref passed to `--file` | Read it first, then pass local SQL to `--file` |

Use `dbexplorer docs doctor --source main` after editing catalog notes. Use
`dbexplorer admin` for setup and local maintenance.
