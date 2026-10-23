# Revlet

Review Markdown, HTML, website snapshots, or live Chromium tabs in a browser.
Annotate and rate document batches without an AI provider, or discuss selected
artifacts with an AI reviewer through Cloop.

Release: `revlet/v0.2.1`.

## Install

For annotation, file reviews, and website snapshots, install the binary:

```sh
eget svilupp/go-utils-depot --tag 'revlet/' --file 'revlet' --to ~/.local/bin
revlet --version
```

On Windows, select `--file 'revlet.exe'`.

Live Chromium review also needs the bundled helper. Download your platform archive
from the [releases page](https://github.com/svilupp/go-utils-depot/releases), verify
it against `checksums.txt`, and extract the complete archive into a dedicated
directory. Keep `browser/` next to the executable and add that directory to `PATH`.
The binary-only eget installation does not install these companion files.

Archives include the pinned BrowserPilot helper, dependency hashes, licenses,
configuration example, usage skill, and optional Pi session extension. Live review
requires Node 22+; annotation and file review do not require Node.

## Quick start

```sh
revlet annotate answer-a.md answer-b.html \
  --ordered-enum 'quality=reject,needs-work,strong' \
  --selectable --export judgments.json
revlet resume <review-id>
revlet export <review-id> --format csv --out judgments.csv
```

Typed annotation needs no Cloop, parent conversation, or model credentials.
Each file becomes one item; a manifest can group supporting documents. Inputs
remain read-only. Ratings and notes persist before optional AI follow-ups.
See [batch annotation](docs/using-revlet-cli/references/annotation.md).

## AI-assisted review

Install a compatible `cloop` executable separately and authenticate the selected
Codex, Claude Code, or Pi CLI. All reviewer turns require Cloop's `read-only-v1`,
`driver-session-id-v1`, `final-message-v1`, and selected-driver fork capability.
Codex additionally requires `codex-service-tier-v1`; screenshot review requires
`codex-images-v1`.

```sh
revlet check
revlet design.md prototype.html
revlet website https://example.com --standalone
revlet annotate answer.md --follow-up manual
```

Revlet detects a calling agent and forks a separate review child when a verified
parent ID is available. A plain shell defaults to standalone Codex. Use
`--parent <verified-session-id>` when detection needs help, or `--standalone` when
an isolated review is intended. Resume preserves the saved conversation.

Revlet reuses a compatible local Cloop server or starts a private instance.
`revlet init` creates private configuration; [revlet.example.toml](revlet.example.toml)
shows its fields. Driver authentication stays with the installed CLIs. Voice is
optional and requires transcription credentials; audio goes to that service.

## Commands

| Command | Purpose |
| --- | --- |
| `annotate` | Human notes, custom enums, ratings, selection, and optional AI follow-ups |
| `export` | Export saved judgments as JSON or CSV without a provider |
| `revlet file.md page.html` | Assisted review and scoped file proposals |
| `website` | Read-only anonymous server-HTML snapshot |
| `live` | Read-only evidence from an explicitly selected local Chromium tab |
| `resume`, `list`, `show` | Continue or inspect durable review state |
| `diagnostics` | Export typed operation logs and count-only summaries |
| `check`, `init`, `schema`, `version` | Setup and machine-readable discovery |
| `clean` | Remove disposable cache; durable review deletion is explicit |

Use `--help` on each command for flags. Live setup and limitations are in
[live-browser.md](docs/live-browser.md).

## Review and data boundaries

Select a block or evidence card, enter a comment, and press **Send** or
**Cmd/Ctrl+Enter**. Dictation is optional. **Finish & apply** applies assisted file
proposals only after hash and lock checks. Annotation, website, and live review
keep originals read-only. **Ctrl-C** pauses; continue with `resume`.

Documents and replacement artifacts have a 15 MiB limit per file. Large documents
load in pages. HTML previews disable author scripts, event handlers, and external
stylesheets. Website snapshots do not reproduce authentication or JavaScript
hydration; use live mode for an existing rendered page.

The private UI binds to loopback and uses a capability-bearing URL. Keep that URL
private. Progress goes to stderr; stdout returns the bounded `REVIEW_COMPLETE`
handoff or `--json` result. `show` prints the full saved handoff. Exit `0` means
success; `1` includes errors, conflicts, and interruption.

Configuration defaults to `~/.config/revlet/config.toml` with mode `0600`.
Review metadata, snapshots, notes, and transcripts persist under
`~/.local/state/revlet/reviews`; disposable cache uses `~/.cache/revlet`.
XDG overrides are supported. Diagnostics omit document content and credentials;
exports and retained review data can contain the reviewed material.

Multi-file application uses one atomic replacement per file and can partially
complete after an I/O failure. Inspect saved state before retrying a conflict.
Never concurrently edit originals during an assisted review.

See [CHANGELOG.md](CHANGELOG.md) and the
[usage skill](docs/using-revlet-cli/SKILL.md), including its references and templates.
