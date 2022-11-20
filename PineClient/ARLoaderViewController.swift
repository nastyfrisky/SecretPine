//
//  ARLoaderViewController.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 19.11.2022.
//

import UIKit

struct LoadingDataViewModel {
    let text: String
    let progress: Float
}

final class ARLoaderViewController: UIViewController {
    
    private let presenter: ARLoaderPresenter
    
    private let popoverView = PopoverView()
    
    private let loadingDataView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 16
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
    
    init(presenter: ARLoaderPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Загрузка дополненной реальности"
        
        [loadingDataView, popoverView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            popoverView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            popoverView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            popoverView.topAnchor.constraint(equalTo: view.topAnchor),
            popoverView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            loadingDataView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            loadingDataView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            loadingDataView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        loadingDataView.addArrangedSubview(textLabel)
        loadingDataView.addArrangedSubview(progressView)
        
        presenter.viewLoaded()
    }
    
    func showPopover(with model: PopoverViewModel) {
        popoverView.configure(with: model)
        popoverView.isHidden = false
    }
    
    func hidePopover() {
        popoverView.isHidden = true
    }
    
    func configure(with model: LoadingDataViewModel) {
        textLabel.text = model.text
        progressView.progress = model.progress
    }
}
