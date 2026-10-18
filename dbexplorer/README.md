# dbexplorer (`dbx`)

CLI for finding database definitions and running parameterized, read-only SQL
against PostgreSQL and BigQuery.

Next release: `dbexplorer/v0.3.0`.

## Install

```bash
eget svilupp/go-utils-depot --tag 'dbexplorer/' --to ~/.local/bin

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
Tunnels and credential provisioning stay outside the CLI.
Use `inspect catalog --match 'schema.pattern*'` to narrow relation discovery.

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
[docs/authoring-database-knowledge/SKILL.md](docs/authoring-database-knowledge/SKILL.md).

## Authentication profiles

An endpoint is the configured access point for a database asset. `--endpoint`
selects its target and identity together. Sources remain knowledge families.
Reuse Google identities with top-level `auth_profiles` and select one through
`connection.auth.profile` on a source or endpoint:

```yaml
version: 1
auth_profiles:
  viewer:
    mode: service_account
    credentials: {type: service_account, client_email: VIEWER_EMAIL, private_key: VIEWER_KEY}
  automation:
    mode: service_account
    credentials: {type: service_account, client_email: AUTOMATION_EMAIL, private_key: AUTOMATION_KEY}
sources:
  warehouse:
    engine: bigquery
    connection:
      project: PROJECT
      default_dataset: ANALYTICS_DATASET
      auth: {profile: viewer}
    access: {enabled: true, query: true, catalog: true}
    endpoints:
      analytics: {description: Analytics through the viewer}
      audit:
        connection:
          default_dataset: AUDIT_DATASET
          auth: {profile: automation}
```

Use complete service-account JSON credentials for real access. These placeholders
do not grant permissions. Existing inline `auth` and ADC configurations still work.
Endpoint auth replaces inherited auth atomically. A profile reference cannot mix
with inline mode or credentials. Unknown profiles and endpoints fail locally.
`inspect sources` reports selected profile names without credentials. There is no
SQL-based identity routing or retry through another profile after permission denial.

Validation, estimates, cached samples, catalog and describe entries, and job
receipts are partitioned by credential identity and rotation, configured target,
profile, and access policy. Changing `access.revision` invalidates earlier evidence
and receipts. Old receipts without this security scope cannot resume; submit a new
query. Existing query execution is still governed by current configured access.

JSON-backed ADC service-account and authorized-user credentials retain cache and
resume support. ADC providers without stable credential material, including metadata
and external-account providers, can query but bypass persistent caches and cannot
resume local receipts. A cache hit does not recheck remote IAM. After a remote
permission revocation, change `access.revision`, disable the endpoint, or clear
cached data as appropriate; otherwise cached data remains readable until its TTL.

## External bearer tokens

Use a named profile when a trusted launcher supplies a Google OAuth access token
or a bearer placeholder. Config contains the variable name only:

```yaml
auth_profiles:
  hosted:
    mode: access_token
    token_env: DBX_GOOGLE_TOKEN
version: 1
sources:
  warehouse:
    engine: bigquery
    connection:
      project: example-project
      default_dataset: analytics
      location: EU
      auth: {profile: hosted}
    access: {enabled: true, query: true, catalog: true}
    endpoints:
      hosted: {}
```

Run `dbexplorer --config hosted.yaml inspect check --endpoint hosted` after the launcher
has provisioned the variable.

Select it with `sources.NAME.connection.auth: {profile: hosted}` or an endpoint's
`connection.auth`. Inline `{mode: access_token, token_env: DBX_GOOGLE_TOKEN}` also works.

The variable is read only for the selected live target. Empty or malformed values
fail with `AUTH`; there is no fallback to local credentials. Tokens are sent
unchanged in `Authorization: Bearer ...`. This mode cannot refresh tokens.

Persistent BigQuery caches, validation reuse, dry-run reuse, and job resume
are disabled for `access_token` mode because an opaque token or placeholder
does not identify the principal. PostgreSQL authentication is unchanged.

The launcher must supply and renew tokens outside the CLI. Keep each run within
the token lifetime; on expiry, obtain a fresh token from the launcher. Enforce
read permissions through Google IAM and configure the required API destination
in any network allowlist. Local offline tests cover bearer headers and missing
tokens; live hosted substitution and expiry still need acceptance testing.
