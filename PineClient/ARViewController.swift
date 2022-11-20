//
//  ARViewController.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 19.11.2022.
//

import UIKit

final class ARViewController: UIViewController {
    
    private let presenter: ARPresenter
    private let arComponent: ARComponent
    
    private let popoverView = PopoverView()
    private let progressPopoverView = ProgressPopoverView()
    
    init(presenter: ARPresenter, worldData: Data, imagesList: [ImageData]) {
        self.presenter = presenter
        arComponent = ARComponentImpl(configuration: .init(
            showAddImageButton: true,
            showGetWorldMapButton: false,
            trackingText: "Идёт определение положения... Осмотрите местность вокруг себя, но не уходите далеко",
            normalTrackingText: nil,
            worldData: worldData,
            imagesList: imagesList
        ))

        super.init(nibName: nil, bundle: nil)
        arComponent.delegate = self
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        [arComponent.view, popoverView, progressPopoverView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            arComponent.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arComponent.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            arComponent.view.topAnchor.constraint(equalTo: view.topAnchor),
            arComponent.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        NSLayoutConstraint.activate([
            popoverView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            popoverView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            popoverView.topAnchor.constraint(equalTo: view.topAnchor),
            popoverView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        NSLayoutConstraint.activate([
            progressPopoverView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressPopoverView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressPopoverView.topAnchor.constraint(equalTo: view.topAnchor),
            progressPopoverView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        if !arComponent.isWorldInitialized { arComponent.view.isHidden = true }
        presenter.viewLoaded(isWorldInitialized: arComponent.isWorldInitialized)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if arComponent.isWorldInitialized {
            arComponent.run()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if arComponent.isWorldInitialized {
            arComponent.pause()
        }
        
        super.viewDidDisappear(animated)
    }
    
    func showPopover(with model: PopoverViewModel) {
        popoverView.configure(with: model)
        popoverView.isHidden = false
    }
    
    func hidePopover() {
        popoverView.isHidden = true
    }
    
    func showProgressPopover(with model: ProgressPopoverViewModel) {
        progressPopoverView.configure(with: model)
        progressPopoverView.isHidden = false
    }
    
    func hideProgressPopover() {
        progressPopoverView.isHidden = true
    }
}

extension ARViewController: ARComponentDelegate {
    func userDidCreateWorldMap(data: Data) {}
    
    func userDidPlaceImage(imageData: ImageData) {
        presenter.didPlacedImage(data: imageData)
    }
    
    func sessionFailed() {
        presenter.arSessionFailed()
    }
}
