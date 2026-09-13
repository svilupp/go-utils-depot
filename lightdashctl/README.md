# lightdashctl (`ldc`)

CLI for discovering and querying Lightdash content and managing content-as-code
bundles.

## Install

```bash
eget svilupp/go-utils-depot --tag 'lightdashctl/v0.1.0' --to ~/.local/bin

# Optional shell alias
alias ldc='lightdashctl'
```

## Quick start

```bash
lightdashctl config init
# Edit the generated config with your instance URL, project, API key, and catalog path.
export LIGHTDASH_API_KEY=...
lightdashctl config doctor
lightdashctl discover search latency --kind dashboard
lightdashctl discover get dashboard <REF>
lightdashctl analyze query ./query.yml --compile-only
lightdashctl build plan ./bundle
lightdashctl build apply ./bundle
```

`config init` writes `~/.config/lightdashctl/config.yaml`. Use
`--config` or `LDC_CONFIG` to select another file. The CLI does not load
`.env` files. Replace the generated example profile, aliases, and catalog path
before using live content or local docs.

## Commands

| Command | Purpose |
| --- | --- |
| `discover search/get/values` | Find content and inspect resources or field values |
| `docs search/read/copy` | Search and read the configured local catalog; copy templates |
| `analyze query/chart/dashboard/status/results/cancel` | Compile, run, and recover metric queries |
| `build export/plan/apply/delete` | Export, validate, publish, or delete a bundle |
| `maintain check` | Check references or broken content |
| `config init/show/doctor` | Set up and validate configuration |
| `schema` | Print the machine-readable command contract |

## Output and safety

- JSON is the default stdout format. `--human` is for terminal display.
- Errors and hints go to stderr. `--error-json` emits one structured error.
- Exit `0` means success, `1` means runtime or permission failure, and `2`
  means invalid usage, configuration, or input.
- Refs are exact UUIDs, slugs, configured `@aliases`, or same-instance URLs.
  Writes never select a fuzzy match.
- `build apply` is the only remote content mutation. `build plan` validates the
  bundle against live resources without publishing or executing queries.
- `build delete` writes a local deletion bundle.
- Native export needs the Lightdash `view:ContentAsCode` permission. Use a
  verified sandbox before applying a bundle to shared content.

See [CHANGELOG.md](CHANGELOG.md) and
[docs/using-lightdashctl-cli/SKILL.md](docs/using-lightdashctl-cli/SKILL.md).
