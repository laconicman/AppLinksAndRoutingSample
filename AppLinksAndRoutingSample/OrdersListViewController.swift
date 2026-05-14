//
//  OrdersListViewController.swift
//  AppLinksAndRoutingSample
//

import UIKit

/// Root of the Orders tab. Insetted list of recent orders. Tapping pushes
/// `OrderViewController`, the same destination the routing layer pushes for
/// `applinksdemo://order/<id>`.
final class OrdersListViewController: UIViewController {

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, Order.ID>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Orders"
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        configureCollectionView()
        configureDataSource()
        applySnapshot()
    }

    private func configureCollectionView() {
        var listConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        listConfig.backgroundColor = .clear
        let layout = UICollectionViewCompositionalLayout.list(using: listConfig)

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureDataSource() {
        let registration = UICollectionView.CellRegistration<UICollectionViewListCell, Order.ID> { cell, _, orderID in
            guard let order = Catalog.order(id: orderID) else { return }
            cell.contentConfiguration = OrdersListViewController.makeContentConfiguration(for: order)
            cell.accessories = [.disclosureIndicator()]
        }
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, orderID in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: orderID)
        }
    }

    private static func makeContentConfiguration(for order: Order) -> UIContentConfiguration {
        var config = UIListContentConfiguration.subtitleCell()
        config.image = UIImage(systemName: order.status.symbolName)
        config.imageProperties.tintColor = order.status.tintColor
        config.imageProperties.preferredSymbolConfiguration = .init(pointSize: 22, weight: .regular)
        config.text = "Order #\(order.id)"
        config.textProperties.font = .preferredFont(forTextStyle: .headline)
        config.secondaryText = "\(order.status.rawValue) · \(Format.placed(order.placedAt)) · \(Format.price(order.total))"
        config.secondaryTextProperties.color = .secondaryLabel
        return config
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Order.ID>()
        snapshot.appendSections([0])
        snapshot.appendItems(Catalog.orders.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension OrdersListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return }
        navigationController?.pushViewController(OrderViewController(orderID: id), animated: true)
    }
}

// MARK: - Status presentation

extension Order.Status {
    var symbolName: String {
        switch self {
        case .processing: "clock.fill"
        case .shipped:    "shippingbox.fill"
        case .delivered:  "checkmark.seal.fill"
        }
    }

    var tintColor: UIColor {
        switch self {
        case .processing: .systemOrange
        case .shipped:    .systemBlue
        case .delivered:  .systemGreen
        }
    }
}
