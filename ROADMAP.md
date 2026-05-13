# Roadmap — internal

Working document for what's done, what's next, and what's still being decided. Not user-facing — that's `README.md`. Keep entries short; link out for detail.

---

## Status

### Done
- **Scene-based deep-link plumbing.** `SceneDelegate` forwards cold-start (`willConnectTo` connectionOptions) and warm-start (`openURLContexts`, `continue userActivity`) into a single `AppCoordinator`.
- **Routing model.** `DeepLinkRoute` enum + URL initializer with **token normalization** so one switch handles both `applinksdemo://…` and `https://…` shapes.
- **Three demo destinations.** `HomeViewController`, `ProductViewController(productID:)`, `OrderViewController(orderID:)`.
- **Custom-scheme registration.** `applinksdemo` in `CFBundleURLTypes`.
- **Programmatic root.** Dropped `UISceneStoryboardFile`; removed template `ViewController.swift` and `Main.storyboard`.

### In progress
- Coordinator testability refactor (`RouteNavigating` protocol + `NavigationControllerRouter`).
- Unit tests (parsing + routing decisions via spy).
- `README.md` (user-facing).

### Next (planned)
1. **Home Screen quick actions.** Apple's sample pattern: save `connectionOptions.shortcutItem` on cold start, replay in `sceneDidBecomeActive`; handle warm start via `windowScene(_:performActionFor:completionHandler:)`. Funnel both into the coordinator as a new route family (or as a sibling concept — TBD, see open questions).
2. **App Intents** (preferred over legacy SiriKit Intents — iOS 16+). Each intent's `perform()` should resolve to the same `DeepLinkRoute` set so the routing core stays single-sourced.
3. **Universal links — end-to-end verifiable.** Requires Associated Domains entitlement + AASA on a real domain. Code path already wired; only setup remains.

---

## Decisions log (short rationale)

| Decision | Why |
|---|---|
| Single `AppCoordinator` owns routing & dedup | Discussion essentials guidance: "high-level application logic should own application flow, while system-specific lifecycle code stays at the edge." Keeps SceneDelegate trivial; survives a multi-scene or SwiftUI move. |
| Token-normalized URL parsing (one switch for both schemes) | Discussion essentials code matched on `components.host`, which silently rejects every universal-link URL (host = the domain, not the route type). Normalizing to a token list keeps one parser. |
| Programmatic root (no Main.storyboard) | Discussion essentials does it programmatically; storyboard would add an extra hop without value here. |
| `Set<DeepLinkRoute>` dedup (lifetime-of-scene) | Faithful to discussion essentials. Reasonable while a route value fully identifies the destination. See open question below. |
| Swift Testing for unit tests | Matches project stub and project CLAUDE.md guidance ("Use the Testing framework for unit tests"). MarcoPolo uses XCTest; the protocol-mock pattern transfers either way. |
| Protocol seam at `RouteNavigating` (not `UINavigationController`) | Coarsest useful boundary. Lets tests assert routing *decisions* without mocking UIKit internals. |

---

## Open questions

- **Dedup strategy will break for quick actions / Intents.** A user can legitimately tap the same quick action repeatedly; an Intent can fire the same route with different state. Options when we get there:
  - Replace `Set<DeepLinkRoute>` with a short-lived "cold-start handled" flag (only dedupes the willConnectTo↔openURLContexts double-delivery window).
  - Tag each incoming event with a token (event ID / timestamp) and dedupe per-token, not per-route.
  - Drop dedup entirely and rely on the coordinator's idempotency at the navigation layer (e.g. don't push a duplicate VC if it's already on top).
  - **Decision deferred** until we add the first non-deep-link entry point.

- **Quick actions: route family vs sibling concept?**
  - (a) Add cases to `DeepLinkRoute` (e.g. `.search`, `.share`, `.favoriteContact(id:)`). Single dispatch, simple.
  - (b) Introduce a higher-level `AppAction` that subsumes both `DeepLinkRoute` and `ShortcutAction`. Cleaner separation, more code.
  - Leaning (a) for now; revisit when Intents land (they may push us toward (b) anyway).

- **Universal-link entitlement placeholder.** Currently no entitlement at all. Worth pre-adding a placeholder `applinks:example.com` so the capability is visible in the project, even if the AASA isn't real? Risk: confusing if reader assumes it works. Lean against until we have a real domain.

- **Static quick actions in Info.plist?** Apple's sample sets *dynamic* items in `sceneWillResignActive`. Static `UIApplicationShortcutItems` in Info.plist are simpler to demo. Probably want both: one static (proves the plist path), some dynamic (proves the runtime path).

- **App Intents vs SiriKit Intents.** App Intents is the modern path (iOS 16+). Unless we want to demo legacy donation flows, App Intents is the call.

---

## Ideas / parking lot

- A `UITests` flow that drives the simulator with `xcrun simctl openurl` and asserts the right screen is on top. Would prove the whole stack end-to-end, not just the parser+dispatcher.
- Add a one-line `os_log` (or `Logger`) trace in the coordinator for every incoming URL/activity and every navigation. Helpful for debugging cold-start delivery ordering.
- A tiny in-app debug menu that lets you fire any route manually — useful while building Intents/quick actions when the simulator's openurl is too slow a loop.

---

## References

Sources used for architectural choices (also surfaced in `README.md` for outside readers, but anchored here too):

- **[How to Implement Deep Link and ShortcutItems When Using SceneDelegate](https://www.jakehao.com/scene-delegate-open-url)** — source of the two-entry-point pattern (cold-start in `willConnectTo` connectionOptions, warm-start in `openURLContexts`).
- **[Apple — Add Home Screen quick actions](https://developer.apple.com/documentation/uikit/add-home-screen-quick-actions)** (sample in `AddHomeScreenQuickActions.zip`) — pattern for `connectionOptions.shortcutItem` save+replay and `windowScene(_:performActionFor:)`. Mirror structure for step 2.
- **[MarcoPolo — ExampleTests.swift](https://github.com/HelioMesquita/MarcoPolo/blob/main/ExampleTests/ExampleTests.swift)** — protocol-mock test pattern (mock the boundary, assert calls). We apply the same idea at the `RouteNavigating` seam.
- **iOS Application Architecture (Srdan Stanic)** — "high-level application logic should own application flow, while system-specific lifecycle code stays at the edge" — the principle behind keeping SceneDelegate thin.
