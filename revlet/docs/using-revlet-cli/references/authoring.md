# Authoring principles

Use these guidelines when preparing artifacts for review.

## Protect the reader's attention

State the requested decision and recommendation first. Give each paragraph one argument. Preserve numbers, constraints, dates, confidence and uncertainty; brevity must not remove the condition that makes a claim true. Use tables for comparable alternatives and optional detail for supporting evidence.

Example: “Approve three attempts for idempotent receipt delivery. Exhausted items fail individually; subsequent items continue.” This is reviewable because it names a number, operation and failure behavior. “Improve reliability” is not.

## Show only the useful relationship

Use a small Mermaid flowchart for ownership or data flow, a sequence diagram for timing, a diff for a proposed change, or a table for tradeoffs. Place the visual next to its explanation. Use actual names and labels, including boundaries and failure paths. Avoid a decorative diagram that duplicates every sentence.

```mermaid
flowchart LR
  Client --> Admission[Admission limit]
  Admission --> Queue[Memory queue]
  Queue --> Worker[Persistent worker]
  Worker --> Exhausted[Fail after 3 attempts]
```

The diagram makes the missing durability boundary visible; prose should explain what process exit means for accepted work.

## Keep guidance flexible

Use concrete examples instead of a long catalog of possible styles. Choose the structure that fits the review; the associated templates are starting points, not required formats. Preserve an existing artifact's voice and format when reviewing it.

Before sharing, inspect three cases: a simple decision note, a multi-file technical proposal, and a visual prototype with an interaction. Check whether reviewers can identify the decision and anchor a specific concern without extra explanation.
