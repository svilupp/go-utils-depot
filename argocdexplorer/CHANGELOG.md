# Changelog

## 0.1.0 - Initial release

- Read-only ArgoCD explorer CLI (`argocdexplorer`, alias `acx`).
- Commands: `init`, `check`, `get`, `status`, `triage`, `events`, `logs`,
  `history`, `resources`, `services` (aliases: `apps`, `list`), `query`,
  `schema`.
- `logs <app>`: bounded, one-shot container log fetch (`follow=false`
  always) with `--container`, `--pod`, `--tail`, `--since`, `--filter`, and
  `--previous`.
- API-key authentication via config (`~/.config/argocdexplorer/config.yaml`
  with `${ENV}` resolution); `init` prompts for API key and server.
- Curated service inventory with optional `nickname` field for fuzzy
  resolution (exact name → exact nickname → unique substring match);
  `acx services` (aliases: `apps`, `list`) lists the live fleet, curated by
  default with a `--all` flag to bypass curation; offline inventory also
  available via `acx schema` (under `curated_services` field).
- Strict stdout-JSON / stderr-human contract with `--human` table rendering
  and 0/1/2 exit-code semantics.
- Universal service-nickname resolution: `get`/`status`/`triage`/`events`/
  `logs`/`history`/`resources` all resolve a curated service + `--env` into
  the matching application name (never silently, always a stderr `resolved:`
  notice); `--since` durations accept an `Nd` (day) suffix everywhere.
