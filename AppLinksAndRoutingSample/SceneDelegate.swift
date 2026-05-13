//
//  SceneDelegate.swift
//  AppLinksAndRoutingSample
//

import UIKit

// MARK: - Setup Notes
//
// Custom-scheme deep links (already wired):
//   1. `applinksdemo` is registered under `CFBundleURLTypes` in Info.plist.
//   2. Test from a running simulator with:
//        xcrun simctl openurl booted applinksdemo://home
//        xcrun simctl openurl booted applinksdemo://product/123
//        xcrun simctl openurl booted applinksdemo://order/abc
//      Cold-start (app not running): URL arrives in `connectionOptions.urlContexts`
//      below. Warm-start: URL arrives in `scene(_:openURLContexts:)`.
//
// Universal links (https://) — the `scene(_:continue:)` code path below is
// already wired. To make iOS actually deliver universal links to the app you
// additionally need:
//
//   1. Enable the "Associated Domains" capability for the app target in Xcode
//      (Signing & Capabilities tab > "+" > Associated Domains).
//   2. Add entries like `applinks:yourdomain.com` (one per host) to the
//      Associated Domains list. This writes the entitlement into the target.
//   3. Host an `apple-app-site-association` JSON file at
//      `https://yourdomain.com/.well-known/apple-app-site-association`
//      served as `application/json` (no redirects, valid TLS). Example body:
//
//        {
//          "applinks": {
//            "details": [{
//              "appID": "TEAMID.com.your.bundleid",
//              "paths": ["/home", "/product/*", "/order/*"]
//            }]
//          }
//        }
//
//   4. Reinstall the app — iOS fetches AASA once on first install and on
//      subsequent updates. Tap a matching https link in Mail/Notes/Safari, or
//      use: `xcrun simctl openurl booted https://yourdomain.com/product/123`
//      (note: simctl with an https URL only triggers the universal-link path
//      if AASA is correctly installed; otherwise Safari opens instead).
//
// Cold-start universal links land in `connectionOptions.userActivities` (handled
// in `willConnectTo` below); warm-start universal links land in
// `scene(_:continue:)`. Both funnel through `AppCoordinator.handleUserActivity`.

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let coordinator = AppCoordinator()

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        coordinator.start(in: window)

        // Cold-start: custom-scheme URL passed in at launch.
        if let url = connectionOptions.urlContexts.first?.url {
            coordinator.handleDeepLink(url)
        }

        // Cold-start: universal link (or other handoff user activity) passed in at launch.
        if let activity = connectionOptions.userActivities.first {
            coordinator.handleUserActivity(activity)
        }
    }

    // Warm-start: custom-scheme URL while the scene is already connected.
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        coordinator.handleDeepLink(url)
    }

    // Warm-start: universal link continuation while the scene is already connected.
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        coordinator.handleUserActivity(userActivity)
    }
}
