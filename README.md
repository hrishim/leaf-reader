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
