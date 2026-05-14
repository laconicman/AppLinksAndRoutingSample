//
//  ProductsListViewController.swift
//  AppLinksAndRoutingSample
//

import UIKit

/// Root of the Products tab. Two-column grid of products backed by a diffable
/// data source. Tapping a cell pushes `ProductViewController` — the same screen
/// the routing layer pushes when an `applinksdemo://product/<id>` deep link
/// arrives. Both paths converge on one destination.
final class ProductsListViewController: UIViewController {

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, Product.ID>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Products"
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        configureCollectionView()
        configureDataSource()
        applySnapshot()
    }

    private func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: Self.makeLayout())
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private static func makeLayout() -> UICollectionViewCompositionalLayout {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalHeight(1.0)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)

        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(200)), subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 24, trailing: 12)
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func configureDataSource() {
        let registration = UICollectionView.CellRegistration<ProductGridCell, Product.ID> { cell, _, productID in
            guard let product = Catalog.product(id: productID) else { return }
            cell.configure(with: product)
        }
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, productID in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: productID)
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Product.ID>()
        snapshot.appendSections([0])
        snapshot.appendItems(Catalog.products.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension ProductsListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return }
        navigationController?.pushViewController(ProductViewController(productID: id), animated: true)
    }
}

// MARK: - Cell

private final class ProductGridCell: UICollectionViewCell {
    private let symbol = UIImageView()
    private let nameLabel = UILabel()
    private let priceLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 14
        contentView.layer.cornerCurve = .continuous

        symbol.contentMode = .scaleAspectFit
        symbol.tintColor = .systemBlue
        symbol.preferredSymbolConfiguration = .init(pointSize: 44, weight: .regular)

        nameLabel.font = .preferredFont(forTextStyle: .subheadline).withWeight(.semibold)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.numberOfLines = 2

        priceLabel.font = .preferredFont(forTextStyle: .footnote)
        priceLabel.textColor = .secondaryLabel
        priceLabel.adjustsFontForContentSizeCategory = true

        let stack = UIStackView(arrangedSubviews: [symbol, nameLabel, priceLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setCustomSpacing(12, after: symbol)
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -14),

            symbol.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with product: Product) {
        symbol.image = UIImage(systemName: product.symbolName)
        nameLabel.text = product.name
        priceLabel.text = Format.price(product.price)
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.contentView.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
            }
        }
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
