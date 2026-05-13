//
//  AppCoordinator.swift
//  AppLinksAndRoutingSample
//

import UIKit

protocol DeepLinkRouting: AnyObject {
    func handleDeepLink(_ url: URL)
    func handleUserActivity(_ userActivity: NSUserActivity)
}

/// Test seam: turns a parsed route into navigation.
///
/// Production uses `NavigationControllerRouter` (UIKit-backed). Tests use a
/// spy that records what it was asked to navigate to — no UIKit needed to
/// assert dispatch decisions.
protocol RouteNavigating: AnyObject {
    func navigate(to route: DeepLinkRoute)
}

/// Production navigator. Pushes destination view controllers onto a
/// `UINavigationController`. Held weakly so it doesn't outlive the scene.
final class NavigationControllerRouter: RouteNavigating {
    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func navigate(to route: DeepLinkRoute) {
        switch route {
        case .home:
            navigationController?.popToRootViewController(animated: true)
        case .product(let id):
            let vc = ProductViewController(productID: id)
            navigationController?.pushViewController(vc, animated: true)
        case .order(let id):
            let vc = OrderViewController(orderID: id)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

/// Owns the navigation stack and is the single place where deep links are parsed,
/// deduplicated, and turned into navigation.
///
/// `SceneDelegate` forwards both cold-start (`willConnectTo`) and warm-start
/// (`openURLContexts`, `continue userActivity`) events into here, so the
/// coordinator is the one component that knows about routing.
final class AppCoordinator: DeepLinkRouting {
    private var router: RouteNavigating?

    // Dedup tracks routes already navigated to during the lifetime of the scene.
    // Reasonable when a route value fully identifies the destination. If the same
    // route can legitimately be opened twice (e.g. refreshed state, repeated
    // quick action), replace this with a short-lived startup flag or per-event
    // token. See ROADMAP.md for the open question.
    private var handledRoutes = Set<DeepLinkRoute>()

    /// Production entry point. Builds the window, the nav stack, and the router.
    func start(in window: UIWindow) {
        let root = HomeViewController()
        let nav = UINavigationController(rootViewController: root)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.router = NavigationControllerRouter(navigationController: nav)
    }

    /// Test entry point. Inject any `RouteNavigating` (typically a spy).
    func start(router: RouteNavigating) {
        self.router = router
    }

    func handleDeepLink(_ url: URL) {
        guard let route = DeepLinkRoute(url: url) else { return }
        dispatch(route)
    }

    func handleUserActivity(_ userActivity: NSUserActivity) {
        // Universal links arrive as NSUserActivityTypeBrowsingWeb with the
        // underlying https URL exposed via `webpageURL`.
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return }
        handleDeepLink(url)
    }

    private func dispatch(_ route: DeepLinkRoute) {
        guard handledRoutes.insert(route).inserted else { return }
        router?.navigate(to: route)
    }
}
