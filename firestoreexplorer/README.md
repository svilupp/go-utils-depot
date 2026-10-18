# firestoreexplorer (`fsx`)

Read-only Firestore explorer for bounded, policy-filtered document reads.

Next release: `firestoreexplorer/v0.2.0`.

## Install

```bash
eget svilupp/go-utils-depot --tag 'firestoreexplorer/' --to ~/.local/bin

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

## Authentication profiles

Each `environments` entry pins a project and database. Select that access point
with `--env`, or retain `default_env`. A named profile lets several databases
use the same service account without copying its credentials.

```yaml
default_env: primary
auth_profiles:
  viewer:
    mode: service_account
    credentials:
      client_email: viewer@example.iam.gserviceaccount.com
      private_key: REPLACE_WITH_PEM
  automation:
    mode: service_account
    credentials:
      client_email: automation@example.iam.gserviceaccount.com
      private_key: REPLACE_WITH_PEM
environments:
  primary:
    project_id: example-project
    database_id: example-db
    auth: {profile: viewer}
  reporting:
    project_id: example-project
    database_id: reporting-db
    auth: {profile: automation}
  archive:
    project_id: example-project
    database_id: archive-db
    auth: {profile: automation}
collections:
  - {name: items, match: 'items/*'}
```

Existing `auth.service_account` configurations remain valid. An environment
must use either `auth.profile` or `auth.service_account`. Empty, undefined,
duplicate, or mixed profile references fail configuration validation.
Profiles support `mode: service_account` or
[`mode: access_token`](#external-bearer-tokens). PEM parsing and token
acquisition use the selected environment only. Discovery does not expose credentials.

Profile selection does not change collection deny rules, field masks, or IAM.
A permission failure never retries with another profile. Cursor tokens remain
opaque Firestore page tokens. Resume with the same `--env` and request options.
Each resumed request authenticates with the selected environment's current
credentials and applies its policy. No result cache exists.

These example names do not provision credentials or grant database access.
For local service-account mode, keep credentials in the private configuration
file with mode `0600`. Hosted token configs contain only variable names.

## External bearer tokens

Use a named profile when a trusted launcher supplies a Google OAuth access token
or a bearer placeholder. Config contains the variable name only:

```yaml
auth_profiles:
  hosted:
    mode: access_token
    token_env: FSX_GOOGLE_TOKEN
default_env: hosted
environments:
  hosted:
    project_id: example-project
    database_id: "(default)"
    auth: {profile: hosted}
collections:
  - {name: items, match: 'items/*'}
```

Run `firestoreexplorer --config hosted.yaml check --env hosted` after the launcher has
provisioned the variable. Replace the example collection rule with your collection
policy before deployment.

Select it with `environments.NAME.auth: {profile: hosted}`. Keep the environment's
`project_id`, `database_id`, collection policy, and limits.

The variable is read only for the selected live target. Empty or malformed values
fail with `AUTH`; there is no fallback to local credentials. Tokens are sent
unchanged in `Authorization: Bearer ...`. This mode cannot refresh tokens.

The launcher must supply and renew tokens outside the CLI. Keep each run within
the token lifetime; on expiry, obtain a fresh token from the launcher. Enforce
read permissions through Google IAM and configure the required API destination
in any network allowlist. Local offline tests cover bearer headers and missing
tokens; live hosted substitution and expiry still need acceptance testing.
