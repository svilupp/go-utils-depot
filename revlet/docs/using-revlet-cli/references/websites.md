# Website review modes

## Read-only server HTML snapshot

```sh
revlet website http://localhost:3000
revlet website https://example.com --driver claude --standalone
```

Revlet makes an anonymous GET, follows at most four redirects, and accepts UTF-8 HTML up to 15 MiB. It saves a durable snapshot with its final URL. Relative image URLs resolve against that URL. Comments carry element anchors and source context; the reviewer returns findings and decisions, with no snapshot edits. Finish returns a handoff without writing to the website.

This captures server HTML, not the rendered application. JavaScript hydration, authentication cookies, live updates and external CSS are not reproduced. Inline styles and native HTML interactions work. For an authenticated or heavily client-rendered page, use live mode below, or export rendered HTML with inline styles and review the saved file. Avoid including private input values in exports.

The snapshot preview uses an opaque-origin sandbox, with scripts allowed only for Revlet's protected bridge. It does not embed the running site or inherit its authentication.

## Live existing Chromium tab

Requires Node 22+ and the packaged, pinned BrowserPilot helper. Use an explicitly selected local BrowserPilot session or an explicitly enabled loopback Chromium browser CDP connection. Do not guess endpoints, attach unrelated tabs, or launch a replacement for a tab with unsaved state.

```sh
revlet check --live
revlet live --session review-browser --target <exact-target-id>
revlet live --endpoint ws://127.0.0.1:9222/devtools/browser/<id>
```

Supply exactly one of `--session` or `--endpoint`. The endpoint must be the local **browser** websocket, not a page websocket. Omit `--target` to let the user choose the exact tab in Revlet's local UI; titles and URLs are labels, not target identity.

Attachment does not activate, reload or resize the borrowed tab. The website still runs its own JavaScript: this is not the snapshot sandbox. The reviewer cannot automate site actions or edit the site, but the user can interact normally in Browse normally mode.

### Capture and discuss

1. In the local Revlet UI, choose **Select element**, then point/click in the target tab. The picker shields the pointer sequence, including native dialogs.
2. The selection becomes an immutable evidence card. Select its card, type a comment and send with Cmd/Ctrl+Enter. Voice controls stay in Revlet, not the website tab.
3. Escape in the website or **Browse normally** restores ordinary interaction. Fresh captures do not rewrite old evidence; stale/saved/detached states remain visible.
4. **Finish review** returns findings, drains evidence, removes the overlay and leaves the borrowed browser open.

Open shadow roots and same-origin frames support element selection. Cross-origin frames, closed shadow roots and canvas internals remain regions. Full navigation pauses capture: explicitly accept the displayed origin to start a fresh picker generation. A lost target is never silently replaced with a different tab.

### Images and recording are explicit

Fresh text capture and masked viewport/crop capture are separate. Image capture does not scroll or resize the tab. **Include image** is opt-in per observation; supported Codex/Cloop conversations receive selected images, with receipts. Other drivers continue with text and retain images for human review.

Masks cover fields, editable/private regions and inaccessible frames, not arbitrary secrets in unmarked prose, canvas or images. Preview evidence before sending it; do not assume masking makes every page safe to share with a model.

Use `--record` or the UI's recording control only when reproduction history is wanted:

```sh
revlet live --session review-browser --target <exact-target-id> --record
```

Recording is bounded metadata history, not a restorable checkpoint or automatic workflow replay. Request bodies and event screenshots are off. Stop and Finish drain it; navigation stops collection and recording must be restarted explicitly. Interrupted captures can be partial; do not claim missing events were retained.

### Resume and reattach

```sh
revlet resume <review-id>                                  # saved evidence, disconnected
revlet resume <review-id> --attach-session review-browser  # explicit reattachment
revlet resume <review-id> --attach-endpoint "$LOCAL_CDP_WS"
```

Reattachment preserves the saved exact target and starts a new generation. A disappeared target or different target is refused. New selections capture fresh observations; historical cards stay unchanged.
