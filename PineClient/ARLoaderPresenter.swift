//
//  ARLoaderPresenter.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 19.11.2022.
//

import Foundation

final class ARLoaderPresenter {
    
    weak var view: ARLoaderViewController?
    
    private let pineID: PeripheralID
    private let manager: CentralManagerService
    
    private var worldData: Data?
    private var imagesCount: Int?
    private var imagesList: [ImageData] = []
    
    private var isWorldDataLoaded: Bool { worldData != nil }
    private var isImagesCountLoaded: Bool { imagesCount != nil }
    
    private var isAllImagesLoaded: Bool {
        guard let imagesCount = imagesCount else { return false }
        return imagesCount == imagesList.count
    }
    
    private var pineConnection: PineConnection?
    
    init(pineID: PeripheralID, manager: CentralManagerService) {
        self.pineID = pineID
        self.manager = manager
    }
    
    func viewLoaded() {
        manager.delegate = self
        executeNeededActions()
    }
    
    private func executeNeededActions() {
        view?.hidePopover()
        
        if !isWorldDataLoaded {
            startWorldDataLoading()
            return
        }
        
        if !isImagesCountLoaded {
            startImagesCountLoading()
            return
        }
        
        if !isAllImagesLoaded {
            startImageLoading()
            return
        }
        
        goToARView()
    }
    
    private func goToARView() {
        guard let worldData = worldData else { return }
        
        let navigation = view?.navigationController
        
        let presenter = ARPresenter(pineID: pineID, manager: manager)
        let viewController = ARViewController(presenter: presenter, worldData: worldData, imagesList: imagesList)
        presenter.view = viewController
        
        navigation?.popViewController(animated: false)
        navigation?.pushViewController(viewController, animated: true)
    }
    
    private func startWorldDataLoading() {
        view?.configure(with: .init(text: "\(loadingTextForCurrentState())...", progress: 0))
        
        let connection = PineConnection(pineID: pineID, centralManagerService: manager)
        connection.delegate = self
        connection.downloadWorld()
        pineConnection = connection
    }
    
    private func startImagesCountLoading() {
        view?.configure(with: .init(text: "\(loadingTextForCurrentState())...", progress: 0))
        
        let connection = PineConnection(pineID: pineID, centralManagerService: manager)
        connection.delegate = self
        connection.requestImagesCount()
        pineConnection = connection
    }
    
    private func startImageLoading() {
        let toLoad = imagesList.count
        
        view?.configure(with: .init(text: "\(loadingTextForCurrentState())...", progress: 0))
        
        let connection = PineConnection(pineID: pineID, centralManagerService: manager)
        connection.delegate = self
        connection.downloadImage(with: toLoad)
        pineConnection = connection
    }
}

extension ARLoaderPresenter: CentralManagerServiceDelegate {
    func centralManagerRescanComplete() {}
    
    func centralManagerRescanFailed() {}
    
    func centralManagerBluetoothStateChanged(newState: BluetoothState) {}
    
    func centralManagerDeviceUpdated(id: PeripheralID) {}
}

extension ARLoaderPresenter: PineConnectionDelegate {
    func imagesCountReceived(count: Int?) {
        if let count = count {
            imagesCount = count
            executeNeededActions()
            return
        }
        
        view?.showPopover(with: .init(
            text: "К сожалению, не удалось загрузить данные, но можно попробовать ещё раз",
            buttonText: "Попробовать ещё раз",
            buttonAction: { [weak self] in self?.executeNeededActions() }
        ))
    }
    
    func imageReceived(imageData: ImageData?) {
        if let imageData = imageData {
            imagesList.append(imageData)
            executeNeededActions()
            return
        }
        
        view?.showPopover(with: .init(
            text: "К сожалению, не удалось загрузить данные, но можно попробовать ещё раз",
            buttonText: "Попробовать ещё раз",
            buttonAction: { [weak self] in self?.executeNeededActions() }
        ))
    }
    
    func uploadProgressUpdated(totalSize: Int, loaded: Int) {}
    
    func imageUploaded(isSuccess: Bool) {}
    
    func messagesReceived(list: [Message]?) {}
    
    func messageSent(isSuccess: Bool) {}
    
    func worldDownloaded(data: Data?) {
        if let data = data {
            worldData = data
            executeNeededActions()
            return
        }
        
        view?.showPopover(with: .init(
            text: "К сожалению, не удалось загрузить данные, но можно попробовать ещё раз",
            buttonText: "Попробовать ещё раз",
            buttonAction: { [weak self] in self?.executeNeededActions() }
        ))
    }
    
    func downloadProgressUpdated(totalSize: Int, loaded: Int) {
        let progress = Float(loaded) / Float(totalSize)
        view?.configure(with: .init(text: "\(loadingTextForCurrentState()) \(Int(progress * 100))%", progress: progress))
    }
    
    private func loadingTextForCurrentState() -> String {
        if !isWorldDataLoaded { return "Загрузка мира" }
        if !isImagesCountLoaded { return "Загрузка количества изображений" }
        
        if !isAllImagesLoaded {
            return "Загрузка изображения \(imagesList.count + 1)/\(imagesCount ?? 0)"
        }
        
        return ""
    }
}
