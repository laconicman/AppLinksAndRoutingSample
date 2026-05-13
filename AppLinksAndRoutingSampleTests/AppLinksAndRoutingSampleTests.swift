//
//  AppLinksAndRoutingSampleTests.swift
//  AppLinksAndRoutingSampleTests
//

import Testing
import Foundation
@testable import AppLinksAndRoutingSample

// MARK: - DeepLinkRoute parsing
//
// Pure-function tests. Verifies the token-normalization path: the same enum
// values come out regardless of whether the URL was a custom-scheme deep link
// or an https universal link.

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
    // These are the cases the original discussion-essentials parser silently
    // rejected — they're the reason for token normalization.

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
}

// MARK: - AppCoordinator routing
//
// Uses a spy `RouteNavigating` to assert *what* the coordinator decided to
// route to, without involving UIKit. Covers parsing→dispatch wiring, the
// user-activity path, and the dedup behavior.

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

    @Test func handleDeepLinkDispatchesCustomSchemeRoute() {
        let (coordinator, spy) = makeSubject()
        coordinator.handleDeepLink(URL(string: "applinksdemo://product/123")!)
        #expect(spy.navigatedRoutes == [.product(id: "123")])
    }

    @Test func handleDeepLinkDispatchesUniversalLinkRoute() {
        let (coordinator, spy) = makeSubject()
        coordinator.handleDeepLink(URL(string: "https://example.com/order/abc")!)
        #expect(spy.navigatedRoutes == [.order(id: "abc")])
    }

    @Test func handleDeepLinkIgnoresUnparseableURL() {
        let (coordinator, spy) = makeSubject()
        coordinator.handleDeepLink(URL(string: "applinksdemo://unknown")!)
        #expect(spy.navigatedRoutes.isEmpty)
    }

    @Test func handleUserActivityRoutesBrowsingWebActivity() {
        let (coordinator, spy) = makeSubject()
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://example.com/product/42")!
        coordinator.handleUserActivity(activity)
        #expect(spy.navigatedRoutes == [.product(id: "42")])
    }

    @Test func handleUserActivityIgnoresNonBrowsingActivity() {
        let (coordinator, spy) = makeSubject()
        let activity = NSUserActivity(activityType: "com.example.something-else")
        activity.webpageURL = URL(string: "https://example.com/product/42")!
        coordinator.handleUserActivity(activity)
        #expect(spy.navigatedRoutes.isEmpty)
    }

    @Test func handleUserActivityIgnoresMissingWebpageURL() {
        let (coordinator, spy) = makeSubject()
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        coordinator.handleUserActivity(activity)
        #expect(spy.navigatedRoutes.isEmpty)
    }

    // Dedup: the same route delivered twice (e.g. once via willConnectTo cold
    // start, once via openURLContexts in a quick succession) should only
    // navigate once.
    @Test func sameRouteDeliveredTwiceNavigatesOnce() {
        let (coordinator, spy) = makeSubject()
        let url = URL(string: "applinksdemo://product/123")!
        coordinator.handleDeepLink(url)
        coordinator.handleDeepLink(url)
        #expect(spy.navigatedRoutes == [.product(id: "123")])
    }
}
