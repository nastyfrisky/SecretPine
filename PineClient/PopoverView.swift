//
//  PopoverView.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 19.11.2022.
//

import UIKit

struct ButtonModel {
    let text: String
    let action: () -> Void
}

struct PopoverViewModel {
    let text: String
    let buttonModel: ButtonModel?
    
    init(text: String) {
        self.text = text
        self.buttonModel = nil
    }
    
    init(text: String, buttonText: String, buttonAction: @escaping () -> Void) {
        self.text = text
        self.buttonModel = .init(text: buttonText, action: buttonAction)
    }
}

final class PopoverView: UIView {
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
        label.font = UIFont.systemFont(ofSize: 18)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private lazy var button: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
        return button
    }()
    
    private var buttonAction: (() -> Void)?
    
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
        contentView.addArrangedSubview(button)
    }
    
    required init?(coder: NSCoder) { nil }
    
    func configure(with model: PopoverViewModel) {
        textLabel.text = model.text
        
        if let buttonModel = model.buttonModel {
            buttonAction = buttonModel.action
            button.setTitle(buttonModel.text, for: .normal)
            button.isHidden = false
        } else {
            button.isHidden = true
        }
    }
    
    @objc private func buttonTapped() {
        buttonAction?()
    }
}
