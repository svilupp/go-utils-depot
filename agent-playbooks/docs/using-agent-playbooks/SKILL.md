---
name: using-agent-playbooks
description: "Use when a user mentions a playbook or skill to find or load, uses an address-style playbook or repository reference (such as repo://NAME), or asks for subagents and you need to choose a role or model. Provides playbook discovery and loading, repository lookup, and the configured subagent map."
---

# Using agent-playbooks

Use the relevant section below. Read linked references only when their details
are needed.

## Find and load playbooks

```bash
agent-playbooks read <name> [<name> ...]
agent-playbooks search "<task>"
agent-playbooks list --scope project
agent-playbooks list --scope global
```

Use `read` for named playbooks; prefer one batch read whenever multiple needed
names are known. Address-style references are optional shorthand: strip a prefix
such as `playbook://` and pass the bare playbook name to `read`. Use `search`
when you know the task instead.
Search auto-reads a confident scoring hit into `selected.content`; use that
body directly without another read. If `selected` is null, inspect candidates.
A failed read suggests commands for nearby matches.

`list` and `index` are aliases. Scope defaults to `all`; `project` limits the
catalog to this project, while `global` selects personal/global guidance.
Use the same scope with `search` or `read`. To target another repository, use
`--project PATH --scope project`; `--project` alone still includes global roots.

Reads return Markdown with a `PATH` for resolving relative references.
For output formats, large reads, matching rules, or harness variants, read
[retrieval details](references/playbooks.md).

## Resolve repository references

For a repository reference, strip `repo://` and run
`agent-playbooks tip repos NAME` with the bare name or alias; omit it for the
whole map. Names and aliases match exactly first, then by substring.
Clarify ambiguous matches. Verify the directory and read its local instructions.
See [repository details](references/repositories.md) for configuration and errors.

## Choose subagents

When asked to use subagents and you need a role or model choice, run
`agent-playbooks tip subagents`. It maps task roles to configured models and
reasoning settings for the current harness. Follow explicit user choices.
See [subagent details](references/subagents.md) when choosing or configuring roles.

## When needed

- Missing skills or initial setup: [configuration and discovery](references/setup.md).
- Rate consumed guidance with `feedback --invocation ID --rating useful`;
  see [feedback details](references/feedback.md) for other ratings and history.
