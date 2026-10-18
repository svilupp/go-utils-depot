# Live Chromium review

Live mode requires Node 22+ and the complete Revlet archive, with `browser/`
beside the executable. The archive includes pinned BrowserPilot 0.7.0, its runtime
dependencies, licenses, and a SHA-256 manifest. No runtime package install is needed.

```sh
revlet check --live
revlet live --session review-browser --target <exact-target-id>
revlet live --endpoint ws://127.0.0.1:9222/devtools/browser/<id>
```

AI discussion also requires compatible Cloop and an authenticated driver.
`check --live` validates prerequisites without a model turn or browser attachment.

Supply exactly one of a named BrowserPilot session or an explicitly enabled local
Chromium browser websocket. Omit `--target` to choose the exact tab in Revlet's
local UI. Do not use a page websocket or guess an unrelated endpoint.

Attachment preserves the existing viewport and unsaved state. Select an element
to capture immutable evidence, then discuss its card in Revlet. Browse normally
or Escape restores page interaction. Finish removes the overlay and leaves the
borrowed browser open; it never applies site edits.

Images require explicit capture and inclusion. Masks cover fields, editable or
marked private regions, and inaccessible frames; arbitrary visible prose can
still contain secrets. Preview evidence before sharing it with a model.

```sh
revlet live --session review-browser --target <exact-target-id> --record
revlet resume <review-id>
revlet resume <review-id> --attach-session review-browser
```

Recording captures bounded subsequent metadata, with request bodies and event
screenshots disabled. It is not a restorable checkpoint and does not authorize
replay. Navigation pauses capture; accept the displayed origin before starting
a new capture generation. Recording must be restarted explicitly.

Resume opens saved evidence detached. Reattachment preserves the saved exact
target; a disappeared tab is never silently replaced. Open shadow roots and
same-origin frames support selection; other frames, closed roots, and canvas
internals remain regions.

For deliberate helper development, `REVLET_LIVE_HELPER` selects another helper
and `REVLET_BP_ROOT` selects another built BrowserPilot tree. Leave these unset
to use the packaged helper and dependency integrity checks.
