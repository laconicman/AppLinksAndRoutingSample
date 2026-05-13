//
//  DeepLinkRoute.swift
//  AppLinksAndRoutingSample
//

import Foundation

/// Routes supported by both the custom URL scheme and universal links.
///
/// Custom-scheme examples (registered under `CFBundleURLTypes` in Info.plist):
///   applinksdemo://home
///   applinksdemo://product/123
///   applinksdemo://order/abc
///
/// Universal-link examples (require Associated Domains + AASA — see SceneDelegate):
///   https://yourdomain.com/home
///   https://yourdomain.com/product/123
///   https://yourdomain.com/order/abc
enum DeepLinkRoute: Hashable {
    case home
    case product(id: String)
    case order(id: String)

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

    private static func pathTokens(_ path: String) -> [String] {
        path.split(separator: "/").map(String.init)
    }
}
