# Changelog

## 0.2.0

- `--human` output now adapts to terminal width: wide results (like
  `issues`/`errors`, with long title/culprit/permalink columns) render as
  wrapped record blocks — one per row, no truncation, no horizontal
  scrolling — while narrower results (like `projects`, `releases`,
  `spikes`) still render as aligned tables. The stdout JSON contract is
  unchanged.

## 0.1.0 - Initial release

- Agent-first Sentry explorer CLI (`sentryexplorer`, alias `srx`), modeled on
  the sibling `newrelicexplorer` (`nrx`).
- Config: `~/.config/sentryexplorer/config.yaml` with `${ENV}` resolution,
  curated project inventory, `max_limit` pagination cap; interim `.env`
  loading from the current directory.
- Commands: `init`, `check`, `projects` (+ `list`), `issues`, `issue`,
  `errors`, `spikes`, `releases`, `query`, `schema`.
- Strict stdout-JSON / stderr-human contract with `--human` table rendering
  and 0/1/2 exit-code semantics.
- Sentry API client with Link-header cursor pagination and 401/403 scope
  hints.
- Hermetic test suite (httptest fakes, no real network) covering config
  resolution, `.env` loading, project fuzzy matching, issues happy path,
  exit-code mapping, pagination, and human table rendering.
