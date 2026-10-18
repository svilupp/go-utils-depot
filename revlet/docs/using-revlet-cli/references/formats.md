# Markdown and HTML patterns

## Markdown proposal

Use the optional [proposal](../assets/proposal.md) as a starting point. A useful proposal usually contains the decision, scope, mechanism, tradeoffs and unresolved questions. These are editorial prompts, not required headings.

Use fenced `mermaid` blocks; diagrams anchor as a whole. Ordinary blocks anchor to source lines. Repeated headings remain distinct. Raw HTML in Markdown is excluded from the preview; use a `.html` artifact when native HTML is needed. Math syntax is plain text unless you provide a self-contained HTML representation.

```sh
revlet design.md api.md
revlet --driver claude --parent "$CLAUDE_SESSION_ID" design.md
revlet --standalone --driver pi --model openai/gpt-4o-mini design.md
```

In assisted file mode, one invocation creates one review across all selected files. `revlet resume rvw_0123456789abcdef` continues the saved provider child; a second invocation starts a new review.

## Self-contained HTML brief

Copy the optional [brief](../assets/brief.html). Prefer semantic headings, short labeled sections, inline CSS, SVG diagrams, readable tables and native `details` for optional evidence. Include responsive wrapping and meaningful accessible labels.

```html
<section data-review-id="retry-policy">
  <h2>Approve three attempts</h2>
  <p>Only idempotent operations may retry.</p>
  <details><summary>Failure evidence</summary><p>After attempt three, fail this item.</p></details>
</section>
```

Revlet isolates previews in an opaque-origin sandbox. Author scripts, event handlers, embedded frames, external stylesheets and form submission are disabled. Inline styles, SVG, MathML, text inputs and native details can be reviewed. The stored original is preserved for the reviewer. Assisted file reviews apply approved proposals only on Finish; annotation inputs stay read-only.

Semantic IDs improve stability. Elements without IDs receive deterministic DOM-path anchors. Duplicate IDs receive distinct suffixes. Clicking inside an SVG initially selects the whole SVG when no deeper anchor exists.
