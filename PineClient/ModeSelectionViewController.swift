//
//  ModeSelectionController.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 20.11.2022.
//

import UIKit

enum AppMode {
    case server
    case client
}

protocol ModeSelectionViewControllerDelegate: AnyObject {
    func didSelectedMode(mode: AppMode)
}

final class ModeSelectionViewController: UIViewController {
    weak var delegate: ModeSelectionViewControllerDelegate?
    
    private let contentView: UIStackView = {
        let view = UIStackView()
        view.spacing = 16
        view.axis = .vertical
        return view
    }()
    
    private lazy var pineButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(pineButtonTapped), for: .touchUpInside)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
        button.setTitle("Я сосна", for: .normal)
        return button
    }()
    
    private lazy var userButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(userButtonTapped), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
        button.setTitle("Я любитель природы", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Выберите режим работы"
        
        [contentView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        contentView.addArrangedSubview(pineButton)
        contentView.addArrangedSubview(userButton)
    }
    
    @objc private func pineButtonTapped() {
        delegate?.didSelectedMode(mode: .server)
    }
    
    @objc private func userButtonTapped() {
        delegate?.didSelectedMode(mode: .client)
    }
}
