---
name: authoring-database-knowledge
description: Onboard or improve a PostgreSQL or BigQuery knowledge root for dbexplorer. Not loaded during normal query work.
---

# Authoring dbexplorer knowledge

Use this when adding a source or repairing docs. Write files in the configured knowledge root. Knowledge directories are not skills.

## Workflow

1. Inventory permitted schemas/relations (`dbexplorer inspect catalog --endpoint E`). Choose questions the source should answer.
2. Read models/migrations/dbt and ask owners where evidence is missing. Mark `unknown` instead of inferring meaning from names.
3. Establish grain and identities before joins. Check cardinality with bounded `sample`/`query`.
4. Write source and domain maps, then table/join/metric docs and parameterized examples. Reuse refs; do not copy definitions.
5. Add evidence, `status`, `reviewed_at`, and optional `endpoints`. A passing SQL check never promotes a doc to reviewed.
6. `dbexplorer docs doctor --source S`, then `dbexplorer docs doctor --source S --endpoint E`, then `--queries` for examples with `test_values`. Doctor must be `ok`: no damaged files (`invalid-header`, `too-deep`, `not-regular`, and similar), no `broken-link`/`invalid-link`/`self-link`. `related:` entries are refs (`tables/x.md` or `other_source:path.md`), never URLs. Keep directories at most 8 deep and never name a directory `*.md`.
7. Give a fresh agent a held-out question with only `using-dbexplorer-cli` and `dbexplorer`. Fix the docs from the failure.

## Required meaning

| Kind | Must state |
| --- | --- |
| Source | questions, coverage, env differences, identity vocabulary, source-of-truth |
| Domain | table map, reading order, lifecycle, joins/metrics, common mistakes |
| Table | grain, identifier, tenant, lifecycle, timestamps, units, null/status |
| Join | keys, direction, cardinality, predicates, fan-out, evidence |
| Metric | population, expression, exclusions, grain, time, unit, SQL |
| Warehouse table | lineage, refresh, event vs ingest time, late arrivals, reconciliation limits |
| Example | purpose, engine, relations, typed parameters, test values, invariant |

Keep table/metric docs to about 20-60 lines. `unknown` plus a reason is valid. Templates: `references/source.md`, `domain.md`, `table.md`, `join.md`, `metric.md`, `example.sql`.
