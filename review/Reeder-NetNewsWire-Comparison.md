# Leaf Reader: Reeder and NetNewsWire review

Review date: 25 October 2026. Scope: the installed Mac apps, the earlier Reeder settings inspection, current Leaf Reader source, and official documentation. This is a feature and workflow review, not a claim that every nested preference, gesture, provider login, or network failure was exercised. No provider credentials were copied and no account was added, removed, or upgraded.

## The proposed blend

Keep Leaf Reader's existing name, leaf logo, subdued green palette and spacious article view. Borrow Reeder's reading customization and item-filter model, and NetNewsWire's account/folder hierarchy, direct menu commands, smart feeds and keyboard navigation. Both Mac and web should use the same labels and behavior. Bionic Reading stays excluded.

The clickable HTML preview is a design artifact, not a replacement for the released app. Sample reading, filtering, search, Read Later, context actions, account/import navigation, article size and theme can be explored. Other preferences demonstrate organization only. Provider setup buttons explain the integration gap; they do not connect or synchronize.

## What was checked

- Reeder: the installed app's starred/unread/all controls, article viewer, read-on-open behavior, account menu and Add Account view. The previous section-level inspection covered General, Appearance, Reading, Animations, Shortcuts, Gestures, Actions/Sharing, account options, and the excluded Bionic section. Its long lists and nested selectors were not exhaustively enumerated.
- NetNewsWire: installed Accounts preferences list On My Mac, iCloud, BazQux, Feedbin, Feedly, Inoreader, NewsBlur, The Old Reader and FreshRSS. Main window has account/feed hierarchy, Today/All Unread/Starred smart feeds, timeline sorting and read filtering, next unread, sharing and Reader View. General preferences expose article size/theme, JavaScript, browser/background opening and refresh schedule; Advanced exposes update and crash-log settings. File menu has New Feed, New Folder, Import and Export Subscriptions. Official help supports the keyboard/reading workflow below.
- Leaf Reader: current web and native source and existing regression coverage. The released app has local public feeds, OPML, Reader extraction, text sharing, basic saved/read state, settings, native context menus, persistent read markers and item filters. It has no connected-service synchronization or account model. OPML currently flattens folders and silently skips some entries.

## Workflow comparison and Leaf Reader decision

| Area | Reference behavior | Leaf Reader design / remaining work |
|---|---|---|
| Account setup | Local reading and service accounts are distinct in both apps | Accounts & Import becomes one clear entry. Local reading remains available without sign-in. Each connected account owns its feeds, folders, item IDs and sync state. |
| Import | File import transfers subscriptions; account sign-in enables continuing synchronization | Separate Import OPML and Connect Service. Choose file, preview feeds/folders, show duplicates/skipped entries, choose destination account, confirm and summarize. Never label an OPML import as synchronized. |
| Organization | NetNewsWire exposes accounts and folders; Reeder supports grouping and subscription ordering | Collapsible account/folder sidebar, rename/move feeds, create folders, manual or alphabetical ordering, per-account unread counts. Folder names must survive OPML export/import. |
| Views | Reeder's starred/unread/all and NetNewsWire's smart feeds | Keep the requested Read Later / Unread / All Items filters visible and consistent. Add Today as a smart feed. Preserve account/feed/folder scope when switching the item filter. Current global-only filter behavior needs that scope separation. |
| Reading | Keep current item readable; read markers and filtering support moving through unread items | Mark on open by default; hide read items after leaving. Provide manual marking preference. Mark All Read applies to the visible scope, asks for confirmation, clears the old detail, and optionally advances to next unread. Read markers survive refresh, cache purge and restart. |
| Navigation | NetNewsWire offers Space to scroll/advance, N for next unread, arrow-key pane focus | Implement accessible keyboard focus across all three panes, next unread across feeds, and clear mobile Feeds / Articles back controls. Browser shortcuts must not fire in editable fields. |
| Appearance | Reeder has richer typography/preview controls; NetNewsWire has article themes | Separate article and interface sizes, font, spacing, title scale, system/light/dark, previews and icons. Keep one settings hierarchy across platforms. Respect reduced motion. |
| Reader mode | Reeder supports per-feed automatic Reader View | Per-feed Reader preference plus temporary toolbar toggle. Prefer full publisher feed text when appropriate. Display access/extraction issues when needed, without repetitive storage/end-of-text banners. |
| Article context menu | Read/star/share/open and batch reading actions | Mark read/unread; Read Later; mark this/older items read; copy text or link; open original. Disable actions accurately while loading or without a shareable body. |
| Feed context menu | Subscription and folder management | Rename, move to folder, refresh, mark feed read, copy feed URL, unsubscribe. Account-wide removal and destructive folder actions require explicit scope. |
| Sharing | Reeder integrates services; NetNewsWire uses sharing and browser commands | Explicit Email Article Text / Copy Article Text / Copy Link / system Share. Keep source URL; avoid silent text truncation. Native system services are platform-specific. |
| Offline use | Local cache and service state have separate purposes | Keep Read Later text independently of ordinary cache retention. Queue connected-account read/star changes offline; show pending changes and retry without restoring stale server state over newer local changes. |
| Troubleshooting | NetNewsWire documents error/activity/account tools | Per-account last successful sync, per-feed errors, retry controls, useful error messages, exportable diagnostic report with secrets excluded. A failed source must not block others. |
| Platform features | Native iCloud, extensions, widgets, system menu services | Not implied by a matching UI. iCloud requires its own app entitlement and web interoperability design. Keep out of the first service-sync release until implemented and tested. |

