# Leaf Reader

A responsive RSS/Atom reader for GitHub Pages. No ChatGPT account, app account, API key or paid service is required. The existing Leaf name, leaf mark and reader layout are preserved.

Subscriptions, read status and saved article text stay in this browser's local storage. They do not sync between devices or browsers. Clearing site data removes the local library; use Manage → Export OPML to back up subscriptions. Only Read Later articles retain text across restarts. Marking an article read removes it from Read Later and deletes its saved body. Images remain remote.

Public feeds and article pages are attempted directly, then through the free anonymous [CORS.dev relay](https://cors.dev/docs) when browser cross-origin restrictions prevent direct access. The relay receives the public URL being retrieved and the visitor's IP address, never the local library. Private/tokenized feed URLs are rejected. The relay's free limits and publisher restrictions may prevent some feeds or full articles from loading; the app reports failures and keeps the Original link. It does not bypass paywalls. A successful extraction does not guarantee completeness.

Reader on extracts the article; Reader off shows feed content. Article titles link to the original. Other controls include search, dark appearance, text size, mark all read, OPML import/export, copy and email draft. The service worker caches the app shell for offline reopening; only saved article text is available offline.

## Publish

Create a public repository, push `main`, then choose **Settings → Pages → Source → GitHub Actions**. The included workflow checks JavaScript and deploys `web/`. It requires no repository secrets. The final URL is shown by the successful Pages deployment. Local preview: `npx --yes http-server web` or any existing static HTTP server.

## Validation

Run `node --test tests/*.test.mjs`. Browser verification must also cover live feed loading, article extraction, persistence, offline saved reading and responsive layout; static checks alone do not establish those behaviors.

Mozilla Readability is bundled with its Apache 2.0 licence in `web/vendor/Readability-LICENSE.md`. The app source is kept separate from the earlier hosted service and native Mac build.

## Native Mac app

The standalone AppKit source is in `mac/`. Build on macOS with `zsh scripts/build-mac.sh`; compiler caches and temporary files use the external workspace volume. Run `zsh scripts/test-mac-display.sh` for isolated native display tests.

Version 1.2 clears the current article and switches to Unread after Mark All Read. Read history is still available through All articles. In-flight extraction cannot restore a cleared article. Article right-click menus provide read/unread, Read Later, Mark Below as Read, Copy Link, Copy Article Text, Email and Open in Browser. Feed right-click menus provide Open Website, Refresh, Mark Feed Read, Edit and Remove. This implements those core actions; it does not claim complete feature parity with Reeder.

The web update labels mobile Feeds/Articles navigation and uses Hindu Tamil's publisher-supplied RSS article body when its webpage exceeds the free relay's size limit.

Version 1.3 adds Settings to both apps. Aa opens Reading/Appearance controls instead of cycling the font size. Article and interface sizes are separate, saved locally, and clamped to 14–36 px and 11–20 respectively. Reading controls include serif/system sans serif, line spacing and title scale. Themes are System/Light/Dark. Mac Settings opens from Leaf Reader → Settings (Command-comma); browser/email and article-storage controls remain available under General. Web Settings opens from the feed sidebar or Aa. Bionic Reading is excluded. This is not complete Reeder settings parity.

Version 1.4 removes routine storage and end-of-text messages. Opening an article marks it read, keeps the current article visible, and removes it from Unread and feed lists when moving on. All articles remains explicit read history. Previous/reload/next controls appear at the article bottom; previous can revisit articles read during this session. Mark All Read clears the web article pane as well as the unread list.

Version 1.5 corrects the bottom menu to Read Later, Unread, and All Items, matching Reeder's starred/unread/all item filters. Article reload remains available in the top toolbar.

Version 1.6 applies the approved local-reader design: Accounts & Import, direct RSS/website entry, OPML review with folder preservation, updates to matching subscriptions, duplicate/unsupported/limit reporting, folder organization, Today, scoped item filters and bulk marking, oldest-first and manual-marking preferences, persistent bottom filters, and web keyboard navigation/context actions. Mac adds View → Next Unread (Command-J). Account synchronization is still unavailable; provider listings explicitly show this. The public app uses no ChatGPT login or AI service. The separate design preview remains at `preview/`.

Validation includes JavaScript/model tests, native storage/OPML round-trip tests, native WebKit rendering tests, and browser checks at desktop/iPhone widths. Remaining reference features include real provider adapters, offline sync queues, per-feed Reader defaults, customizable gestures/shortcuts, and native extensions/iCloud. This release does not claim complete Reeder/NetNewsWire parity.
