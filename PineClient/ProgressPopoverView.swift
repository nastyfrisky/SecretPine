//
//  ProgressPopoverView.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 20.11.2022.
//

import UIKit

struct ProgressPopoverViewModel {
    let text: String
    let progress: Float
}

final class ProgressPopoverView: UIView {

    private let contentView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.spacing = 16
        view.axis = .vertical
        
        view.layoutMargins = .init(top: 16, left: 16, bottom: 16, right: 16)
        view.isLayoutMarginsRelativeArrangement = true
        
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
        
        return view
    }()
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private let progressView: UIProgressView = {
        let view = UIProgressView()
        return view
    }()
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .init(white: 0, alpha: 0.5)
        
        [contentView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        contentView.addArrangedSubview(textLabel)
        contentView.addArrangedSubview(progressView)
    }
    
    required init?(coder: NSCoder) { nil }
    
    func configure(with model: ProgressPopoverViewModel) {
        textLabel.text = model.text
        progressView.progress = model.progress
    }
}
