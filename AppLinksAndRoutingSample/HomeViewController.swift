//
//  HomeViewController.swift
//  AppLinksAndRoutingSample
//

import UIKit

/// Welcome screen for the Home tab. Doubles as in-app documentation by listing
/// the simulator commands that exercise every routing entry point.
final class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Home"
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 24
        content.alignment = .fill
        content.translatesAutoresizingMaskIntoConstraints = false
        content.layoutMargins = UIEdgeInsets(top: 16, left: 20, bottom: 32, right: 20)
        content.isLayoutMarginsRelativeArrangement = true
        scroll.addSubview(content)

        content.addArrangedSubview(makeHero())
        content.addArrangedSubview(makeSection(
            title: "Custom-scheme deep links",
            footer: "Run from a terminal with the simulator booted.",
            rows: [
                "xcrun simctl openurl booted applinksdemo://home",
                "xcrun simctl openurl booted applinksdemo://product/2",
                "xcrun simctl openurl booted applinksdemo://order/1001"
            ]
        ))
        content.addArrangedSubview(makeSection(
            title: "Universal links",
            footer: "Wired in code; requires Associated Domains + AASA to actually deliver. See README.",
            rows: [
                "https://yourdomain.com/product/3",
                "https://yourdomain.com/order/1002"
            ]
        ))
        content.addArrangedSubview(makeSection(
            title: "Home Screen quick actions",
            footer: "Long-press the app icon on the Home Screen to access these.",
            rows: [
                "Continue Shopping  →  Espresso Maker",
                "Track Latest Order  →  #1001"
            ]
        ))

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])
    }

    private func makeHero() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .leading

        let symbol = UIImageView(image: UIImage(systemName: "arrow.triangle.branch"))
        symbol.tintColor = .systemBlue
        symbol.preferredSymbolConfiguration = .init(pointSize: 44, weight: .semibold)
        symbol.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = "Welcome"
        title.font = .preferredFont(forTextStyle: .largeTitle).bold()
        title.adjustsFontForContentSizeCategory = true

        let subtitle = UILabel()
        subtitle.text = "This sample demonstrates one routing core handling custom-scheme deep links, universal links, and Home Screen quick actions in a tab-based UIKit app."
        subtitle.numberOfLines = 0
        subtitle.font = .preferredFont(forTextStyle: .body)
        subtitle.textColor = .secondaryLabel
        subtitle.adjustsFontForContentSizeCategory = true

        stack.addArrangedSubview(symbol)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(subtitle)
        return stack
    }

    private func makeSection(title: String, footer: String, rows: [String]) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8

        let header = UILabel()
        header.text = title.uppercased()
        header.font = .preferredFont(forTextStyle: .footnote)
        header.textColor = .secondaryLabel
        header.adjustsFontForContentSizeCategory = true
        container.addArrangedSubview(header)

        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 12
        card.layer.cornerCurve = .continuous
        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 0
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cardStack)

        for (index, row) in rows.enumerated() {
            let label = UILabel()
            label.text = row
            label.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
            label.textColor = .label
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
            label.lineBreakMode = .byCharWrapping
            let row = UIView()
            row.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: row.topAnchor, constant: 12),
                label.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -12),
                label.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
                label.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16)
            ])
            cardStack.addArrangedSubview(row)
            if index < rows.count - 1 {
                cardStack.addArrangedSubview(SeparatorView())
            }
        }

        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: card.topAnchor),
            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        container.addArrangedSubview(card)

        let footerLabel = UILabel()
        footerLabel.text = footer
        footerLabel.font = .preferredFont(forTextStyle: .footnote)
        footerLabel.textColor = .secondaryLabel
        footerLabel.numberOfLines = 0
        footerLabel.adjustsFontForContentSizeCategory = true
        container.addArrangedSubview(footerLabel)

        return container
    }
}

private extension UIFont {
    func bold() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) else { return self }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
