//
//  AppLinksAndRoutingSampleTests.swift
//  AppLinksAndRoutingSampleTests
//

import Testing
import Foundation
import UIKit
@testable import AppLinksAndRoutingSample

// MARK: - DeepLinkRoute parsing
//
// Verifies the token-normalization path (custom-scheme and universal-link URLs
// produce the same enum values) and each adapter init delegates correctly to
// the URL parser.

@Suite("DeepLinkRoute parsing")
struct DeepLinkRouteTests {

    // Custom-scheme (deep link) shape: host carries the route type.

    @Test func customSchemeHome() {
        #expect(DeepLinkRoute(url: URL(string: "applinksdemo://home")!) == .home)
    }

    @Test func customSchemeProduct() {
        #expect(DeepLinkRoute(url: URL(string: "applinksdemo://product/123")!) == .product(id: "123"))
    }

    @Test func customSchemeOrder() {
        #expect(DeepLinkRoute(url: URL(string: "applinksdemo://order/abc")!) == .order(id: "abc"))
    }

    // Universal-link (https) shape: route type is the first path component.

    @Test func universalLinkHome() {
        #expect(DeepLinkRoute(url: URL(string: "https://example.com/home")!) == .home)
    }

    @Test func universalLinkProduct() {
        #expect(DeepLinkRoute(url: URL(string: "https://example.com/product/123")!) == .product(id: "123"))
    }

    @Test func universalLinkOrder() {
        #expect(DeepLinkRoute(url: URL(string: "https://example.com/order/abc")!) == .order(id: "abc"))
    }

    // Rejection cases.

    @Test func unknownHostReturnsNil() {
        #expect(DeepLinkRoute(url: URL(string: "applinksdemo://unknown/123")!) == nil)
    }

    @Test func missingProductIdReturnsNil() {
        #expect(DeepLinkRoute(url: URL(string: "applinksdemo://product")!) == nil)
    }

    @Test func extraPathSegmentReturnsNil() {
        #expect(DeepLinkRoute(url: URL(string: "applinksdemo://product/123/extra")!) == nil)
    }

    @Test func emptyHttpsPathReturnsNil() {
        #expect(DeepLinkRoute(url: URL(string: "https://example.com/")!) == nil)
    }

    // NSUserActivity adapter.

    @Test func userActivityBrowsingWebRoutes() {
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://example.com/product/42")!
        #expect(DeepLinkRoute(userActivity: activity) == .product(id: "42"))
    }

    @Test func userActivityNonBrowsingReturnsNil() {
        let activity = NSUserActivity(activityType: "com.example.something-else")
        activity.webpageURL = URL(string: "https://example.com/product/42")!
        #expect(DeepLinkRoute(userActivity: activity) == nil)
    }

    @Test func userActivityMissingWebpageURLReturnsNil() {
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        #expect(DeepLinkRoute(userActivity: activity) == nil)
    }

    // UIApplicationShortcutItem adapter.

    @Test @MainActor func shortcutItemRoutes() {
        let item = UIApplicationShortcutItem(type: "applinksdemo://product/1", localizedTitle: "Continue Shopping")
        #expect(DeepLinkRoute(shortcutItem: item) == .product(id: "1"))
    }

    @Test @MainActor func shortcutItemOrderRoutes() {
        let item = UIApplicationShortcutItem(type: "applinksdemo://order/1001", localizedTitle: "Track Latest Order")
        #expect(DeepLinkRoute(shortcutItem: item) == .order(id: "1001"))
    }

    @Test @MainActor func shortcutItemMalformedTypeReturnsNil() {
        let item = UIApplicationShortcutItem(type: "not a url at all 💥", localizedTitle: "Broken")
        #expect(DeepLinkRoute(shortcutItem: item) == nil)
    }
}

// MARK: - AppCoordinator routing
//
// Uses a spy `RouteNavigating` to assert *what* the coordinator decided to
// route to, without involving UIKit's view hierarchy.

@MainActor
@Suite("AppCoordinator routing")
struct AppCoordinatorTests {

    private final class SpyRouter: RouteNavigating {
        private(set) var navigatedRoutes: [DeepLinkRoute] = []
        func navigate(to route: DeepLinkRoute) {
            navigatedRoutes.append(route)
        }
    }

    private func makeSubject() -> (AppCoordinator, SpyRouter) {
        let coordinator = AppCoordinator()
        let spy = SpyRouter()
        coordinator.start(router: spy)
        return (coordinator, spy)
    }

    @Test func processCustomSchemeURLDispatches() {
        let (coordinator, spy) = makeSubject()
        coordinator.process(url: URL(string: "applinksdemo://product/123")!)
        #expect(spy.navigatedRoutes == [.product(id: "123")])
    }

    @Test func processUniversalLinkURLDispatches() {
        let (coordinator, spy) = makeSubject()
        coordinator.process(url: URL(string: "https://example.com/order/abc")!)
        #expect(spy.navigatedRoutes == [.order(id: "abc")])
    }

    @Test func processUnparseableURLIgnored() {
        let (coordinator, spy) = makeSubject()
        coordinator.process(url: URL(string: "applinksdemo://unknown")!)
        #expect(spy.navigatedRoutes.isEmpty)
    }

    @Test func processUserActivityBrowsingWebDispatches() {
        let (coordinator, spy) = makeSubject()
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://example.com/product/42")!
        coordinator.process(userActivity: activity)
        #expect(spy.navigatedRoutes == [.product(id: "42")])
    }

    @Test func processUserActivityNonBrowsingIgnored() {
        let (coordinator, spy) = makeSubject()
        let activity = NSUserActivity(activityType: "com.example.something-else")
        activity.webpageURL = URL(string: "https://example.com/product/42")!
        coordinator.process(userActivity: activity)
        #expect(spy.navigatedRoutes.isEmpty)
    }

    @Test func processShortcutItemDispatches() {
        let (coordinator, spy) = makeSubject()
        let item = UIApplicationShortcutItem(type: "applinksdemo://order/1001", localizedTitle: "Track Latest Order")
        coordinator.process(shortcutItem: item)
        #expect(spy.navigatedRoutes == [.order(id: "1001")])
    }

    @Test func processShortcutItemMalformedIgnored() {
        let (coordinator, spy) = makeSubject()
        let item = UIApplicationShortcutItem(type: "not-a-url", localizedTitle: "Broken")
        coordinator.process(shortcutItem: item)
        #expect(spy.navigatedRoutes.isEmpty)
    }

    // Quick actions are legitimately repeatable; dispatch must NOT dedup.
    @Test func repeatedProcessingNavigatesEachTime() {
        let (coordinator, spy) = makeSubject()
        let item = UIApplicationShortcutItem(type: "applinksdemo://product/1", localizedTitle: "Continue Shopping")
        coordinator.process(shortcutItem: item)
        coordinator.process(shortcutItem: item)
        #expect(spy.navigatedRoutes == [.product(id: "1"), .product(id: "1")])
    }
}
