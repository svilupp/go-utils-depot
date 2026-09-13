---
name: using-lightdashctl-cli
description: Use lightdashctl (ldc) to discover and query Lightdash content and plan or apply content-as-code bundles. Covers configuration, JSON output, exact refs, safe writes, pagination, and recovery. Triggers: lightdashctl, ldc, Lightdash, chart, dashboard, metric query.
---

# Use Lightdash with ldc

Use `lightdashctl` in scripts and agent commands. `ldc` is an optional shell
alias.

Choose the shortest path that answers the question. Use a known UUID, slug, or
`@alias` directly. Search live content when the ref is unknown. Use help,
schema, and docs to resolve specific uncertainty.

| Task | Start with |
| --- | --- |
| Orient to the contract | `lightdashctl --help`, `lightdashctl --version`, `lightdashctl schema commands` |
| Check auth and capabilities | `lightdashctl config doctor` |
| Find a dashboard or chart | `lightdashctl discover search latency --kind dashboard` |
| Inspect one resource | `lightdashctl discover get dashboard <REF>` |
| Find fields in an explore | `lightdashctl discover search latency --kind field --explore <EXPLORE_REF>` |
| Read metric notes | `lightdashctl docs search latency --kind metric` then `lightdashctl docs read <REF>` |
| Copy a local template | `lightdashctl docs copy <TEMPLATE> --as demo --space <SPACE_REF> -o ./demo` |
| Compile a query | `lightdashctl analyze query ./query.yml --compile-only` |
| Preview a publish | `lightdashctl build plan ./bundle` |
| Publish a bundle | `lightdashctl build apply ./bundle` |

## Output contract

```bash
lightdashctl discover search latency --kind dashboard 2>/dev/null | jq .
```

- stdout is JSON with `contract_version: 1` by default.
- `--human` changes display formatting and must not be parsed.
- stderr contains `error: [CODE] ...` and `hint:` lines.
- `--error-json` emits one structured error object.
- `--output` or `-o` writes an artifact and prints a `{path,bytes,kind}` receipt.
- Exit `0` means success, `1` means runtime or permission failure, and `2`
  means invalid usage, configuration, or input.
- Empty searches are successful. Content searches and query-result pages provide
  `meta.next_cursor` when another page exists. Other searches return bounded
  results without continuation cursors.

The CLI does not load `.env` files. Configuration precedence is
`--config`, `LDC_CONFIG`, `$XDG_CONFIG_HOME/lightdashctl/config.yaml`, then
`~/.config/lightdashctl/config.yaml`.

## Refs and writes

Refs are exact UUIDs, slugs, configured `@aliases`, or URLs from the same
Lightdash instance. Resource titles do not identify a write target.

`build apply` is the only remote content mutation. `build plan` validates the
full bundle against live resources and previews field changes without
publishing or executing queries. `build delete` writes a local deletion bundle.
Export forks remove `ownerEmail`, `access`, `verified`, and `verification` from
exported resources. Use a verified sandbox for authoring.

Native export requires the `view:ContentAsCode` permission. A viewer token can
still discover and inspect content, but export and apply may return
`FORBIDDEN`. Do not retry a write when the token lacks that permission.

## Query workflow

Compile first when the query shape is new. Run a saved chart or dashboard only
when its ref is known. Async execution returns a handle; poll it with
`lightdashctl analyze status HANDLE` and fetch completed pages with
`lightdashctl analyze results HANDLE`.

For a local query file:

```bash
lightdashctl analyze query ./query.yml --compile-only
lightdashctl analyze query ./query.yml --output query.json
```

`analyze results HANDLE --format csv --output results.csv` writes all result
pages, up to 5,000 rows and 100 pages. Exceeding either limit returns an error.
Do not resubmit a query to poll it.

## Recovery

| Failure | Next step |
| --- | --- |
| Missing args or unknown flag | Read the hinted command help |
| `CONFIG_INVALID` | Run `lightdashctl config init`, then update the config path or values |
| `AUTH` or empty API key | Export `LIGHTDASH_API_KEY` or set a PAT in the 0600 config |
| `FORBIDDEN` on export or apply | Use a token with `view:ContentAsCode` in a sandbox |
| Empty discovery search | Use a shorter token, then fetch by UUID |
| `AMBIGUOUS` | Pass the exact UUID |
| Query timeout | Run `lightdashctl analyze status HANDLE` |
