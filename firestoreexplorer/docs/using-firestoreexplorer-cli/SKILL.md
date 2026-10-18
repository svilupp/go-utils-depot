---
name: using-firestoreexplorer-cli
description: Use firestoreexplorer (fsx) for bounded, policy-filtered Firestore document reads and collection search. Covers authentication profiles, result shapes, continuation, and recovery.
---

# Answer Firestore questions with fsx

Use `firestoreexplorer` in scripts and agent commands. `fsx` is an optional
shell alias.

Choose the shortest path that answers the question. Read a known document path
directly. Search the configured notes when the collection or field is unknown.
Use help, schema samples, and checks to resolve specific uncertainty.

| Task | Start with |
| --- | --- |
| Find a field or collection note | `firestoreexplorer docs search 'item status'` |
| Read a catalog note | `firestoreexplorer docs search 'item status'` then `firestoreexplorer docs read <REF>` |
| Search one visible field | `firestoreexplorer search items --contains TEXT --field displayName --env dev` |
| Use an indexed filter | `firestoreexplorer search items --where 'slug == VALUE' --env dev` |
| Read a known document | `firestoreexplorer get items/ITEM_ID --summary --env dev` |
| Project nested fields | `firestoreexplorer get items/ITEM_ID --fields settings.theme --env dev` |
| List child collections | `firestoreexplorer collections items/ITEM_ID --env dev` |
| Compare notes with data | `firestoreexplorer schema items --sample 5 --env dev` |

`--env` selects a fully pinned connection. Each environment pins a project,
database, and credentials. Do not assume a path exists in another environment.

## Result shapes

- `list`, `search`, and `get --summary` return compact rows with paths, IDs,
  and available summary fields.
- `get PATH` and `search ... --full` return policy-filtered data.
- `get PATH --fields a.b,c` projects selected paths.
- `get PATH PATH...` returns `documents[]` and `missing[]` for mixed batches.
- An incomplete page returns a `next` instruction. Follow it; when it names a
  `nextPageToken` or `nextCursor`, pass that token to `--cursor`.

`--where` is indexed and has no cursor. Narrow it with another clause or raise
`--limit`. `--contains` and `list` use `--cursor` when a token is returned. A
mid-page limit cannot resume; rerun with a higher limit.

An exhausted empty page is a successful result. A failed page is never changed
into empty data. An empty result may include hints about other configured
environments, fields, or schema samples. Hints are advice; fsx never switches
environment on its own.

## Output contract and policy

- stdout is JSON with `contract_version: 1` by default.
- `--human` changes display formatting and must not be parsed.
- stderr contains `error: [CODE] ...` and `hint:` lines.
- `--error-json` emits one structured error object; stdout is empty on error.
- Exit `0` includes empty or bounded results, `1` is a runtime failure, and `2`
  is a usage, configuration, or policy error.

Policy runs before projection, summaries, matching, observations, and output.
Masked or denied fields cannot be searched. Visible IDs may still be sensitive.
Keep the configured catalog and credentials out of command output.

## Authentication profiles

`--env` selects the pinned project, database, and identity. Reuse a named
`auth_profiles` entry through `environments.NAME.auth: {profile: NAME}`. Profiles
support `mode: service_account` with `credentials`, or `mode: access_token` with
`token_env: FSX_GOOGLE_TOKEN`. Existing inline `auth.service_account` still works;
do not combine it with a profile reference.

Only the selected live environment reads its token variable or parses its PEM.
Missing or malformed tokens fail with `AUTH`; there is no credential fallback
or token refresh. Ask the trusted launcher to provision or renew the token
without printing it. `check` reports the selected authentication mode.

Profile selection preserves collection policy and IAM. Permission failures do
not switch identities. Resume cursors with the same environment and request
options; each request uses current credentials and policy. There is no result cache.

The tool's README includes complete authentication configuration examples.

## Recovery

| Signal | Next step |
| --- | --- |
| `CATALOG_MISSING` | Set `catalog_dir` for docs commands; live reads still work |
| `NOT_FOUND` | Confirm the path and `--env`, then search by an indexed field |
| `INDEX_MISSING` | Narrow the `--where` filter; fsx does not scan silently |
| `AUTH`, `CONNECTION`, or `TIMEOUT` | Run `firestoreexplorer check --env NAME`; renew injected tokens through the launcher |
| Empty projection | Run `firestoreexplorer schema COLLECTION --sample N` to inspect real fields |
| More pages remain | Follow `next`; pass its `nextPageToken` or `nextCursor` to `--cursor` when present |

Use `firestoreexplorer docs doctor` after editing notes. Use
`firestoreexplorer admin init` for setup and `firestoreexplorer admin schema`
for the machine contract.
