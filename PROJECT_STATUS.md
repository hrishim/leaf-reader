# Leaf Reader shared handover

Updated 2026-11-11. Read this before continuing work in any Leaf Reader chat. This is a curated project handover, not an automatic merge of conversation histories. Update it after meaningful work, using verified results and source-chat links. Do not put credentials, cookies or full private emails here.

## Chat index

1. [Automate Email Article shortcut](codex://threads/01a16385-5dc5-74f3-899b-c53b3a129966) — original build conversation, 22–23 October. Expanded from an iOS sharing shortcut into PublicRSSReader/Leaf Reader; Reeder comparison, REA investigation, standalone Mac build, extraction, retention and iCloud requirements. Latest original-chat packaging checks were unfinished; later work in the main chat supersedes them where verified.
2. [Find Leaf Reader chat](codex://threads/01a16733-aad6-76f0-8878-55387689c878) — main continuation, GitHub publication, Mac/web revisions, feed imports, sync architecture, Inoreader refusal and alternative-service discussion. Continue product work here by default.
3. [Import OPML NewsBlur](https://chatgpt.com/c/6adf4d48-3294-83ee-bd83-758cf3a89c6f) — separate ChatGPT conversation. User reported unresponsive import/account controls. Its assistant suspected an interface bug, but this is not a verified root cause. User subsequently rejected NewsBlur in the main chat. Do not restart that migration without a new instruction.
4. [Locate reverse engineering skill](codex://threads/01a17c0e-9c3d-7080-ba74-afccdf13f57a) — confirms original REA skill location.
5. [Locate Reverse Engineering skill](codex://threads/01a17d36-5e70-7572-847b-b600ffec8abb) — confirms REA location and reports installed Ghidra. Supporting tooling context, not another app implementation.

Incidental mention only: [Fix hearing aid connection pop-up](codex://threads/01a16e53-cb0b-7f92-879c-5c7a186eebaf). The user explicitly said that was a separate troubleshooting chat. Do not mix its work with Leaf Reader.

Search coverage: live and archived chat listings, the local session title index, and user messages in local sessions dated 21–29 October. Internal approval-review sessions were excluded. Older non-listed/cloud-only chats may remain undiscovered; do not claim universal account-wide search coverage.

## Canonical project and artifacts

- Source: `/Volumes/codex_Extender/Projects/LeafReaderGitHub`; remote `git@github.com:hrishim/leaf-reader.git`.
- Live web: https://hrishim.github.io/leaf-reader/ ; design preview: https://hrishim.github.io/leaf-reader/preview/ . Deployment has not been retested on 29 October.
- Original project/tools: `/Volumes/codex_Extender/Projects/PublicRSSReader`.
- REA: `/Volumes/codex_Extender/Projects/PublicRSSReader/tools/node_modules/rea-agents/skills/reverse-engineer-anything/SKILL.md`; project workflow: `../PublicRSSReader/REA-workflow-and-prompt.md`. Use original skill, not a replacement. Original build chat explicitly records its use to inspect Reeder.
- Last reported Mac package: `/Volumes/codex_Extender/Outputs/NativeReader/Leaf-Reader-Mac-1.6.zip`. Ad hoc signed; no claim of notarization.
- Latest user-supplied subscription export: `/Users/sathyavasu/Downloads/Inoreader Feeds 20261026.xml`. It is OPML XML; do not overwrite with the older export. Old export: `/Volumes/codex_Extender/Outputs/LeafReader/Inoreader-Subscriptions-2026-10-25.opml` (13 feeds). New export includes at least one changed publisher feed URL; review before migration.

## Verified code state on 29 October

Repo HEAD `02f590f`: authenticated sync transport/native client and loopback tests. Prior `10b9a11`: multi-provider core/adapters. Prior `5a570be`: approved local-reader redesign. Working tree was clean before this handover was added.

The released reader supports local RSS/Atom, reviewed OPML import, folders, Today, Read Later/Unread/All Items, text/interface settings and reading-state persistence. These are historical implementation results, not a fresh full visual acceptance test on 29 October.

`sync/` implements a persistent state queue, encrypted credential vault, authenticated single-owner HTTP boundary and adapters for Inoreader, FreshRSS, Feedbin and NewsBlur. `mac/ReaderSyncClient.swift` is a backend client with Keychain helpers. **Neither released app is wired to a live sync service.** No public HTTPS backend is provisioned. Passing fixture/loopback tests does not prove live provider synchronization. See `sync/README.md` for exact remaining work.

## Decisions and constraints

- Cross-app read/unread and saved status is a key requirement. OPML transfers subscriptions only; never present it as sync.
- Inoreader: Rosen Apostolov's 26 October reply refused new OAuth credentials/integration approval for a free account; a paid subscription is required. No upgrade or charge was made. Do not keep waiting for approval already refused.
- NewsBlur: login was achieved but the feed import was never verified. User rejected the choice and requested alternatives. No verified migration or Leaf Reader connection.
- FreshRSS, BazQux and Feedbin were compared, but no replacement was selected or deployed. Free-only remains in effect; no paid plan, trial with payment obligations, upgrade or charge is authorized.
- User also requested email sign-in and isolated libraries for multiple users. This is **not implemented**. Existing sync server is single-owner and must not be exposed as a multi-user service.
- Original requirement: read article bodies removed by default; optional retention capped at 30 days; Read Later retained until marked read. Keep durable read markers so old read items do not return on refresh.
- Original iCloud sync requirement is deferred, not delivered. Apple signing/provisioning and cross-app/provider sync are distinct concerns. No native iOS/iPadOS app work until Mac/web stability.
- Keep Reader on by default with optional off; headings open original URLs; full available text sharing through Leaf controls; clear sidebar return; scoped Mark All Read clears displayed article; context menus and reliable font settings; bottom Read Later / Unread / All Items. Reeder and NetNewsWire are behavior references. Exclude Bionic Reading.
- Preserve Leaf Reader name/logo per later main-chat direction; earlier original-chat naming deferral is superseded.
- All substantial project/build/download assets use external volume `/Volumes/codex_Extender`, UUID `67158BC2-8049-47D6-AF79-BC96D9E6CC9E`. Verify mounted external identity before creating assets. Credentials/live state may remain internally as necessary.
- Avoid multiple browser windows/profiles; use one clearly identified account session. No passwords in chat, repository or handover.

## Current scope and verified revision — 11 November

The user explicitly deferred all syncing and requested a standalone local Mac app, independent on each Mac. This supersedes the historical sync work list above. Do not install FreshRSS or reconnect NewsBlur without a new request. No service was installed and no paid account was used.

Version 1.8 adds configurable automatic refresh (15 minutes by default while open/awake), launch/wake checks, durable headline metadata, preserving read markers and older loaded headlines across refresh, Substack publication normalization, public full-feed text fallback and subscriber-only headline handling. Existing Leaf branding is retained. Fresh installs have no demo feeds. Subscription controls replace the dormant account-provider chooser. Latest OPML feed URL corrections preserve read/saved state.

User's local library has Krishnan, Maratha History: Beyond Conquests, The Economist (publisher title Latest Updates) and Amish Tripathi (official authoramish.com feed). These personal choices are not bundled as default subscriptions. Paid bodies still require the publisher's browser login. Existing Swarajya and New Indian Express Nation feeds reported errors during live checking; other publishers' availability is not guaranteed.

Validation: 37 Node tests, native display regression suite, store tests and 12 actual WebKit engine assertions pass. Universal arm64/x86_64 build targets macOS 14; only this Apple Silicon Mac has been exercised. Package is ad-hoc signed, not notarized. Release artifact: `/Volumes/codex_Extender/Outputs/NativeReader/Leaf-Reader-Mac-1.8.zip`.

Next: user trials of the local app; fix concrete reported issues. Sync, multi-user email login and native iOS remain deferred. Source chat: main continuation linked above.

## Cross-chat continuity procedure

- Start from this file and the linked source chats; verify current code and deployment before relying on historical claims.
- Keep one coordinating chat (Find Leaf Reader chat) and one canonical repository. Additional chats should read this handover first and record their verified outcome here.
- After changes, record date, source chat, commit/artifact, tests, remaining gaps and next action. Resolve conflicts with the latest explicit user instruction.
- Preserve original histories. Available chat-management tools do not provide a merge operation; do not edit internal conversation databases or promise automatic two-way history synchronization.

## Read headline appearance — 11 November

Version 1.8.1 dims read article rows to 55 percent opacity, regular-weight secondary-color headlines. Marking unread restores prominence. Scoped All Read remains; Unread clears read rows, All Items keeps dimmed rows. Reeder Item menu exposes Mark All as Read. Native display regression suite passes, including read/unread appearance assertions.

## Substack Reader recovery — 11 November

Version 1.8.2 refetches a Substack feed when a restored headline has no body, uses available public feed text and falls back to page extraction when needed. Existing stale-request guards remain. Economist feed label migrates from Latest Updates to The Economist. Native display suite passes. Two installed copies were found running, with Reader Off selected. Substack Chrome session is signed out; complete account subscription import remains pending user sign-in, not delivered. Gmail newsletter history is not a complete current subscription list.

## Substack Reader repair — 11 November

Version 1.8.3 fixes XML field priority: full content:encoded now wins over earlier description teasers. Available Substack feed text displays in Reader mode, with short excerpts labelled. Verified on the installed Mac app. Native display suite, 13 actual WebKit assertions and 37 Node tests pass. Public feed subscriptions were imported through reviewed OPML into the local Substack folder; this is a one-time import, not account synchronization. Personal OPML remains outside Git. User asked to leave the magazine aside; no further work on it. Installed app: Outputs/NativeReader/Leaf Reader.app; package Leaf-Reader-Mac-1.8.3.zip. The prior pending-sign-in status is superseded.
