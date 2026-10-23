# agent-playbooks

Discover, search, and read agent skills and commands. Resolve configured repository references and harness-specific subagent settings.

## Install

```sh
eget svilupp/go-utils-depot --tag 'agent-playbooks/' --to ~/.local/bin
agent-playbooks admin init
agent-playbooks admin doctor --human
```

## Use

```sh
agent-playbooks search "review a Go change"
agent-playbooks read NAME
agent-playbooks index --scope project
agent-playbooks index --scope global
agent-playbooks tip repos NAME
agent-playbooks tip subagents
```

`--project PATH` selects a repository; add `--scope project` to exclude global guidance. Project skill-folder discovery is enabled by default. An isolated config requires `--project PATH` or `--scope project` to enable project discovery.

Reads emit Markdown by default. Other commands return JSON; use `--human` for terminal output. `admin sync-router` previews installation of the loader skill and its references; add `--apply` to write them.

See the [usage skill](docs/using-agent-playbooks/SKILL.md), its linked references, and [changelog](CHANGELOG.md). Use `agent-playbooks COMMAND --help` for command options.
