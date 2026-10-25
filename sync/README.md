# Account synchronization implementation — not activated in the released apps

This directory implements a shared account-sync core and provider adapters. It is **not yet connected to the Mac or GitHub Pages interfaces**, and no live provider account has been verified. OPML import in the released app remains a subscription copy, not synchronization.

Implemented adapters: Inoreader (registered OAuth), FreshRSS (server API password), Feedbin (HTTP Basic over HTTPS), and NewsBlur (authenticated session). Feedly, BazQux, The Old Reader, FeedHQ and Instapaper are listed as not implemented in the registry. No unsupported provider is shown as connected. Additional adapters can implement the same `pull`/`push` interface.

## Implemented behavior

- Account-scoped article identity using provider IDs, never publisher URL matching.
- Read/unread and saved-state pull and push; local subscriptions and folders are imported from provider snapshots.
- Persistent, coalesced state-change queue and serialized sync per account.
- Pending changes survive failure and restart. A change is cleared only after the provider snapshot confirms it, not merely after HTTP success.
- Local changes during a request take precedence over that older response and remain queued.
- Partial or failed snapshots never replace the prior complete state. Pagination limits cause a visible failure rather than silently dropping old items.
- Provider errors avoid including credentials or raw authenticated response bodies.
- OAuth state validation, replay rejection, write-scope validation, access-token refresh locking.
- AES-256-GCM credential vault with an independently supplied backend key. Client secrets and provider sessions do not belong in the GitHub Pages assets or public repository.
- Atomic serialized JSON persistence; the host chooses external-volume data directories on this Mac.

`AccountService` connects adapters, the engine, the encrypted vault and OAuth. It is a host-neutral boundary; it does not open a public port. A host must authenticate the user and provide an owner-scoped service instance. Never expose this service directly without that authentication.

## Remaining work before real use

1. Register Leaf Reader with Inoreader and obtain its own authorized OAuth client configuration. The existing Reeder/NetNewsWire credentials must not be copied. Current Inoreader documentation requires app registration; developer access depends on provider eligibility. No paid upgrade is authorized.
2. Provide a trusted HTTPS backend callback and secret storage. GitHub Pages only serves static files and cannot hold an OAuth client secret. No hosting account, API credentials or public backend is currently configured.
3. Add the authenticated backend HTTP/session layer, wire the web and Mac account views to it, store native session credentials in Keychain, and route every read/star action through the account queue. The existing local-only library must remain isolated.
4. Implement subscription changes (add/remove/move) on provider accounts; current adapters pull subscriptions and push reading/saved state only.
5. Run real-account tests: mark read in Leaf, observe Inoreader/Reeder/NetNewsWire; reverse it; verify saved state, restart, offline replay, pagination, expired login and disconnect. Test each additional provider against an authorized account before presenting it as supported.
6. Improve incremental article-body downloads and rate-limit scheduling before enabling large libraries or background polling. Current bounded full pulls are correctness-oriented scaffolding, not an optimized production client.

## Tests

Run `node --test tests/sync.test.mjs`. Tests use simulated provider responses; they do not log into or change a real account. A passing fixture test is not proof that the user's live account synchronizes.

## Primary API references

- Inoreader registration: https://www.inoreader.com/developers/register-app
- OAuth and backend requirements: https://www.inoreader.com/developers/oauth
- Article IDs: https://www.inoreader.com/developers/article-ids
- Reading/saved edits: https://www.inoreader.com/developers/edit-tag
- Feedbin: https://github.com/feedbin/feedbin-api
- NewsBlur: https://newsblur.com/api
- FreshRSS: https://freshrss.github.io/FreshRSS/en/developers/06_GoogleReader_API.html
