# AppLinksAndRoutingSample

A reference sample for a **scene-based UIKit app** that handles app-links
cleanly across all the entry points iOS can deliver them through, with a
tab-bar shell that looks like a real shopping app. Built incrementally — the
current cut covers **custom-scheme deep links**, **universal links**, and
**Home Screen quick actions**, all funneling through one routing core. App
Intents are planned next; see [`ROADMAP.md`](./ROADMAP.md).

## What's in the app

```
┌───────────────────────────────────────────────────┐
│                  MainTabBarController             │
│ ┌─────────┐  ┌──────────────┐  ┌───────────────┐  │
│ │  Home   │  │   Products   │  │    Orders     │  │
│ │  (nav)  │  │    (nav)     │  │    (nav)      │  │
│ └─────────┘  └──────────────┘  └───────────────┘  │
└───────────────────────────────────────────────────┘
```

- **Home tab** — Welcome screen + an in-app cheat sheet listing the URLs and
  quick actions that exercise every routing entry point. Doubles as live
  documentation while running the sample.
- **Products tab** — Two-column grid (compositional layout + diffable data
  source) of six mock products with SF Symbol icons. Tap pushes a rich detail
  screen.
- **Orders tab** — Inset-grouped list of three mock orders. Status pills
  (orange/blue/green for Processing/Shipped/Delivered), relative-date subtitle,
  detail screen with line-items card and total.

All destination screens (`ProductViewController`, `OrderViewController`) are
reached from **both** in-app navigation (tapping a list cell) and the routing
layer (deep link, universal link, quick action). Both paths converge.

## Scope (routing entry points)

| Entry point | Cold start (app not running) | Warm start (already running) |
|---|---|---|
| Custom-scheme URL (`applinksdemo://…`) | `scene(_:willConnectTo:options:)` → `connectionOptions.urlContexts` | `scene(_:openURLContexts:)` |
| Universal link (`https://…`) | `scene(_:willConnectTo:options:)` → `connectionOptions.userActivities` | `scene(_:continue:)` |
| Home Screen quick action | `scene(_:willConnectTo:options:)` → `connectionOptions.shortcutItem` | `windowScene(_:performActionFor:completionHandler:)` |

All six rows funnel into the same `AppCoordinator`.

## Architecture

```
                 ┌──────────────────────────────┐
   system  ───►  │         SceneDelegate        │     thin: parameter-passing
  callbacks      │  (6 entry points, no logic)  │     only
                 └───────────────┬──────────────┘
                                 │ .process(url:|userActivity:|shortcutItem:)
                                 ▼
                 ┌──────────────────────────────┐
                 │  AppCoordinator (@MainActor) │     thin: parse + dispatch
                 │                              │
                 │   URL ─┐                     │
                 │   NSUA ┼─► DeepLinkRoute     │     factory family
                 │   Item─┘   (3 overloaded     │     on the route type
                 │             inits)           │
                 └───────────────┬──────────────┘
                                 │ navigate(to:)
                                 ▼
                 ┌──────────────────────────────┐
                 │ RouteNavigating  (@MainActor)│     test seam
                 └───────────────┬──────────────┘
                                 │
                       ┌─────────┴──────────┐
                       ▼                    ▼
                   TabRouter             SpyRouter
                  (production)            (tests)
                       │
                       ▼
                MainTabBarController
                  (3 nav stacks)
```

### Principles

- **`SceneDelegate` is the edge, `AppCoordinator` is the flow.** Lifecycle
  callbacks parameter-pass into the coordinator; the coordinator owns every
  routing decision. Survives swaps to a different shell (multi-scene, SwiftUI
  target) without rewriting routing.
- **Factory family on the route enum.** Instead of a separate `RouteFactory`
  class, `DeepLinkRoute` exposes overloaded initializers: `init?(url:)`,
  `init?(userActivity:)`, `init?(shortcutItem:)`. Each adapter delegates to
  `init?(url:)`, so the URL parser is the single source of truth. Adding a new
  input (App Intent, push notification) means adding one more init.
- **No child coordinators yet.** With three flat routes and one VC per tab,
  child coordinators would be scaffolding. The `RouteNavigating` seam already
  lets us split into per-tab routers when actual per-tab logic appears.
- **No async-stream pipeline.** Both producer (SceneDelegate) and consumer
  (TabRouter) are `@MainActor`. A stream between two `@MainActor` callers adds
  task lifecycle without payload. Modern Concurrency still shows up as
  isolation annotations on the protocols.
- **No SPM dependencies.** Nothing earns its keep at this scale. Reconsider
  when there's a concrete use (e.g. multicast routing, real async chains).

### Files

```
AppLinksAndRoutingSample/
├── SceneDelegate.swift          6 system callbacks → AppCoordinator
├── AppCoordinator.swift         Owns routing; declares RouteNavigating + TabRouter
├── DeepLinkRoute.swift          Enum + factory inits (URL, userActivity, shortcutItem)
├── MainTabBarController.swift   Composes the three tab navs
├── HomeViewController.swift     Welcome + in-app cheat sheet
├── ProductsListViewController.swift   Grid of products (compositional + diffable)
├── OrdersListViewController.swift     Inset-grouped list of orders
├── ProductViewController.swift  Detail (used by tap and by deep link)
├── OrderViewController.swift    Detail (used by tap and by deep link)
├── Catalog.swift                Mock products + orders + formatting helpers
├── SeparatorView.swift          Hairline UIView using `.separator` color
└── Info.plist                   Custom scheme + UIApplicationShortcutItems
```

