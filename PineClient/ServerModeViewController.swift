//
//  ServerModeViewController.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 20.11.2022.
//

import UIKit

final class ServerModeViewController: UIViewController {
    
    private let dataStorage = PineDataStorage()
    
    private let stateLabelsView: UIStackView = {
        let view = UIStackView()
        view.spacing = 8
        view.axis = .vertical
        return view
    }()
    
    private let buttonsView: UIStackView = {
        let view = UIStackView()
        view.spacing = 16
        view.axis = .vertical
        return view
    }()
    
    private lazy var createWorldButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(createWorldButtonTapped), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
        button.setTitle("Создать карту мира", for: .normal)
        return button
    }()
    
    private lazy var clearDataButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(clearDataButtonTapped), for: .touchUpInside)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
        button.setTitle("Очистить все данные", for: .normal)
        return button
    }()
    
    private lazy var shareWorldButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(shareWorldButtonTapped), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
        button.setTitle("Отправить карту местности", for: .normal)
        button.isHidden = true
        return button
    }()
    
    private var manager: PeripheralManagerService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        view.backgroundColor = .white
        title = "Состояние сосны"
        
        [stateLabelsView, buttonsView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            buttonsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            stateLabelsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stateLabelsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stateLabelsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
        
        buttonsView.addArrangedSubview(createWorldButton)
        buttonsView.addArrangedSubview(shareWorldButton)
        buttonsView.addArrangedSubview(clearDataButton)
        
        update()
    }
    
    private func stateLabel(with key: String, and value: String) -> UILabel {
        let keyAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)]
        let valueAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]

        let fullString = NSMutableAttributedString()
        fullString.append(NSAttributedString(string: "\(key):", attributes: keyAttributes))
        fullString.append(NSAttributedString(string: " \(value)", attributes: valueAttributes))
        
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = fullString
        return label
    }
    
    private func update() {
        stateLabelsView.arrangedSubviews.forEach {
            stateLabelsView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        stateLabelsView.addArrangedSubview(stateLabel(
            with: "Количество сообщений",
            and: "\(dataStorage.getMessages().count)"
        ))
        
        stateLabelsView.addArrangedSubview(stateLabel(
            with: "Количество изображений",
            and: "\(dataStorage.imagesCount)"
        ))
        
        if let mapSize = dataStorage.getWorldMapSize() {
            stateLabelsView.addArrangedSubview(stateLabel(
                with: "Размер карты местности",
                and: "\(Int(Float(mapSize) / 1024)) кБ"
            ))
            
            stateLabelsView.addArrangedSubview(stateLabel(
                with: "Состояние сосны",
                and: "работает при включенном bluetooth"
            ))
            
            manager = PeripheralManagerService(pineDataStorage: dataStorage)
        } else {
            stateLabelsView.addArrangedSubview(stateLabel(
                with: "Карта местности существует",
                and: "нет"
            ))
            
            stateLabelsView.addArrangedSubview(stateLabel(
                with: "Состояние сосны",
                and: "не работает, создайте карту местности"
            ))
        
            manager = nil
        }
    }
    
    @objc private func createWorldButtonTapped() {
        let viewController = ARWorldMapCreationViewController()
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc private func clearDataButtonTapped() {
        dataStorage.clear()
        update()
    }
    
    @objc private func shareWorldButtonTapped() {
        let data = dataStorage.getWorldData()
        
        let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
        let targetURL = tempDirectoryURL.appendingPathComponent("worldMap.bin")

        try? data.write(to: targetURL)

        let activityViewController = UIActivityViewController(activityItems: [targetURL], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
}

extension ServerModeViewController: ARWorldMapCreationViewControllerDelegate {
    func userDidCreateWorldMap(data: Data) {
        dataStorage.createWorldMap(data: data)
        navigationController?.popViewController(animated: true)
        update()
    }
}
