//
//  ARWorldMapCreationViewController.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 20.11.2022.
//

import UIKit

protocol ARWorldMapCreationViewControllerDelegate: AnyObject {
    func userDidCreateWorldMap(data: Data)
}

final class ARWorldMapCreationViewController: UIViewController {
    
    weak var delegate: ARWorldMapCreationViewControllerDelegate?
    
    private let arComponent: ARComponent = ARComponentImpl(configuration: .init(
        showAddImageButton: false,
        showGetWorldMapButton: true,
        trackingText: "Идёт определение положения... Осмотрите местность вокруг себя, но не уходите далеко",
        normalTrackingText: "Походите вокруг, для создания карты местности. Нажмите на кнопку, когда будете готовы.",
        worldData: nil,
        imagesList: []
    ))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arComponent.delegate = self
        
        [arComponent.view].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            arComponent.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arComponent.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            arComponent.view.topAnchor.constraint(equalTo: view.topAnchor),
            arComponent.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        arComponent.run()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        arComponent.pause()
        super.viewWillDisappear(animated)
    }
}

extension ARWorldMapCreationViewController: ARComponentDelegate {
    func sessionFailed() {}
    
    func userDidPlaceImage(imageData: ImageData) {}
    
    func userDidCreateWorldMap(data: Data) {
        delegate?.userDidCreateWorldMap(data: data)
    }
}
