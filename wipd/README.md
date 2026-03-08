# wipd

Per-folder task tracker for AI agents. Prevents collisions when multiple agents or processes work in the same directory.

## When to use it

You have multiple AI agents (or agent + human) working in the same codebase. wipd gives each agent a way to claim tasks, signal completion, and send messages — all backed by a single JSONL file with file-level locking.

- `wipd take TASK-1` — claim a task before working on it
- `wipd done TASK-1 -y` — mark it complete
- `wipd mail send worker-2 "need the API key"` — message another agent
- `wipd inbox` — check for new messages

## Install

```bash
eget svilupp/go-utils-depot --tag 'wipd/*' --to ~/.local/bin
```

## Quick start

```bash
# See what's in progress
wipd status

# Claim a task
wipd take TASK-1 --as agent1 -m "fixing auth bug"

# Mark it done
wipd done TASK-1 -y

# If blocked, drop with reason
wipd drop TASK-1 -y -m "needs API key"
```

Set `WIPD_WORKER` to auto-detect your worker ID (also reads `CLOOP_WORKER_ID`).

## Commands

| Command | What it does |
|---------|-------------|
| `status` | Show active tasks and their owners |
| `take <id>` | Claim a task (errors if already taken) |
| `done <id>` | Mark a task complete (requires `-y`) |
| `drop <id>` | Drop a task with reason (requires `-y -m`) |
| `list` | List all tasks (including completed) |
| `clear` | Remove completed/dropped tasks (requires `-y`) |
| `mail send <to> <msg>` | Send a message to another worker |
| `mail read [worker]` | Read messages for a worker |
| `mail list` | List all messages |
| `inbox [worker]` | Check for unread messages |

## How it works

Tasks and messages are stored in a single JSONL file (`logs/wipd/tasks.jsonl`) in the current directory. Concurrent access is safe — wipd uses both in-process mutex and file-level locking.

`take` is atomic: if another agent already holds the task, you get an error immediately. No need to check `status` first.

## Confirmation flags

Destructive commands require explicit confirmation:

| Command | Required flags |
|---------|---------------|
| `done` | `-y` |
| `drop` | `-y` and `-m "reason"` |
| `clear` (multiple) | `-y` |

Without `-y`, wipd shows what would happen and exits.

## Docs

- [Full usage guide](docs/SKILL.md) — all commands, workflows, agent integration patterns
