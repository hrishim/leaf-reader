# Native reader working build

Standalone AppKit application for macOS 14 or newer. Swift handles networking and local files. The bundled Mozilla Readability engine runs against inert publisher HTML in a nonpersistent WebKit document. No server, Node runtime, OpenAI account, API key or ChatGPT sign-in is required by the native app.

Build: `zsh scripts/build-mac.sh`. Builds and compiler caches use the configured external volume. The app contains its extraction scripts and default public subscriptions.

## Storage

Live library: `~/Library/Application Support/LeafReader/`. Subscriptions and read status are saved atomically in `state.json`. Merely opening an article does not save its body. Read Later saves extracted text locally; images remain remote. Marking Read removes it from Read Later and deletes the body by default. Article Storage settings offer 0, 1, 7, 14 or 30 days of post-read retention. The store clamps any setting to 0–30. Retained bodies expire from their read date. Reducing retention shortens existing expiry; increasing it does not extend previously stored bodies. Expired bodies are purged on launch, on access, on refresh and every minute while the app is running. A closed app cannot execute cleanup until next launch.

iCloud synchronization is deferred. This build explicitly reports local storage and does not claim to sync. Apple Developer signing and iCloud provisioning remain future work if developer access becomes available.

## Validation

`mac/Tests/StoreTests.swift` verifies immediate deletion, cap enforcement, expiry, Read Later preservation, shortening retention, reopening the library, public URL checks, OPML nested imports/deduplication/private token rejection, escaped export roundtrip, malformed XML, wrong format and oversized imports.

`mac/Tests/EngineTests.swift` runs `engine-tests.js` in actual WebKit: RSS full text, safe blocks, Atom escaped HTML, relative discovery, empty feed, paid article rejection, partial extraction warning and public Substack filtering.

Manual app tests cover direct feed loading without login, full Swiggy extraction, Read Later persistence across restart, removal from Read Later and disk after marking Read, retention choices, nested OPML import and live Atom/Substack feeds.

## Limits

The local app is ad-hoc signed, not notarized or App Store distributed. It is a tested working build, not a claim of universal extraction correctness. Publisher layouts, feeds, restrictions and availability vary. Swarajya's current feed returns no public entries and is flagged; New Indian Express uses public section headlines because its old RSS URLs fail. Paid content is excluded when the publisher marks it as restricted. Email creates a draft through the configured mail app; it does not send messages automatically. Full offline image archives, cloud sync and native iPhone/iPad apps are not implemented.

Final name and logo remain undecided. Web app work is deferred.
