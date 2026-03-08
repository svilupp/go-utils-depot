---
name: using-wipd
description: Per-folder task tracker for AI agents with inter-agent messaging. Use when coordinating multiple agents in the same directory, claiming tasks to prevent collisions, or sending messages between workers.
---

# Using wipd

wipd prevents task collisions between multiple AI agents working in the same directory. Atomic task claiming, messaging, and status — backed by a single JSONL file with file-level locking.

## First Move

```bash
# Check what's in progress
wipd status

# Claim a task
wipd take TASK-1 --as agent1 -m "fixing auth bug"

# When done
wipd done TASK-1 -y
```

## Commands

### take — Claim a task

```bash
wipd take TASK-1 --as agent1 -m "fixing auth bug"
wipd take TASK-1                    # uses WIPD_WORKER for --as
```

Errors if already taken. No need to check status first.

### done — Complete a task

```bash
wipd done TASK-1 -y
```

### drop — Release a task with reason

```bash
wipd drop TASK-1 -y -m "blocked on API key"
```

### status — Active tasks

```bash
wipd status
```

### list — All tasks (including completed)

```bash
wipd list
```

### clear — Remove completed/dropped tasks

```bash
wipd clear -y
```

### mail — Inter-agent messaging

```bash
wipd mail send worker-2 "need help with auth"
wipd mail read                      # auto-detect worker from env
wipd mail read worker-1
wipd mail list --to worker-1
```

### inbox — Unread message check

```bash
wipd inbox                          # auto-detect worker
wipd inbox worker-1
```

## Worker Detection

Set `WIPD_WORKER` environment variable. Also reads `CLOOP_WORKER_ID` automatically.

Priority: `WIPD_WORKER` env > `CLOOP_WORKER_ID` env

## Storage

Single JSONL file: `logs/wipd/tasks.jsonl` in the current directory.

Concurrent access is safe (in-process mutex + file lock with 5s timeout).

## Agent Integration

```bash
# At start of work
export WIPD_WORKER="agent-1"
wipd inbox                          # check for messages
wipd status                         # see what's taken

# Claim before working
wipd take TASK-1 -m "implementing feature X"

# If claim fails, pick another task
wipd take TASK-2 -m "fallback task"

# Signal completion
wipd done TASK-1 -y

# Message another agent
wipd mail send agent-2 "TASK-1 done, TASK-3 is unblocked"
```

## Confirmation Rules

- `done`: requires `-y`
- `drop`: requires `-y` AND `-m "reason"`
- `clear` (multiple): requires `-y`

Without `-y`, shows what would happen and exits. Safe to run without flags to preview.