## Service inventory and integration status

The installed NetNewsWire account chooser and Reeder Classic's official list overlap but are not identical. Reeder Classic's official page lists Feedbin, Feedly, FeedHQ, NewsBlur, The Old Reader, Inoreader, BazQux, FreshRSS, Instapaper and Pocket. Presence in an old app or marketing list is not proof a service remains available. Pocket is a legacy entry and is excluded from the proposed active-provider list pending current availability verification. Instapaper is a read-later service, not a subscription-feed service.

| Choice | Present in reference | Leaf Reader situation |
|---|---|---|
| Local RSS / OPML | Both | Already supported; improve folder retention, preview and import reports. No paid source is needed. |
| Inoreader | Both | User uses free mode. Existing approved clients may connect free accounts. Registering Leaf Reader is a separate developer-access requirement; user authorization alone does not supply app credentials. Do not require an upgrade or ask users to paste developer secrets into the public web app. |
| NewsBlur | Both | Official API says no API key is required for session authentication; OAuth registration is a separate process. Candidate for a first integration; still needs client code, protected credential/session handling and end-to-end testing. No account is created or migration selected by this review. |
| FreshRSS | Both | Open-source server with Google Reader API and an API-specific password. Candidate for users with an existing server. Hosting is required; do not assume the user has one or that hosting is free. |
| Feedly | Both | Integration access and current provider approval must be checked for this new app. Do not confuse enterprise self-service API tokens with access granted to an existing consumer reader. |
| Feedbin / BazQux / The Old Reader | Both | Each requires its own implemented adapter, authorization/session design and current plan/access verification. No blanket claim of free sync. |
| FeedHQ | Reeder Classic list | Additional provider to evaluate after common adapters, with current service/API verification. |
| Instapaper | Reeder Classic list | Separate read-later adapter, not an RSS subscription import source. |
| iCloud | Both have Apple sync choices | Not a drop-in solution for a GitHub Pages web app. Requires native signing/entitlements and a deliberate cross-platform approach. |

## Proposed delivery order and acceptance checks

1. Review the clickable design before major implementation. It shows accounts/imports, folders, the three requested filters, settings categories and mobile navigation.
2. Strengthen local reading: folder-preserving OPML with preview/report, independent account/feed scope and item filter, Today, oldest/newest sorting, next unread, scoped bulk read, keyboard focus and persistent preferences. Verify folder round-trip, duplicates, malformed files, read-state survival and iPhone back navigation.
3. Introduce account storage and a synchronization engine: stable provider IDs, per-account isolation, queued writes, pagination, incremental updates, conflict ordering, retries and disconnect. Test with simulated provider responses before using a real account.
4. Implement and validate one real service end-to-end before showing Connect as active. For the user's existing Inoreader account, developer registration remains unresolved. Alternatives should be chosen with the user, not silently substitute a service or create an account.
5. Add remaining adapters only after each passes login, subscription/folder fetch, article fetch, read/unread, saved state, offline replay, restart, token/session expiry and disconnect tests on Mac and web.

A published static web page cannot securely hold provider client secrets. Account sync may need a backend; authenticated traffic must never go through the anonymous public-article relay. Native credentials belong in Keychain and web sessions require a protected server-side design. No paid hosting, service upgrade or credential migration has been authorized.

## Official references

- Reeder Classic features and service list: https://reederapp.com/classic/
- NetNewsWire help hub (current and older version manuals): https://netnewswire.com/help/
- NetNewsWire reading flow: https://netnewswire.com/help/mac/5.1/en/reading-articles.html
- NetNewsWire shortcuts: https://netnewswire.com/help/mac/6.0/en/keyboard-shortcuts.html
- NetNewsWire error log: https://netnewswire.com/help/error-log.html
- Inoreader API setup: https://www.inoreader.com/features/api
- Inoreader OAuth/backend requirements: https://www.inoreader.com/developers/oauth
- NewsBlur API: https://newsblur.com/api
- FreshRSS mobile/API setup: https://freshrss.github.io/FreshRSS/en/users/06_Mobile_access.html
- Feedly self-service API access (not proof of consumer OAuth availability): https://developers.feedly.com/reference/authorization
