# AppLinksAndRoutingSample

A reference sample for a **scene-based UIKit app** that handles app-links
cleanly across all the entry points iOS can deliver them through. Built
incrementally — the first cut covers **custom-scheme deep links** and
**universal links**, sharing one routing core. Quick actions and App Intents
are planned next (see [`ROADMAP.md`](./ROADMAP.md)).

## Scope (current)

| Entry point | Cold start (app not running) | Warm start (already running) |
|---|---|---|
| Custom-scheme deep link (`applinksdemo://…`) | `scene(_:willConnectTo:options:)` → `connectionOptions.urlContexts` | `scene(_:openURLContexts:)` |
| Universal link (`https://…`) | `scene(_:willConnectTo:options:)` → `connectionOptions.userActivities` | `scene(_:continue:)` |

Both rows funnel into the same `AppCoordinator`.

## Architecture

```
                 ┌──────────────────────────────┐
   system  ───►  │         SceneDelegate        │     thin: parameter-passing
  callbacks      │  (4 entry points, no logic)  │     only
                 └───────────────┬──────────────┘
                                 │ url / activity
                                 ▼
                 ┌──────────────────────────────┐
                 │        AppCoordinator        │     parse → dedupe → dispatch
                 │  - DeepLinkRoute(url:)       │
                 │  - Set<DeepLinkRoute> dedup  │
                 └───────────────┬──────────────┘
                                 │ navigate(to:)
                                 ▼
                 ┌──────────────────────────────┐
                 │  RouteNavigating  (protocol) │     test seam
                 └───────────────┬──────────────┘
                                 │
                       ┌─────────┴──────────┐
                       ▼                    ▼
            NavigationControllerRouter   SpyRouter
                  (production)            (tests)
```

Principle: *high-level application logic owns application flow; system-specific
lifecycle code stays at the edge.* `SceneDelegate` is the edge. `AppCoordinator`
is the flow. The route enum is the contract between them.

### Files

```
AppLinksAndRoutingSample/
├── SceneDelegate.swift          Forwards 4 system callbacks to AppCoordinator
├── AppCoordinator.swift         Owns routing + RouteNavigating + dedup
├── DeepLinkRoute.swift          Enum + URL parsing (custom + universal in one switch)
├── HomeViewController.swift     Destination
├── ProductViewController.swift  Destination
├── OrderViewController.swift    Destination
└── Info.plist                   Registers `applinksdemo://` under CFBundleURLTypes
```

## URL shapes & parsing

Two URL shapes carry the routing information in different places:

- Custom scheme: `applinksdemo://product/123` — host = `product`, path = `/123`
- Universal link: `https://example.com/product/123` — host = `example.com`, path = `/product/123`

A naive parser that switches on `URL.host` works for the first but silently
rejects every universal link. `DeepLinkRoute` normalizes both shapes into a
**token list** (for `https`/`http`: path components only; for custom schemes:
host prepended to path components), then matches with a single switch. One
parser, two URL families.

Routes recognized:

| Tokens | Route |
|---|---|
| `["home"]` | `.home` |
| `["product", id]` | `.product(id:)` |
| `["order", id]` | `.order(id:)` |

## Trying it out

The app starts on a Home screen. Trigger routes from a running simulator with:

```sh
xcrun simctl openurl booted applinksdemo://home
xcrun simctl openurl booted applinksdemo://product/123
xcrun simctl openurl booted applinksdemo://order/abc
```

These exercise the **custom-scheme** entry points. Kill the app between
invocations to verify the cold-start path through `willConnectTo`.

### Universal links — additional setup

The `https://…` code path is wired but iOS won't deliver universal links to
the app until you do the following (canonical reference in the header comment
of `SceneDelegate.swift`):

1. **Associated Domains capability** — Target → Signing & Capabilities → "+" →
   *Associated Domains*. Add an entry like `applinks:yourdomain.com`.
2. **Host an `apple-app-site-association` file** at
   `https://yourdomain.com/.well-known/apple-app-site-association`, served as
   `application/json`, no redirects, valid TLS. Body:
   ```json
   {
     "applinks": {
       "details": [{
         "appID": "TEAMID.com.your.bundleid",
         "paths": ["/home", "/product/*", "/order/*"]
       }]
     }
   }
   ```
3. **Reinstall the app** — iOS fetches AASA on first install / subsequent updates.
4. **Test** by tapping a matching `https://` URL in Mail/Notes/Safari, or
   `xcrun simctl openurl booted https://yourdomain.com/product/123` (only
   triggers the universal-link path if AASA is installed correctly).

## Deduplication

`AppCoordinator` keeps a `Set<DeepLinkRoute>` of routes already handled and
silently drops repeats. This is intentional — iOS can deliver the same route
twice in quick succession (cold start through `connectionOptions` followed
immediately by a warm-start callback for the same URL) and we don't want to
push the destination twice.

It's reasonable **while a route value fully identifies the destination**. It
will not survive contact with quick actions or Intents (legitimate
fire-the-same-thing-repeatedly semantics). When that step lands we'll swap
the set for one of: short-lived "cold-start handled" flag, per-event token,
or idempotency-at-the-navigation-layer. See `ROADMAP.md` for the open
discussion.

## Testing

Swift Testing (per project convention; see `CLAUDE.md`). Two suites:

- **`DeepLinkRouteTests`** — pure parsing. Verifies custom-scheme and
  universal-link URLs produce the same enum values (proves token
  normalization), and that malformed URLs return `nil`.
- **`AppCoordinatorTests`** — uses a `SpyRouter` (a `RouteNavigating`
  conformance that records calls) to assert routing decisions without
  involving UIKit. Covers parsing→dispatch wiring, `NSUserActivity` filtering,
  and the dedup behavior.

Run:

```sh
xcodebuild -scheme AppLinksAndRoutingSample test
```

Or in Xcode: ⌘U.

## Sources & references

- **[How to Implement Deep Link and ShortcutItems When Using SceneDelegate](https://www.jakehao.com/scene-delegate-open-url)** — origin of the two-entry-point pattern (cold start via `connectionOptions`, warm start via the dedicated callbacks). The architecture here largely mirrors this article.
- **[Apple — Add Home Screen quick actions](https://developer.apple.com/documentation/uikit/add-home-screen-quick-actions)** — the canonical Apple sample for scene-based quick actions. Used as the template for the *next* step in the roadmap.
- **[MarcoPolo — `ExampleTests.swift`](https://github.com/HelioMesquita/MarcoPolo/blob/main/ExampleTests/ExampleTests.swift)** — protocol-mock testing pattern. We apply the same idea at the `RouteNavigating` seam instead of `UIApplication`.

See `ROADMAP.md` for in-progress questions, decisions log, and what's planned next.
