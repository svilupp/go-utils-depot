# Annotate and rate a collection

Use `revlet annotate` for human review of tasks, generated answers, or other UTF-8 documents. Typed comments, ratings, navigation, resume, and export work without Cloop, a parent session, or model credentials. Original files stay read-only.

## Start a batch

```sh
revlet annotate task-a.md task-b.md \
  --enum 'disposition=keep,revise,drop' \
  --export task-review.json

revlet annotate output-a.html output-b.md \
  --ordered-enum 'quality=reject,needs-work,strong' \
  --selectable --export output-review.json
```

Each file becomes one item. Repeat `--enum` or `--ordered-enum` for more fields. An enum defines categories. An ordered enum lists values from lowest to highest. An empty field means unrated. Selection is independent of quality and review status. Field definitions stay fixed for the lifetime of a saved batch. To change a field or its allowed values, export existing judgments and create a new batch.

1. Choose an item from the batch index.
2. Record its overall note, ratings, and review status above the document.
3. Select a document block and send a comment for a specific observation.
4. Use previous, next, or next unreviewed to move through the batch.
5. Finish the review and inspect the export and handoff.

Wait for save confirmation before closing the process. If saving fails, keep the draft and retry with the same request identity. A failed AI reply does not remove an acknowledged human annotation.

## Group related documents

A manifest groups an answer and its supporting documents into one review item.

```json
{
  "schema_version": 1,
  "title": "Answer review",
  "fields": [
    {"id": "quality", "type": "ordered_enum", "values": ["reject", "needs-work", "strong"]},
    {"id": "selected", "type": "boolean"}
  ],
  "items": [
    {
      "id": "candidate-a",
      "title": "Candidate A",
      "group": "question-1",
      "primary": "answer",
      "artifacts": [
        {"id": "answer", "path": "a/answer.html"},
        {"id": "brief", "path": "brief.md"}
      ],
      "metadata": {"external_id": "candidate-123"}
    }
  ]
}
```

```sh
revlet annotate --manifest batch.json --export judgments.json
```

Paths resolve relative to the manifest. Item IDs remain stable across sorting and resume. Use unique item IDs and unique artifact IDs within each item. `primary` names one of that item's artifacts. Unknown field types, duplicate identities, invalid primary references, and conflicting field definitions fail before the browser opens. A manifest supplies all fields: do not combine `--manifest` with `--enum`, `--ordered-enum`, or `--selectable`.

## Choose optional AI assistance

```sh
revlet annotate answer.md --follow-up none
revlet annotate answer.md --follow-up manual
revlet annotate answer.md --follow-up automatic
```

The default policy is `none`. `manual` exposes an explicit request for AI help with a saved annotation. `automatic` requests a reply after saving the annotation. Assisted policies need the usual provider configuration and Cloop capabilities. Assistance does not grant permission to change annotation inputs.

AI follow-up prompts have a separate 2 MiB limit. An oversized item fails before provider dispatch. Create a smaller manifest item or separate supporting documents into a new batch to reduce context. The current UI does not select a supporting-file subset within an item.

Existing `revlet proposal.md` continues AI-assisted review with its existing proposal and Finish workflow. Annotation and assisted review share durable comments and target context. An uncertain interrupted provider operation stays visible in the saved state and export. Revlet blocks automatic resends and has no reconciliation or cancellation control for that outcome. Inspect the retained provider receipt before arranging a separate follow-up.

Dictation is optional and needs transcription configuration. Audio goes to the transcription service. With `--follow-up none`, sending dictated text saves a note without requesting an AI review. Manual and automatic follow-ups use the same policy for dictated and typed notes.

## Resume and export

```sh
revlet resume <review-id>
revlet export <review-id> --format json --out judgments.json
revlet export <review-id> --format csv --out summary.csv
revlet diagnostics <review-id> --out diagnostics.zip
```

Export does not start a browser or provider. Export and diagnostics destinations must be outside Revlet's private state and must not replace a reviewed source, including symlink or hardlink aliases. JSON retains the saved annotation state and batch definitions. CSV summarizes items and escapes spreadsheet formula prefixes. Read the result before using a judgment as an input to another process. A personal rating is not a validated benchmark score.

Resume uses the retained snapshots, identities, and field definitions. Editing the original source does not retarget earlier annotations. Source proposals and changes remain governed by the workflow's write policy.

## Limits and diagnostics

Each document may contain at most 15 MiB, exactly 15,728,640 bytes. The ceiling applies per file, not to the combined batch. Website HTML and replacement proposals use the same document limit. Audio, images, HTTP requests, and AI context have separate limits. Cloop responses allow up to 128 MiB of encoded JSON and 96 MiB of decoded aggregate reviewer message, so nested JSON escaping can carry a valid replacement. Every proposed artifact still has its own 15 MiB ceiling; the response budgets also bound aggregate proposals.

The browser requests document metadata during polling and loads the selected document separately. Document blocks arrive in pages of at most 150 blocks and about 512 KiB of rendered HTML by default. A single larger block remains one page. HTML previews keep the existing isolated, script-disabled behavior.

Local operation records live at `<review-directory>/diagnostics/events.jsonl`. Logs rotate at 10 MiB and retain three older generations. The directory is private and logs use mode `0600`. Records contain operation names, IDs, durations, byte counts, and result codes. They omit document text, comments, audio, credentials, and private browser URLs. A logging failure produces one stderr warning and a nonblocking browser warning. Notes and ratings still use their independent save path. A missing diagnostics file does not mean a note failed to save.

| Symptom | Recovery |
|---|---|
| Note did not save | Keep the draft and retry the same operation identity |
| AI failed after saving | Keep the note and inspect the follow-up outcome before retrying |
| Document revision changed | Reload the document and select the intended current target |
| Large document is slow | Load another page or use the available HTML preview and inspect diagnostics |
| Export failed | Keep the review and export again to a writable destination |

`revlet diagnostics` creates a private zip containing typed operation logs and a count-only summary. It excludes artifacts, transcripts, annotations, and configuration. Use installed command help and `revlet schema` as the CLI contract.
