//
//  MainTabBarController.swift
//  AppLinksAndRoutingSample
//

import UIKit

/// Composes the three tabs — Home, Products, Orders — each wrapped in its own
/// `UINavigationController`. Holds the nav stacks so `TabRouter` can both
/// switch tabs and push destinations onto the selected tab's stack.
final class MainTabBarController: UITabBarController {

    enum Tab: Int, CaseIterable {
        case home, products, orders
    }

    let homeNavigationController: UINavigationController
    let productsNavigationController: UINavigationController
    let ordersNavigationController: UINavigationController

    init() {
        self.homeNavigationController = Self.wrap(
            HomeViewController(),
            tabTitle: "Home",
            symbolName: "house.fill")
        self.productsNavigationController = Self.wrap(
            ProductsListViewController(),
            tabTitle: "Products",
            symbolName: "bag.fill")
        self.ordersNavigationController = Self.wrap(
            OrdersListViewController(),
            tabTitle: "Orders",
            symbolName: "shippingbox.fill")
        super.init(nibName: nil, bundle: nil)
        viewControllers = [homeNavigationController, productsNavigationController, ordersNavigationController]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func navigationController(for tab: Tab) -> UINavigationController {
        switch tab {
        case .home:     homeNavigationController
        case .products: productsNavigationController
        case .orders:   ordersNavigationController
        }
    }

    private static func wrap(_ root: UIViewController, tabTitle: String, symbolName: String) -> UINavigationController {
        let nav = UINavigationController(rootViewController: root)
        nav.tabBarItem = UITabBarItem(title: tabTitle,
                                      image: UIImage(systemName: symbolName),
                                      selectedImage: nil)
        return nav
    }
}
