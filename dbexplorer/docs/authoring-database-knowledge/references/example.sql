/* ---
summary: Purpose of this example
relations: [schema.table]
parameters:
  - {position: 1, type: text}
test_values: ["example"]
status: draft
--- */

SELECT 1 WHERE $1 IS NOT NULL
