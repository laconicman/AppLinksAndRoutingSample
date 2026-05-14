//
//  AppCoordinator.swift
//  AppLinksAndRoutingSample
//

import UIKit

@MainActor
protocol DeepLinkRouting: AnyObject {
    func process(url: URL)
    func process(userActivity: NSUserActivity)
    func process(shortcutItem: UIApplicationShortcutItem)
}

/// Test seam: turns a parsed route into navigation.
///
/// Production uses `TabRouter`. Tests use a spy that records what it was asked
/// to navigate to — no UIKit needed to assert dispatch decisions.
@MainActor
protocol RouteNavigating: AnyObject {
    func navigate(to route: DeepLinkRoute)
}

/// Production navigator. Switches to the tab the route belongs to and presents
/// the destination on that tab's navigation stack. Always pops to root before
/// pushing a detail, so the navigation state matches the route exactly even on
/// repeated deliveries.
@MainActor
final class TabRouter: RouteNavigating {
    private weak var tabBarController: MainTabBarController?

    init(tabBarController: MainTabBarController) {
        self.tabBarController = tabBarController
    }

    func navigate(to route: DeepLinkRoute) {
        guard let tabBarController else { return }
        switch route {
        case .home:
            select(.home, on: tabBarController)
            tabBarController.navigationController(for: .home).popToRootViewController(animated: true)

        case .product(let id):
            select(.products, on: tabBarController)
            let nav = tabBarController.navigationController(for: .products)
            nav.popToRootViewController(animated: false)
            nav.pushViewController(ProductViewController(productID: id), animated: true)

        case .order(let id):
            select(.orders, on: tabBarController)
            let nav = tabBarController.navigationController(for: .orders)
            nav.popToRootViewController(animated: false)
            nav.pushViewController(OrderViewController(orderID: id), animated: true)
        }
    }

    private func select(_ tab: MainTabBarController.Tab, on tabBarController: MainTabBarController) {
        tabBarController.selectedIndex = tab.rawValue
    }
}

/// Owns the tab structure and is the single place where every routing input is
/// parsed and turned into navigation. `SceneDelegate` forwards system callbacks
/// here; the coordinator decides the rest.
///
/// Three input shapes, one factory family on `DeepLinkRoute`:
///   - URL                      → `DeepLinkRoute(url:)`
///   - NSUserActivity           → `DeepLinkRoute(userActivity:)` (universal links)
///   - UIApplicationShortcutItem → `DeepLinkRoute(shortcutItem:)` (Home Screen quick actions)
///
/// Each one is a thin adapter that ends up calling the canonical URL parser, so
/// the routing surface is single-sourced.
@MainActor
final class AppCoordinator: DeepLinkRouting {
    private var router: RouteNavigating?

    /// Production entry point. Builds the tab bar, wires the router.
    func start(in window: UIWindow) {
        let tabBarController = MainTabBarController()
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        self.router = TabRouter(tabBarController: tabBarController)
    }

    /// Test entry point. Inject any `RouteNavigating` (typically a spy).
    func start(router: RouteNavigating) {
        self.router = router
    }

    func process(url: URL) {
        guard let route = DeepLinkRoute(url: url) else { return }
        router?.navigate(to: route)
    }

    func process(userActivity: NSUserActivity) {
        guard let route = DeepLinkRoute(userActivity: userActivity) else { return }
        router?.navigate(to: route)
    }

    func process(shortcutItem: UIApplicationShortcutItem) {
        guard let route = DeepLinkRoute(shortcutItem: shortcutItem) else { return }
        router?.navigate(to: route)
    }
}
