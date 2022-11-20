//
//  HintView.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 20.11.2022.
//

import UIKit

struct HintViewModel {
    let text: String
    let color: UIColor
}

private enum Constants {
    static let spacing: CGFloat = 16
}

final class HintView: UIView {
    
    private let hintLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()
    
    init() {
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) { nil }
    
    private func setupView() {
        layer.cornerRadius = 20
        
        addSubview(hintLabel)
        
        NSLayoutConstraint.activate([
            hintLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.spacing),
            hintLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.spacing),
            hintLabel.topAnchor.constraint(equalTo: topAnchor, constant: Constants.spacing),
            hintLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.spacing),
        ])
    }
}

extension HintView {
    func configure(with model: HintViewModel) {
        hintLabel.text = model.text
        backgroundColor = model.color
    }
}
