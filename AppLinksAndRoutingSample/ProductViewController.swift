//
//  ProductViewController.swift
//  AppLinksAndRoutingSample
//

import UIKit

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
        title = "Product"
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Product \(productID)"
        label.font = .preferredFont(forTextStyle: .title1)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
