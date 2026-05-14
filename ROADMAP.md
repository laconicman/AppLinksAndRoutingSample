# Roadmap — internal

Working document for what's done, what's next, and what's still being decided. Not user-facing — that's `README.md`. Keep entries short; link out for detail.

---

## Status

### Done
- **Scene-based deep-link plumbing.** `SceneDelegate` forwards all 5 system callbacks (3 cold-start via `connectionOptions`, 3 warm-start via dedicated callbacks; URL + userActivity + shortcutItem) into a single `AppCoordinator`.
- **Routing model.** `DeepLinkRoute` enum + three overloaded initializers (factory family on the route type, not a separate class): `init?(url:)`, `init?(userActivity:)`, `init?(shortcutItem:)`. All three delegate to `init?(url:)` so the URL parser is the single source of truth.
- **Token-normalized URL parsing.** One switch handles both `applinksdemo://…` and `https://…` shapes.
- **Tab bar architecture.** `MainTabBarController` with Home / Products / Orders tabs, each in its own `UINavigationController`. `TabRouter` switches tabs and pushes onto the selected tab's stack.
- **Home Screen quick actions.** Two static items in Info.plist (`Continue Shopping`, `Track Latest Order`) using URL strings as `UIApplicationShortcutItemType` so the routing layer reuses the URL parser.
- **Mock catalog.** `Catalog.swift` with six products and three orders backs both in-app browsing and deep-link destinations.
- **HIG-conformant destination screens.** Grid for products, inset-grouped list for orders, hero+detail layouts on both detail screens, system colors / SF Symbols / dynamic type / safe areas throughout.
- **Tests.** Swift Testing suites for `DeepLinkRoute` parsing (incl. shortcut-item and user-activity adapters) and `AppCoordinator` dispatch via `SpyRouter`. 24 unit tests, all green.
- **MainActor isolation.** `RouteNavigating`, `TabRouter`, `AppCoordinator`, `DeepLinkRouting` are `@MainActor`. Modern Concurrency shows up as isolation annotations rather than async pipelines (see decisions log).

### Next (planned)
1. **App Intents.** iOS 16+ (modern path; legacy SiriKit Intents not pursued). Each intent's `perform()` should resolve to the same `DeepLinkRoute` set so routing stays single-sourced. Likely adds `init?(intent:)` (a fourth factory adapter on the route enum).
2. **Push & local notification handling.** Route taps on notifications through the same coordinator / factory pipeline. Details in the section below — has its own design questions to resolve.
3. **Universal links — end-to-end verifiable.** Code path already wired; only setup remains. Requires Associated Domains entitlement + AASA on a real domain.
4. **Dynamic quick actions.** Runtime `UIApplication.shared.shortcutItems = …` in `sceneWillResignActive` once we have real "recent items" worth promoting (likely after Intents land).

---

## Planned step: Push & local notifications

### Goal
Tapping a remote-push notification or a delivered local notification opens the same destination a deep link would, with the same routing core. No parallel grammar for notification payloads.

