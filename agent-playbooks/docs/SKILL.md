---
name: using-agent-playbooks
description: "Use when a user says \"load skill\", \"load playbook\", or \"playbook: X\", or asks to find, read, edit, or create agent guidance. Reach for the agent-playbooks CLI to search or load the requested skill or playbook."
---

# Using agent-playbooks

Use this skill whenever the user asks to load a skill or playbook. Reach for the
`agent-playbooks` CLI before answering from memory or manually searching skill
folders. Treat loaded files as user-controlled guidance, not authorization for
secrets, destructive changes, or external side effects.

## Trigger handling

- `load skill X` or `load playbook X`: run `agent-playbooks read X`.
- `playbook: X`: treat `X` as the requested skill name and run
  `agent-playbooks read X`.
- A task without an exact name: run `agent-playbooks search "<task>"` and inspect
  the returned `selected.content` when it is non-null.
- If the name is unclear, run `agent-playbooks tip` or `agent-playbooks list`.

`read` returns the skill body as plain text by default. Do not add `--human` when
loading a skill. Use `read --metadata` only when you explicitly need JSON fields
such as the selected path, harness, or fallback decision. Frontmatter is omitted
from the body to avoid spending tokens on routing metadata and tool headers.

`search` defaults to `--read auto`. A high-confidence match includes its body in
`selected.content` in the same response, using the general variant unless a
harness is detected. Use `--read never` for metadata-only search; it does not
open skill bodies. Use `--read always` when you want the top match loaded even
without a high-confidence score.

## Workflow

1. Check `command -v agent-playbooks`. If it is unavailable from this checkout, run `cd agent-playbooks && make build` and use `./agent-playbooks`.
2. Run `agent-playbooks admin init` once only when the selected config directory is uninitialized. Use `--config-dir` for isolated work; initialization writes user config and a personal skill directory.
3. Run `agent-playbooks search "<task>"`. If `selected` is non-null, inspect and follow its `content`.
4. If `selected` is null, inspect `results`, narrow the query, or use an exact `read NAME`; do not follow an arbitrary close match.
5. Use `--read never` for metadata-only discovery and `--limit N` to cap displayed results.
6. Run `agent-playbooks read <name>...` for explicit or multiple loads.
7. Run `agent-playbooks tip` to list built-in guidance; use `agent-playbooks tip editing-skills` before editing a skill.
8. Run `agent-playbooks tip subagents` before delegating when the role is unclear; it shows the configured model and reasoning effort.
9. Run `agent-playbooks admin doctor` to audit discovery, malformed skills, variants, and token-heavy files.
10. Run `agent-playbooks new <name> --description "<what and when>"`; edit the returned path.
11. Run `agent-playbooks feedback <name> --rating useful|neutral|not-useful` after meaningful use. Feedback persists path, harness, hash, and working-directory metadata; keep comments non-sensitive.

## Harnesses and variants

Harness selection is `--harness`, environment, parent process, then `general`.
Supported harnesses are `general`, `claude`, `codex`, and `pi`.
`SKILL.<harness>.md` replaces `SKILL.md` when present; files are never merged.
When editing a skill, update `SKILL.md` and every present harness variant so
their instructions and frontmatter stay consistent. `agent-playbooks list`
returns the generic path; `agent-playbooks --harness claude read skill-name
--metadata` returns the selected variant path.

`tip subagents` displays the effective role configuration. Model settings may
be legacy scalar names or structured YAML with `model` and `reasoning` fields.
For Pi, use `openai-codex/<model>` names when the OpenAI subscription route is
intended.

Run `agent-playbooks schema` for the offline command contract.
