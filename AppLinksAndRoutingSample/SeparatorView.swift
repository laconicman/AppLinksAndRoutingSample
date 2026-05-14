//
//  SeparatorView.swift
//  AppLinksAndRoutingSample
//
//  Created by Paul Buktab on 5/14/26.
//

import UIKit

final class SeparatorView: UIView {
    init() {
        super.init(frame: .zero)
        backgroundColor = .separator
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 1 / traitCollection.displayScale).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
