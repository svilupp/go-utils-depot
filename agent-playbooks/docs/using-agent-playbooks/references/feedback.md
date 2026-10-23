# Feedback and invocation history

Read this to rate the exact guidance consumed, handle multi-read feedback, or inspect usage.

Successful plain reads show an `INVOCATION:` ID when logging is enabled. JSON
read records and search objects include `invocation_id`. Rate the exact content
consumed with:

```bash
agent-playbooks feedback --invocation ID --rating useful
agent-playbooks feedback --invocation ID --rating not-useful --category wrong_skill
agent-playbooks feedback --invocation ID --item 2 --rating neutral
```

Use `--item N` for multi-name reads. Legacy `feedback NAME` describes the
current catalog file, not an earlier read. Invocation history is bounded;
query text is not retained by default. `admin stats --since 7d` reports sample
sizes, incomplete events, errors, and retention coverage. Never treat a
successful CLI exit or positive feedback total as proof that the user's task
succeeded.
