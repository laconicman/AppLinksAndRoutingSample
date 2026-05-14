//
//  ProductViewController.swift
//  AppLinksAndRoutingSample
//

import UIKit

/// Product detail screen. Reached both by tapping a cell in
/// `ProductsListViewController` and by routing an
/// `applinksdemo://product/<id>` or `https://.../product/<id>` link.
final class ProductViewController: UIViewController {

    private let productID: String

    init(productID: String) {
        self.productID = productID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Product"

        if let product = Catalog.product(id: productID) {
            install(content: makeDetailView(for: product))
        } else {
            install(content: NotFoundView(symbol: "questionmark.circle",
                                          title: "Product not found",
                                          message: "No product with id \"\(productID)\". Try one of the IDs from the Products tab."))
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

    private func makeDetailView(for product: Product) -> UIView {
        let container = UIView()

        let hero = UIView()
        hero.backgroundColor = .secondarySystemGroupedBackground
        hero.layer.cornerRadius = 16
        hero.layer.cornerCurve = .continuous

        let symbol = UIImageView(image: UIImage(systemName: product.symbolName))
        symbol.contentMode = .scaleAspectFit
        symbol.tintColor = .systemBlue
        symbol.preferredSymbolConfiguration = .init(pointSize: 88, weight: .regular)
        symbol.translatesAutoresizingMaskIntoConstraints = false
        hero.addSubview(symbol)
        NSLayoutConstraint.activate([
            symbol.centerXAnchor.constraint(equalTo: hero.centerXAnchor),
            symbol.centerYAnchor.constraint(equalTo: hero.centerYAnchor),
            hero.heightAnchor.constraint(equalToConstant: 220)
        ])

        let nameLabel = UILabel()
        nameLabel.text = product.name
        nameLabel.font = .preferredFont(forTextStyle: .largeTitle).withWeight(.semibold)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.numberOfLines = 0

        let priceLabel = UILabel()
        priceLabel.text = Format.price(product.price)
        priceLabel.font = .preferredFont(forTextStyle: .title2)
        priceLabel.textColor = .systemBlue
        priceLabel.adjustsFontForContentSizeCategory = true

        let summary = UILabel()
        summary.text = product.summary
        summary.font = .preferredFont(forTextStyle: .body)
        summary.textColor = .secondaryLabel
        summary.numberOfLines = 0
        summary.adjustsFontForContentSizeCategory = true

        let idChip = makeChip(text: "ID  \(product.id)", symbol: "number")

        var addToCart = UIButton.Configuration.filled()
        addToCart.title = "Add to Cart"
        addToCart.image = UIImage(systemName: "cart.badge.plus")
        addToCart.imagePadding = 8
        addToCart.cornerStyle = .large
        let cartButton = UIButton(configuration: addToCart)
        cartButton.addAction(UIAction { [weak self] _ in
            self?.presentToast("Added \(product.name) to cart")
        }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [hero, nameLabel, priceLabel, idChip, summary, cartButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.setCustomSpacing(8, after: nameLabel)
        stack.setCustomSpacing(20, after: priceLabel)
        stack.setCustomSpacing(12, after: idChip)
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 20, bottom: 20, right: 20)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor)
        ])
        return container
    }

    private func makeChip(text: String, symbol: String) -> UIView {
        let chip = UIStackView()
        chip.axis = .horizontal
        chip.spacing = 6
        chip.alignment = .center
        chip.layoutMargins = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 12)
        chip.isLayoutMarginsRelativeArrangement = true

        let image = UIImageView(image: UIImage(systemName: symbol))
        image.tintColor = .secondaryLabel
        image.preferredSymbolConfiguration = .init(pointSize: 12, weight: .semibold)

        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .caption1).withWeight(.semibold)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true

        chip.addArrangedSubview(image)
        chip.addArrangedSubview(label)
        chip.backgroundColor = .tertiarySystemGroupedBackground
        chip.layer.cornerRadius = 12
        chip.layer.cornerCurve = .continuous

        let wrapper = UIStackView(arrangedSubviews: [chip, UIView()])
        wrapper.axis = .horizontal
        return wrapper
    }

    private func presentToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak alert] in
            alert?.dismiss(animated: true)
        }
    }
}

// MARK: - Not-found state

final class NotFoundView: UIView {
    init(symbol: String, title: String, message: String) {
        super.init(frame: .zero)

        let image = UIImageView(image: UIImage(systemName: symbol))
        image.tintColor = .tertiaryLabel
        image.preferredSymbolConfiguration = .init(pointSize: 56, weight: .regular)
        image.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .title2).withWeight(.semibold)
        titleLabel.textColor = .label
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.textColor = .secondaryLabel
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [image, titleLabel, messageLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 32)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
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