### Sketch
- **Input adapter (the factory family stays single-sourced).** Add `init?(notificationResponse: UNNotificationResponse)` to `DeepLinkRoute`. Convention: encode the destination as a URL string in the notification's `userInfo` (e.g. `userInfo["link"] = "applinksdemo://order/1001"`). The adapter pulls that string, makes a `URL`, and delegates to `init?(url:)`. Same trick we used for `UIApplicationShortcutItem.type`.
- **Entry point.** `UNUserNotificationCenter` is **app-level**, not scene-level — `UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)` lives on `AppDelegate` (or a separate delegate object owned by it). On single-scene apps that just forwards to *the* coordinator. On multi-scene apps (we're not multi-scene today; see Open Questions) the AppDelegate has to decide which scene's coordinator gets the route — non-trivial.
- **Cold-start case.** If the app is killed and the user taps a notification, the action arrives in `application(_:didFinishLaunchingWithOptions:)` via `launchOptions[.remoteNotification]` (or for local notifications, `UNUserNotificationCenter` re-delivers the response after `didFinishLaunching`). Need to buffer until the scene's `AppCoordinator` exists, then drain.
- **Permission flow.** Out of scope for the routing test but worth a small `NotificationsPermissionRequester` so the demo isn't broken end-to-end.
- **Local notification trigger.** Tiny in-app button on the Home tab ("Notify me in 10s") that schedules a local notification with a `userInfo["link"]` payload — best way to demo the path without a real APNs setup.

### Design questions to resolve when we get there

| Question | Notes |
|---|---|
| AppDelegate → SceneDelegate handoff | How does the app-level notification delegate find the right `AppCoordinator`? With single-scene this is trivial. Multi-scene needs explicit decision (most-recent-active scene? all scenes? user prompt?). |
| Cold-start buffering | Should `AppDelegate` hold an optional pending `URL`/`Route` until the scene wires up its coordinator? Or should each `SceneDelegate.willConnectTo` ask the AppDelegate "is there a pending notification route?". |
| Payload contract | Stick with `userInfo["link"] = "applinksdemo://…"` (string-URL, reuses our parser) or design a richer payload (`{"type":"order","id":"1001"}`)? URL-string is simpler and keeps everything single-sourced; richer payload buys nothing until we have non-URL-shaped actions. |
| Foreground notification presentation | Do we present banners while in foreground (`willPresent` returning `[.banner]`) or suppress them? Default: present them, since the demo benefits from showing the system UI. |
| Re-evaluate child coordinators | Notifications start to introduce app-level state (delegate, permission, cold-start buffer) that lives outside the scene-scoped coordinator. May tip the cost/benefit toward a small `AppRootCoordinator` (app-lifecycle) + the current scene-level `AppCoordinator` as its child. See Library options below. |

### Library / pattern options to evaluate

These are options to consider *when* we tackle this step — not a decision now. Each is a different sized commitment.

| Option | Fit for our context | Notes |
|---|---|---|
| **Keep current minimal coordinator, extend it** | High | Smallest delta. Adds an `AppRootCoordinator` that owns notification delegate + cold-start buffer and forwards to a scene-scoped `AppCoordinator` (which becomes its child). See "Patterns to borrow from HWS" below for specifics. |
| **[Navigator (hmlongco)](https://github.com/hmlongco/Navigator)** | **Low** — SwiftUI-only (iOS 16+/17+), no UIKit support. Would only fit if we add a SwiftUI target. Useful for the *idea* of `navigationSend()` as a broadcast bus (tab switch then drill-in), which we could replicate ourselves. |
| **[NavigationStack (WWDC22)](https://developer.apple.com/videos/play/wwdc2022/10054/)** | **Low** — SwiftUI-only. Same caveat. Worth referencing for the path-binding pattern (deep links mutate a single path) if we ever migrate. |
| **[TCA (point-free)](https://github.com/pointfreeco/swift-composable-architecture)** | Medium | Cross-platform (incl. UIKit). Big framework, opinionated state/action/reducer/store model. Push handling would be modeled as Effects feeding actions; navigation through their Navigation article's patterns. Justified only if we also adopt TCA for app state — adopting it just for routing is overkill. |
| **xcresource + custom Xcode templates** | Tangential | The Obsidian [Enhance Xcode snippets using Git](https://fabernovel.github.io/2021-07-22/enhance-xcode-snippets-using-git) note describes distributing reusable code via xcresource. Not relevant to push handling itself, but if we publish this routing pattern as a starter, an xcresource template would be the delivery vehicle. Parking lot. |

### Patterns to borrow from HWS (if we extend the current coordinator)

The [HWS advanced coordinators article](https://www.hackingwithswift.com/articles/175/advanced-coordinator-pattern-tutorial-ios) is UIKit-native and directly applicable. Concrete pieces to pick up — and pieces to skip — when introducing the `AppRootCoordinator` → `AppCoordinator` split:

- **Adopt: `Coordinator: AnyObject` constraint** + `childCoordinators: [Coordinator]` array on the parent. (We already have `RouteNavigating: AnyObject`; the parent role is the new bit.)
- **Adopt: parent reference + cleanup callback.** `weak var parentCoordinator: AppRootCoordinator?` on `AppCoordinator`; `childDidFinish(_:)` on the parent removes the entry from its `childCoordinators` array using the `===` identity check. Avoids a "stack-of-coordinators" model in favor of a tree where any child can finish independently.
- **Skip (for now): the `UINavigationControllerDelegate.didShow` Khanlou trick** for back-detection. It earns its keep when a child coordinator pushes a *sequence* of view controllers and needs to clean up on a back tap mid-flow. Our scene-level coordinator only pushes leaf detail VCs from a deep link; there's no mid-flow back to detect. Pull this in when (and only when) we add a multi-step flow (e.g. checkout, onboarding).
- **Skip (for now): one-coordinator-per-tab.** HWS recommends a `Coordinator` per tab; we currently route all tabs through a single `TabRouter`. Worth re-evaluating *only* when a single tab grows internal routing logic worth isolating (per-tab dependencies, sub-flows). Until then, splitting is scaffolding.
- **Already doing: protocols over a generic `delegate` name.** Our `RouteNavigating` protocol is the same idea Hudson recommends — specialized delegate with a name that signals its role.
- **Consider: closures for child→parent "finished" signaling.** HWS notes closures suit "one or two callbacks" better than a protocol. The `AppRootCoordinator` → `AppCoordinator` relationship may only need a single `onFinished: (() -> Void)?` callback, in which case a protocol is overkill. Default to closure unless we end up with three or more callbacks.
- **Skip: storyboard segues.** Already follow this — everything programmatic.

### Tests to plan
- `DeepLinkRoute(notificationResponse:)` parsing — valid `userInfo["link"]`, missing key, malformed URL.
- `AppCoordinator.process(notificationResponse:)` dispatch via `SpyRouter` (mirror the shortcut-item tests).
- AppDelegate cold-start buffering: launch options with `.remoteNotification` should result in one route once the scene wires up.
- If we split coordinators: `AppRootCoordinator` test that asserts `childCoordinators` is emptied via `childDidFinish(_:)` (mirrors the HWS pattern).

---

## Decisions log

| Decision | Why |
|---|---|
| Single `AppCoordinator` owns routing | Discussion essentials guidance: high-level application logic owns flow; system-specific lifecycle stays at the edge. |
| Token-normalized URL parsing | Discussion essentials parser matched on `URL.host`, which silently rejects every universal-link URL. Normalizing to a token list keeps one parser. |
| Factory pattern via overloaded inits on `DeepLinkRoute` (not a separate `RouteFactory` class) | Preserves factory-pattern intent without introducing an extra type. Each new input source adds one init; the canonical URL parser stays single-sourced. |
| `TabRouter` is the only `RouteNavigating` impl; **no child coordinators** | 3 flat routes, no per-tab routing logic worth isolating. Children would be scaffolding. The `RouteNavigating` seam already gives us the protocol surface to split into children later when there's actual per-tab logic (e.g. product → review → reviewer profile). |
| **No AsyncStream pipeline.** Single-consumer producer (SceneDelegate) and single-consumer consumer (TabRouter) are both `@MainActor`. A stream between two `@MainActor` callers adds task lifecycle + scheduling latency for no functional gain. | Bartlett's pipeline shines when producers/consumers are decoupled across actors or have legitimate fan-out. Neither applies here. Modern Concurrency still shows up as `@MainActor` annotations. |
| **No SPM dependency.** swift-async-algorithms not needed (no stream); coordinator libraries (XCoordinator etc.) too heavy for 3 routes. | YAGNI. Reconsider when there's a concrete use (e.g. real async chains, multicast). Validated by Khanlou ("Coordinators Redux"): *"There's no library you can use for coordinators because they're so simple."* |
| **List view controllers push detail VCs directly** rather than calling back to a coordinator. Deviation from strict Khanlou orthodoxy ("view controllers never instantiate subsequent view controllers"). | The coordinator surface is reserved for *external* entry points (deep links, universal links, quick actions, future intents/pushes). In-app browsing taps go straight through UIKit because adding a `weak var coordinator` + protocol + assignment for two list VCs doing one push each doesn't earn its keep at this scope. Revisit if a tap needs to do *anything* beyond push a detail (analytics, permission check, prerequisite flow). |
| Dropped lifetime-of-scene `Set<DeepLinkRoute>` dedup | Quick actions are legitimately repeatable (open ROADMAP question now closed). `TabRouter` pops-to-root before pushing a detail, so navigation state matches the route exactly on every delivery — that's idempotency at the navigation layer, which is what we actually wanted. |
| Single-section diffable snapshots typed `Int` not `enum Section { case main }` | `@MainActor` view controllers caused nested enum Hashable conformances to be main-actor-isolated, breaking `Sendable` requirement of `NSDiffableDataSourceSnapshot`'s `SectionIdentifierType`. `Int` sidesteps it for the trivial single-section case. |
| Swift Testing for unit tests | Matches project stub and CLAUDE.md guidance. Spy pattern transfers cleanly from XCTest. |

---

## Open questions

- **App Intents shape.** Will `init?(intent:)` adequately cover every Intent shape, or will some intents express routing decisions that don't fit `DeepLinkRoute`? Likely fine for navigation-style intents; opaque for transactional ones ("place this order"). May need a sibling `AppAction` type if non-navigation intents arrive.
- **Multiple scene support.** `UIApplicationSupportsMultipleScenes` is `false`. The coordinator is currently scene-scoped (created per `SceneDelegate`). If we ever flip multi-scene on, each scene gets its own router, which is fine — but a single `applinksdemo://` URL would only target the most-recent active scene. Worth thinking through before flipping the switch.

---

## Notes for future selves

Forward-looking principles to apply when iterating — not decisions yet, just things to remember to consider before reaching for an older pattern.

- **Prefer `await` over completion handlers.** Many APIs that historically required a completion closure now have `async` variants (Foundation, UserNotifications, URLSession, etc.); anything that doesn't can usually be wrapped with `withCheckedContinuation`. When extending or refactoring, default to the async version. Specifics for our likely future surface:
  - `UNUserNotificationCenter.requestAuthorization(options:)` and `add(_:)` are already `async`. Use those directly — no completion-handler peer needed.
  - `userNotificationCenter(_:didReceive:withCompletionHandler:)` still has a completion in its delegate signature, but its body can be `Task { await coordinator.process(notificationResponse: response); completionHandler() }` — we get async ergonomics inside, and the delegate contract stays the way UIKit defined it.
  - Khanlou's "viewDidDisappear → parent-finish" pattern could be modeled as an `AsyncStream` of lifecycle events. Almost certainly overkill at our scope, but worth knowing the option exists before reflexively reaching for the delegate-method version.
  - Our own `ProductViewController.presentToast(_:)` uses `DispatchQueue.main.asyncAfter`. If we ever revisit it, `Task { try? await Task.sleep(for: .seconds(0.9)); alert.dismiss(...) }` reads better. Not worth touching for its own sake.


---

## Ideas / parking lot

- A UITests flow that drives the simulator with `xcrun simctl openurl` and asserts the right tab/screen is on top. Would prove the whole stack end-to-end. (XCUIAutomation per CLAUDE.md.)
- A small `Logger` trace in `AppCoordinator.process(...)` and `TabRouter.navigate(to:)` for debugging cold-start delivery ordering.
- An in-app debug menu to fire any route manually — useful while building Intents.

---

## References

- **[How to Implement Deep Link and ShortcutItems When Using SceneDelegate](https://www.jakehao.com/scene-delegate-open-url)** — origin of the two-entry-point pattern (cold start via `connectionOptions`, warm start via dedicated callbacks). The SceneDelegate shape mirrors this.
- **[Apple — Add Home Screen quick actions](https://developer.apple.com/documentation/uikit/add-home-screen-quick-actions)** — Apple sample for scene-based quick actions. `connectionOptions.shortcutItem` cold start + `windowScene(_:performActionFor:)` warm start pattern.
- **[MarcoPolo — `ExampleTests.swift`](https://github.com/HelioMesquita/MarcoPolo/blob/main/ExampleTests/ExampleTests.swift)** — protocol-mock testing pattern. We apply it at the `RouteNavigating` seam.
- **[Deep linking iOS — moderateepheezy gist](https://gist.github.com/moderateepheezy/af9b41460629dcb69f5ececa1fa58912)** — factory pattern for routing multiple input shapes (URL, push) into one canonical action. We adopted the *intent* via overloaded inits rather than a separate factory class.
- **[Handle Deep Links with Async Algorithms — Jacob Bartlett](https://blog.jacobstechtavern.com/p/deep-links-with-async-algorithms)** — AsyncChannel-per-route pipeline. We considered, then rejected, because single-consumer-on-both-sides eliminates the architectural pressure that made his design earn its keep. Useful reference if we ever genuinely need multicast routing.
- **iOS Application Architecture (Srdan Stanic)** — the "edge/flow" separation principle behind keeping SceneDelegate thin.
- **[Khanlou — "The Coordinator"](http://khanlou.com/2015/01/the-coordinator/)** (2015) — origin of the coordinator pattern in iOS. Establishes the core motivation: extracting flow logic from view controllers so VCs become reusable units that just bind models to views. Frames coordinators as a PONSO (plain old non-special object) that owns navigation, creates VCs, and acts as their delegate.
- **[Khanlou — "Coordinators Redux"](http://khanlou.com/2015/10/coordinators-redux/)** (2015) — the foundational refinement. Two key things we lean on: (a) coordinators handle *navigation and model mutation*, leaving VCs inert — the latter half is what we'll honor when "Add to Cart" actually does something; (b) "*There's no library you can use for coordinators because they're so simple*" — direct validation of our no-SPM stance. Also introduces the `start()` method shape and the child-coordinator array we'll reach for during the push/notifications step.
