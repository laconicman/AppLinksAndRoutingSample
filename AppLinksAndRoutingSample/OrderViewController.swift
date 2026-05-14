//
//  OrderViewController.swift
//  AppLinksAndRoutingSample
//

import UIKit

/// Order detail screen. Header with status pill, line items list, total at the
/// bottom. Reached both from the Orders tab list and from `applinksdemo://order/<id>`.
final class OrderViewController: UIViewController {

    private let orderID: String

    init(orderID: String) {
        self.orderID = orderID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Order"

        if let order = Catalog.order(id: orderID) {
            install(content: makeDetailView(for: order))
        } else {
            install(content: NotFoundView(symbol: "questionmark.circle",
                                          title: "Order not found",
                                          message: "No order with id \"\(orderID)\". Try one of the IDs from the Orders tab."))
        }
    }

    private func install(content: UIView) {
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func makeDetailView(for order: Order) -> UIView {
        let scroll = UIScrollView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 20, bottom: 24, right: 20)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(makeHeader(for: order))
        stack.addArrangedSubview(makeSectionHeader("Items"))
        stack.addArrangedSubview(makeItemsCard(for: order))
        stack.addArrangedSubview(makeTotalCard(for: order))

        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])
        return scroll
    }

    private func makeHeader(for order: Order) -> UIView {
        let idLabel = UILabel()
        idLabel.text = "Order #\(order.id)"
        idLabel.font = .preferredFont(forTextStyle: .largeTitle).withWeight(.bold)
        idLabel.adjustsFontForContentSizeCategory = true

        let placedLabel = UILabel()
        placedLabel.text = "Placed \(Format.placed(order.placedAt))"
        placedLabel.font = .preferredFont(forTextStyle: .subheadline)
        placedLabel.textColor = .secondaryLabel
        placedLabel.adjustsFontForContentSizeCategory = true

        let pill = StatusPill(status: order.status)

        let pillRow = UIStackView(arrangedSubviews: [pill, UIView()])
        pillRow.axis = .horizontal

        let stack = UIStackView(arrangedSubviews: [idLabel, placedLabel, pillRow])
        stack.axis = .vertical
        stack.spacing = 6
        stack.setCustomSpacing(12, after: placedLabel)
        return stack
    }

    private func makeSectionHeader(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    private func makeItemsCard(for order: Order) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 12
        card.layer.cornerCurve = .continuous

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        for (index, lineItem) in order.lineItems.enumerated() {
            stack.addArrangedSubview(makeLineItemRow(lineItem))
            if index < order.lineItems.count - 1 {
                stack.addArrangedSubview(SeparatorView())
            }
        }
        return card
    }

    private func makeLineItemRow(_ lineItem: Order.LineItem) -> UIView {
        let symbol = UIImageView(image: UIImage(systemName: lineItem.product.symbolName))
        symbol.tintColor = .systemBlue
        symbol.preferredSymbolConfiguration = .init(pointSize: 24, weight: .regular)
        symbol.contentMode = .scaleAspectFit

        let name = UILabel()
        name.text = lineItem.product.name
        name.font = .preferredFont(forTextStyle: .body).withWeight(.semibold)
        name.adjustsFontForContentSizeCategory = true

        let qty = UILabel()
        qty.text = "Qty \(lineItem.quantity) · \(Format.price(lineItem.product.price)) each"
        qty.font = .preferredFont(forTextStyle: .footnote)
        qty.textColor = .secondaryLabel
        qty.adjustsFontForContentSizeCategory = true

        let textStack = UIStackView(arrangedSubviews: [name, qty])
        textStack.axis = .vertical
        textStack.spacing = 2

        let total = UILabel()
        total.text = Format.price(lineItem.lineTotal)
        total.font = .preferredFont(forTextStyle: .body).withWeight(.semibold)
        total.textColor = .label
        total.adjustsFontForContentSizeCategory = true
        total.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [symbol, textStack, total])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center
        row.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        row.isLayoutMarginsRelativeArrangement = true

        symbol.widthAnchor.constraint(equalToConstant: 28).isActive = true
        return row
    }

    private func makeTotalCard(for order: Order) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 12
        card.layer.cornerCurve = .continuous

        let title = UILabel()
        title.text = "Total"
        title.font = .preferredFont(forTextStyle: .headline)
        title.adjustsFontForContentSizeCategory = true

        let total = UILabel()
        total.text = Format.price(order.total)
        total.font = .preferredFont(forTextStyle: .title2).withWeight(.bold)
        total.textColor = .systemBlue
        total.adjustsFontForContentSizeCategory = true

        let row = UIStackView(arrangedSubviews: [title, UIView(), total])
        row.axis = .horizontal
        row.alignment = .center
        row.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        row.isLayoutMarginsRelativeArrangement = true
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }
}

// MARK: - Status pill

private final class StatusPill: UIView {
    init(status: Order.Status) {
        super.init(frame: .zero)

        backgroundColor = status.tintColor.withAlphaComponent(0.15)
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous

        let symbol = UIImageView(image: UIImage(systemName: status.symbolName))
        symbol.tintColor = status.tintColor
        symbol.preferredSymbolConfiguration = .init(pointSize: 13, weight: .bold)

        let label = UILabel()
        label.text = status.rawValue
        label.font = .preferredFont(forTextStyle: .footnote).withWeight(.semibold)
        label.textColor = status.tintColor
        label.adjustsFontForContentSizeCategory = true

        let stack = UIStackView(arrangedSubviews: [symbol, label])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.layoutMargins = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 12)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: 0)
    }
}
