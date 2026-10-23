# Subagent selection reference

Read this when choosing a role, interpreting model settings, or configuring the map.

```bash
agent-playbooks tip subagents
agent-playbooks tip subagents --human
```

The tip returns the active harness's configured roles, models, and optional
reasoning settings in `content`. Use this live map instead of hardcoded model
names. Explicit user choices take precedence. Looking up the map does not
itself request delegation.

| Role | Task |
|---|---|
| `cheap` | Simple lookup and bounded research |
| `implementer` | Implementation and routine verification |
| `planner` | Hard planning or debugging |
| `advisor` | Consequential decisions and independent review |

Use a native role when its settings match. Otherwise use supported explicit
model/reasoning controls. If the harness cannot honor a setting, explain the
limitation rather than claiming that model was used.

## Configuration

Global `config.yaml` stores settings under `models.<harness>.<role>`, with
`general`, `claude`, `codex`, and `pi` harnesses. Each role accepts a model name
string or a mapping with `model` and optional `reasoning`. Missing settings
fall back to built-in defaults for the selected harness. The `general` mapping
is used when the detected or explicitly selected harness is `general`.

The CLI detects the harness automatically; `--harness codex` (or another
supported harness) explicitly selects it. Inspect `agent-playbooks detect`
when selection is unexpected. Use the current harness's map for the task.
