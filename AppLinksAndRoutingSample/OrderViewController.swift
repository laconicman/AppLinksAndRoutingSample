//
//  OrderViewController.swift
//  AppLinksAndRoutingSample
//

import UIKit

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
        title = "Order"
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Order \(orderID)"
        label.font = .preferredFont(forTextStyle: .title1)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