## URL shapes & parsing

Two URL shapes carry the routing information in different places:

- Custom scheme: `applinksdemo://product/123` — host = `product`, path = `/123`
- Universal link: `https://example.com/product/123` — host = `example.com`, path = `/product/123`

A naive parser that switches on `URL.host` works for the first but silently
rejects every universal link. `DeepLinkRoute` normalizes both into a token list
(for `https`/`http`: path components only; for custom schemes: host prepended
to path components), then matches with a single switch.

Quick actions reuse this: each `UIApplicationShortcutItem.type` is itself a
URL string (e.g. `"applinksdemo://product/1"`), so `init?(shortcutItem:)` is
one line of delegation to `init?(url:)`. No parallel route grammar.

Routes recognized:

| Tokens | Route |
|---|---|
| `["home"]` | `.home` |
| `["product", id]` | `.product(id:)` |
| `["order", id]` | `.order(id:)` |

## Trying it out

The app launches into the **Home tab**. The Home screen lists every URL and
quick action below. From a terminal with the simulator booted:

```sh
xcrun simctl openurl booted applinksdemo://home
xcrun simctl openurl booted applinksdemo://product/2
xcrun simctl openurl booted applinksdemo://order/1001
```

Kill the app between invocations to verify cold-start delivery through
`willConnectTo`.

### Home Screen quick actions

Two static items are registered in `Info.plist`:

- **Continue Shopping** → `applinksdemo://product/1`
- **Track Latest Order** → `applinksdemo://order/1001`

Long-press the app icon on the simulator's Home Screen to use them. (Note: on
the simulator, long-press requires a tiny pause to register vs. on device.)

### Universal links — additional setup

The `https://…` code path is wired but iOS won't deliver universal links to
the app until:

1. **Associated Domains capability** — Target → Signing & Capabilities → "+" →
   *Associated Domains*. Add an entry like `applinks:yourdomain.com`.
2. **Host an `apple-app-site-association` file** at
   `https://yourdomain.com/.well-known/apple-app-site-association`, served as
   `application/json`, no redirects, valid TLS:
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
3. **Reinstall the app** — iOS fetches AASA on install and updates.
4. **Test** by tapping a matching `https://` URL in Mail/Notes/Safari, or
   `xcrun simctl openurl booted https://yourdomain.com/product/123` (only
   triggers the universal-link path if AASA is correctly installed).

Canonical setup notes also live in the header comment of `SceneDelegate.swift`.

## Navigation behavior

`TabRouter` switches to the route's tab and **pops to root before pushing the
detail**. This makes the resulting navigation stack a function of the route
alone — repeated deliveries of the same route land you in the same place, not
on a stack of duplicates. Replaces the earlier lifetime-of-scene
`Set<DeepLinkRoute>` dedup, which broke legitimately-repeatable quick actions.

## Testing

Swift Testing (per project convention; see `CLAUDE.md`). Two suites:

- **`DeepLinkRouteTests`** — pure parsing across all three input shapes (URL,
  NSUserActivity, UIApplicationShortcutItem). Asserts custom-scheme and
  universal-link URLs produce identical enum values (token normalization);
  rejects malformed inputs.
- **`AppCoordinatorTests`** — uses a `SpyRouter` (a `RouteNavigating`
  conformance that records calls) to assert routing decisions without
  involving UIKit's view hierarchy. Covers all three `process(...)` overloads
  and verifies repeated dispatches *do* navigate each time (no dedup).

Run:

```sh
xcodebuild -scheme AppLinksAndRoutingSample test
```

Or in Xcode: ⌘U.

## Sources & references

- **[How to Implement Deep Link and ShortcutItems When Using SceneDelegate](https://www.jakehao.com/scene-delegate-open-url)** — origin of the two-entry-point pattern (cold start via `connectionOptions`, warm start via dedicated callbacks).
- **[Apple — Add Home Screen quick actions](https://developer.apple.com/documentation/uikit/add-home-screen-quick-actions)** — Apple sample for scene-based quick actions; pattern for `connectionOptions.shortcutItem` + `windowScene(_:performActionFor:)`.
- **[MarcoPolo — `ExampleTests.swift`](https://github.com/HelioMesquita/MarcoPolo/blob/main/ExampleTests/ExampleTests.swift)** — protocol-mock testing pattern. Applied here at the `RouteNavigating` seam.
- **[Deep linking iOS — moderateepheezy gist](https://gist.github.com/moderateepheezy/af9b41460629dcb69f5ececa1fa58912)** — factory pattern for routing multiple input shapes into one canonical action. Adopted as overloaded inits on the route enum.
- **[Handle Deep Links with Async Algorithms — Jacob Bartlett](https://blog.jacobstechtavern.com/p/deep-links-with-async-algorithms)** — considered AsyncChannel-per-route pipeline; rejected because single-consumer on both sides removed the architectural pressure that earned the design.

See `ROADMAP.md` for in-progress questions, full decisions log, and what's planned next.
