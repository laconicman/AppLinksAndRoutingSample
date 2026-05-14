//
//  SceneDelegate.swift
//  AppLinksAndRoutingSample
//

import UIKit

// MARK: - Setup Notes
//
// Custom-scheme deep links (already wired):
//   `applinksdemo` is registered under `CFBundleURLTypes` in Info.plist.
//   Cold-start arrives via `connectionOptions.urlContexts` in `willConnectTo`.
//   Warm-start arrives via `scene(_:openURLContexts:)`.
//   Test:  xcrun simctl openurl booted applinksdemo://product/2
//
// Universal links — the `scene(_:continue:)` and connectionOptions paths below
// are already wired. iOS won't actually deliver them until you:
//   1. Enable the "Associated Domains" capability (Signing & Capabilities tab).
//   2. Add an `applinks:yourdomain.com` entry to the Associated Domains list.
//   3. Host an `apple-app-site-association` JSON file at
//      `https://yourdomain.com/.well-known/apple-app-site-association`,
//      served as `application/json` (no redirects, valid TLS). Example:
//        {
//          "applinks": {
//            "details": [{
//              "appID": "TEAMID.com.your.bundleid",
//              "paths": ["/home", "/product/*", "/order/*"]
//            }]
//          }
//        }
//   4. Reinstall the app — iOS fetches AASA on install and on updates.
//
// Home Screen quick actions (already wired):
//   Two static actions are declared under `UIApplicationShortcutItems` in
//   Info.plist. Cold-start arrives via `connectionOptions.shortcutItem`; warm
//   start arrives via `windowScene(_:performActionFor:completionHandler:)`.
//   Test by long-pressing the app icon on the Home Screen.

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
            coordinator.process(url: url)
        }

        // Cold-start: universal link (or other handoff activity).
        if let activity = connectionOptions.userActivities.first {
            coordinator.process(userActivity: activity)
        }

        // Cold-start: Home Screen quick action.
        if let shortcutItem = connectionOptions.shortcutItem {
            coordinator.process(shortcutItem: shortcutItem)
        }
    }

    // Warm-start: custom-scheme URL.
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        coordinator.process(url: url)
    }

    // Warm-start: universal link continuation.
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        coordinator.process(userActivity: userActivity)
    }

    // Warm-start: Home Screen quick action.
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        coordinator.process(shortcutItem: shortcutItem)
        completionHandler(true)
    }
}
