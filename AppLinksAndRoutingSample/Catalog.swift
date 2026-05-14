//
//  Catalog.swift
//  AppLinksAndRoutingSample
//
//  In-memory mock data backing the Products and Orders tabs. Kept intentionally
//  tiny — the point of this sample is routing, not data layers.
//

import Foundation

struct Product: Hashable, Identifiable {
    let id: String
    let name: String
    let price: Decimal
    let symbolName: String
    let summary: String
}

struct Order: Hashable, Identifiable {
    enum Status: String {
        case processing = "Processing"
        case shipped = "Shipped"
        case delivered = "Delivered"
    }

    struct LineItem: Hashable {
        let product: Product
        let quantity: Int

        var lineTotal: Decimal {
            product.price * Decimal(quantity)
        }
    }

    let id: String
    let placedAt: Date
    let status: Status
    let lineItems: [LineItem]

    var total: Decimal {
        lineItems.reduce(Decimal(0)) { $0 + $1.lineTotal }
    }
}

enum Catalog {
    static let products: [Product] = [
        Product(id: "1", name: "Espresso Maker", price: 129,
                symbolName: "cup.and.saucer.fill",
                summary: "Pull café-quality shots at home with a 15-bar pump and steam wand."),
        Product(id: "2", name: "Wireless Headphones", price: 199,
                symbolName: "headphones",
                summary: "Active noise cancellation with 30 hours of playback per charge."),
        Product(id: "3", name: "Smart Watch", price: 349,
                symbolName: "applewatch",
                summary: "Health, fitness, and notifications on your wrist — always-on display."),
        Product(id: "4", name: "Mechanical Keyboard", price: 159,
                symbolName: "keyboard",
                summary: "Hot-swap switches, per-key RGB, and a satisfying tactile click."),
        Product(id: "5", name: "Desk Lamp", price: 89,
                symbolName: "lamp.desk",
                summary: "Adjustable color temperature from focused work to evening reading."),
        Product(id: "6", name: "Ergonomic Chair", price: 549,
                symbolName: "chair.lounge.fill",
                summary: "Adaptive lumbar support and breathable mesh for the long haul.")
    ]

    static func product(id: String) -> Product? {
        products.first { $0.id == id }
    }

    static let orders: [Order] = [
        Order(id: "1001",
              placedAt: Date(timeIntervalSinceNow: -3 * 86_400),
              status: .processing,
              lineItems: [
                .init(product: products[0], quantity: 1),
                .init(product: products[1], quantity: 1)
              ]),
        Order(id: "1002",
              placedAt: Date(timeIntervalSinceNow: -10 * 86_400),
              status: .shipped,
              lineItems: [
                .init(product: products[3], quantity: 1)
              ]),
        Order(id: "1003",
              placedAt: Date(timeIntervalSinceNow: -25 * 86_400),
              status: .delivered,
              lineItems: [
                .init(product: products[2], quantity: 1),
                .init(product: products[4], quantity: 2)
              ])
    ]

    static func order(id: String) -> Order? {
        orders.first { $0.id == id }
    }
}

// MARK: - Formatting helpers

enum Format {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    static func price(_ value: Decimal) -> String {
        currency.string(from: value as NSDecimalNumber) ?? "$\(value)"
    }

    static let relativeDate: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    static func placed(_ date: Date) -> String {
        relativeDate.localizedString(for: date, relativeTo: Date())
    }
}
