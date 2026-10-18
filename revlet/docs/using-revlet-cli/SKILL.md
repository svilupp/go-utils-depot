---
name: using-revlet-cli
description: Use Revlet to annotate and rate document batches, or review Markdown, HTML, website snapshots, or live Chromium tabs with optional AI assistance. Covers preparing assets from templates, starting and resuming reviews, and consuming the final handoff.
---

# Using Revlet CLI

Revlet opens a private browser review where the user annotates documents, rates batch items, or iterates with an AI reviewer. Typed notes work without a provider in annotation mode; dictation requires transcription configuration. The calling agent waits for the final handoff, then continues its task.

## Choose the review mode

| Need | Command | Write boundary |
|---|---|---|
| Annotate tasks or rate generated outputs without AI | `revlet annotate task-a.md task-b.md` | Originals stay read-only |
| Review existing or newly authored files | `revlet design.md prototype.html` | Only Finish & apply writes proposals to the selected originals |
| Review anonymous server HTML | `revlet website https://example.com` | Saved snapshot stays read-only; no website writes |
| Review an existing authenticated or client-rendered page | `revlet live --session <browserpilot-session>` | Captures evidence from a borrowed tab; no site edits or automated site actions by the reviewer |

One invocation creates one review. Ordinary assisted file review shares one conversation across files. Annotation batches scope optional AI conversations to each item. To continue a saved review, use `revlet resume <id>`, not another new invocation. For live attachment, navigation, images and limitations, read [website modes](references/websites.md).

## Prepare assets when needed

Existing artifacts need no template or reformatting. If asked to create an artifact, write it into the user's working directory before launching Revlet; do not edit the skill's templates in place.

- Use [authoring principles](references/authoring.md) for decision-first prose and useful visuals.
- Use [format patterns](references/formats.md) for Markdown anchors, Mermaid and self-contained HTML constraints.
- Start from the [proposal template](assets/proposal.md) or [HTML brief template](assets/brief.html) when useful.

Keep the user's existing structure and voice unless the requested review calls for a change. Files must be UTF-8 regular files, at most 15 MiB each. HTML previews disable author scripts, event handlers and external stylesheets; use inline styles and native interactions, or use live mode for a running application.

## Preflight and parent conversation

Human annotation with the default `none` follow-up policy skips provider setup. For batch fields, manifests, navigation, and exports, read [the annotation workflow](references/annotation.md).

Run `revlet check` before a long AI-assisted review; add `--live` for live-browser prerequisites. These checks make no model turn. Use `revlet schema` and command `--help` for the installed CLI's detailed contract.

With `driver = "auto"`, Revlet detects Codex, Claude Code or Pi and forks the caller's conversation into a separate review child. If a saved config pins another driver, use `--driver auto` deliberately. Never guess a parent session ID or resume the parent directly.

- If detection cannot identify the parent, supply a verified `--parent <session-id>`.
- Pi requires the full session UUID. Revlet's optional `pi/revlet-session.ts` extension exports `REVLET_PI_SESSION_ID` to Pi shell commands; verify detection with `revlet check`.
- Claude can export its session ID through the `revlet claude-env-hook` SessionStart hook; otherwise supply a verified parent explicitly.
- Use `--standalone` only when an isolated review is intended, not as a silent workaround for missing parent context. A plain shell without caller markers defaults to standalone Codex.

```sh
revlet check
revlet design.md api.md
revlet --driver claude --parent "$CLAUDE_SESSION_ID" prototype.html
revlet --standalone design.md
```

All reviewer model turns require compatible Cloop read-only capabilities. If checks fail, fix the reported configuration, authentication or Cloop mismatch; do not bypass Revlet with an unsafe direct model invocation. `revlet init` configures private settings; never put credentials in artifacts or handoffs.

## Run and wait

Keep the review process alive while the user works. Allow a long-running tool call or retain a managed process handle; a short tool timeout must not terminate an active review. Do not abandon the process or treat opening the browser as completion.

The user selects a subject, comments, and sends with Cmd/Ctrl+Enter. Annotation mode saves notes and item judgments; AI-assisted modes also show replies and any permitted proposals. Voice is optional. Leave Send and Finish to the user unless explicitly asked to operate them.

- **Finish & apply** applies file proposals after checking original hashes and taking artifact locks. Do not concurrently edit the selected files while review is active.
- **Finish review** in annotation, website, and live modes returns findings without modifying originals. Annotation batches also write the requested `--export` file.
- **Ctrl-C** pauses without applying proposals. Interruption is not a completed review; continue with `revlet resume <id>`.

Progress and the capability-bearing browser URL go to stderr; treat the full URL as private. `--no-browser` prints it without opening a tab. Stdout is the final bounded `REVIEW_COMPLETE` handoff, or the final result with `--json`.

## Consume the handoff and recover

Read the returned handoff and any annotation export before continuing the calling task. Inspect changed files after an assisted editing review. If the handoff is truncated, use `revlet show <id>` for the complete saved version. Carry forward decisions, unresolved questions and requested follow-up work; do not infer completion from process exit alone. Exit status 1 includes errors, conflicts and interruption.

```sh
revlet list                # retained review metadata as JSON
revlet resume <id>         # saved annotations, context and any proposals
revlet show <id>           # complete saved handoff
```

Resume preserves the saved driver/model/parent; it rejects overrides. Live reviews resume disconnected unless explicitly reattached; see [website modes](references/websites.md).

If applying proposals reports a conflict, inspect the originals and saved review state rather than overwriting concurrent changes. Multi-file application is not a cross-file transaction: an I/O failure can leave some files applied. Durable `before/`, `after/`, `work/`, transcript and handoff data live under `$XDG_STATE_HOME/revlet/reviews` (default `~/.local/state/revlet/reviews`).

Default `revlet clean` removes only disposable cache. `clean --reviews` deletes eligible durable review state; use it only when explicitly asked to discard that history.

## Batch annotation details

Read [the annotation workflow](references/annotation.md) for custom enums, item notes, supporting artifacts, optional follow-ups, and JSON or CSV export. Leave the browser open until save confirmation and consume the retained export before continuing the calling task.
