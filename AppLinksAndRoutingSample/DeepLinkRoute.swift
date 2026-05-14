//
//  DeepLinkRoute.swift
//  AppLinksAndRoutingSample
//

import Foundation
import UIKit

/// Canonical route type. Multiple input shapes (URL, NSUserActivity from a
/// universal link, UIApplicationShortcutItem from a Home Screen quick action)
/// all converge here via overloaded initializers — a factory family expressed
/// directly on the route type.
///
/// Each adapter init ultimately delegates to `init?(url:)`, so the URL parser
/// is the single source of truth for route shape. Adding a new input later
/// (App Intent, push notification payload, …) means adding one more init.
///
/// Custom-scheme examples (registered under `CFBundleURLTypes` in Info.plist):
///   applinksdemo://home
///   applinksdemo://product/2
///   applinksdemo://order/1001
///
/// Universal-link examples (require Associated Domains + AASA — see SceneDelegate):
///   https://yourdomain.com/home
///   https://yourdomain.com/product/2
///   https://yourdomain.com/order/1001
enum DeepLinkRoute: Hashable {
    case home
    case product(id: String)
    case order(id: String)

    // MARK: - URL (custom-scheme deep link OR universal link)

    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }

        // Normalize both URL shapes into a single token list so matching is uniform.
        // - https/http (universal link): tokens = path components only.
        // - custom scheme (deep link): tokens = [host] + path components, since the
        //   route type lives in the host (e.g. `applinksdemo://product/123`).
        let tokens: [String]
        let scheme = components.scheme?.lowercased()
        if scheme == "https" || scheme == "http" {
            tokens = Self.pathTokens(components.path)
        } else {
            var combined: [String] = []
            if let host = components.host, !host.isEmpty {
                combined.append(host)
            }
            combined.append(contentsOf: Self.pathTokens(components.path))
            tokens = combined
        }

        guard let head = tokens.first else { return nil }
        let rest = Array(tokens.dropFirst())

        switch (head, rest) {
        case ("home", []):
            self = .home
        case ("product", let parts) where parts.count == 1:
            self = .product(id: parts[0])
        case ("order", let parts) where parts.count == 1:
            self = .order(id: parts[0])
        default:
            return nil
        }
    }

    // MARK: - NSUserActivity (universal-link continuation)

    /// Routes from an `NSUserActivity`. Only `NSUserActivityTypeBrowsingWeb`
    /// activities with a `webpageURL` produce a route; other activity types
    /// are ignored (caller responsibility to forward them elsewhere if needed).
    init?(userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return nil }
        self.init(url: url)
    }

    // MARK: - UIApplicationShortcutItem (Home Screen quick action)

    /// Routes from a Home Screen quick action. The shortcut's `type` is
    /// stored as a fully-formed URL string (e.g. `applinksdemo://product/2`)
    /// in both static (`Info.plist`) and dynamic registrations, so the parser
    /// reuses `init?(url:)`. This keeps quick actions thin adapters rather
    /// than introducing a parallel route grammar.
    init?(shortcutItem: UIApplicationShortcutItem) {
        guard let url = URL(string: shortcutItem.type) else { return nil }
        self.init(url: url)
    }

    private static func pathTokens(_ path: String) -> [String] {
        path.split(separator: "/").map(String.init)
    }
}
