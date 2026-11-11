# Leaf Reader for Mac

Standalone local reader for macOS 14 or newer, built for Apple Silicon and Intel. No server, account, ChatGPT sign-in or subscription is required. Each Mac keeps its own independent library. Sync is deferred at the user's request.

Build with `zsh scripts/build-mac.sh` on the configured external Samsung T7. The script verifies its volume UUID and produces `build/Leaf Reader.app`, with the existing Leaf logo and a universal executable. The app is ad-hoc signed, not Apple notarized; another Mac may require approval through macOS security settings. Intel compilation is verified, but physical Intel hardware has not been tested.

## Subscriptions and new posts

Use Add Feed for RSS, Atom, website discovery or a Substack publication URL. Use Subscriptions & Import for reviewed OPML import/export, folders and organization. Fresh installations start empty; existing subscriptions and read markers are preserved. A Substack profile URL is not a publication feed.

New posts are checked every 15 minutes by default while the app is open and the Mac is awake. Settings offers manual, 5, 15, 30 or 60 minutes. Launch, activation and wake also check when due. Closed or sleeping apps cannot fetch posts. Read markers persist across refresh and restart. Up to 200 headline records per feed are retained; normal article bodies are not kept in the headline cache.

Public publisher text can be read inside Leaf Reader. Publisher-marked subscriber-only posts retain their headline and open in the browser for access with the user's subscription. Leaf Reader does not unlock paywalls or import browser login cookies. Feed availability and completeness depend on each publisher.

## Storage and reading

Live library: `~/Library/Application Support/LeafReader/`. Subscriptions, settings and read markers are saved atomically. Read Later retains extracted text locally; images remain remote. Mark Read removes Read Later and deletes its body by default. Optional post-read body retention is capped at 30 days. Reducing retention shortens existing expiry; increasing it does not extend stored bodies. Cleanup runs on launch, access, refresh and each minute while running.

Settings covers article typography, interface appearance, reading behavior, refresh, storage, mail/browser choices and subscriptions. Bottom filters are Read Later, Unread and All Items. Mark All Read clears the selected article in the marked scope. Context menus provide article and feed actions. Leaf controls share available article text; mail creates a draft rather than sending automatically.

## Validation

Node tests cover shared reading behavior. Native store tests cover persistence, retention, feed URL validation and OPML. Actual WebKit engine tests cover RSS/Atom, Substack discovery, empty feeds, paid metadata, safe blocks and partial extraction. Display regressions cover rendered typography, saved settings, Mark All Read clearing, late extraction cancellation, history and context marking. Live publisher feeds were checked separately; these checks do not guarantee every publisher's future extraction or availability.
