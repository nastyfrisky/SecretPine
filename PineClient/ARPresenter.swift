//
//  ARPresenter.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 19.11.2022.
//

import Foundation

final class ARPresenter {
    weak var view: ARViewController?
    
    private let pineID: PeripheralID
    private let manager: CentralManagerService
    private var pineConnection: PineConnection?
    
    private var imageDataToSend: ImageData?
    private var isNeededSendImage: Bool { imageDataToSend != nil }
    
    init(pineID: PeripheralID, manager: CentralManagerService) {
        self.pineID = pineID
        self.manager = manager
    }
    
    func viewLoaded(isWorldInitialized: Bool) {
        manager.delegate = self

        view?.hideProgressPopover()
        
        if isWorldInitialized {
            view?.hidePopover()
        } else {
            view?.showPopover(with: .init(
                text: "К сожалению, не удалось загрузить мир. Попробуйте перезагрузить приложение :(",
                buttonText: "Вернуться в чат",
                buttonAction: { [weak self] in self?.goBack() }
            ))
        }
    }
    
    func didPlacedImage(data: ImageData) {
        imageDataToSend = data
        startImageSending()
    }
    
    func arSessionFailed() {
        view?.showPopover(with: .init(
            text: "Для работы дополненной реальности вам необходимо обновить iOS",
            buttonText: "Вернуться в чат",
            buttonAction: { [weak self] in self?.goBack() }
        ))
    }
    
    private func goBack() {
        view?.navigationController?.popViewController(animated: true)
    }
    
    private func startImageSending() {
        guard let imageDataToSend = imageDataToSend else { return }
        
        view?.hidePopover()
        view?.showProgressPopover(with: .init(text: "Отправка изображения...", progress: 0))
        
        let connection = PineConnection(pineID: pineID, centralManagerService: manager)
        connection.delegate = self
        connection.uploadImage(imageData: imageDataToSend)
        pineConnection = connection
    }
    
    private func executeNeededActions() {
        if isNeededSendImage {
            startImageSending()
            return
        }
    }
}

extension ARPresenter: CentralManagerServiceDelegate {
    func centralManagerRescanComplete() {}
    
    func centralManagerRescanFailed() {}
    
    func centralManagerBluetoothStateChanged(newState: BluetoothState) {}
    
    func centralManagerDeviceUpdated(id: PeripheralID) {}
}

extension ARPresenter: PineConnectionDelegate {
    func imagesCountReceived(count: Int?) {}
    
    func imageReceived(imageData: ImageData?) {}
    

    func uploadProgressUpdated(totalSize: Int, loaded: Int) {
        let progress = Float(loaded) / Float(totalSize)
        view?.showProgressPopover(with: .init(text: "Отправка изображения \(Int(progress * 100))%", progress: progress))
    }
    
    func imageUploaded(isSuccess: Bool) {
        view?.hideProgressPopover()
        
        if isSuccess {
            imageDataToSend = nil

            view?.showPopover(with: .init(
                text: "Изображение загружено :)",
                buttonText: "Ок",
                buttonAction: { [weak self] in self?.view?.hidePopover() }
            ))
            
            return
        }
        
        view?.showPopover(with: .init(
            text: "К сожалению, не удалось отправить изображение, но можно попробовать ещё раз",
            buttonText: "Попробовать ещё раз",
            buttonAction: { [weak self] in self?.executeNeededActions() }
        ))
    }
    
    func messagesReceived(list: [Message]?) {}
    
    func messageSent(isSuccess: Bool) {}
    
    func worldDownloaded(data: Data?) {}
    
    func downloadProgressUpdated(totalSize: Int, loaded: Int) {}
}
