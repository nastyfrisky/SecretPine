//
//  ChatPresenter.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 19.11.2022.
//

import Foundation

final class ChatPresenter {
    weak var view: ChatViewController?
    
    private let centralManager: CentralManagerService = CentralManagerServiceImpl()
    
    private var messages: [Message]?
    private var pineID: PeripheralID?
    private var currentlySendingMessage: String?
    private var isMessagesLoaded: Bool { messages != nil }
    private var isPineFound: Bool { pineID != nil }
    private var pineConnection: PineConnection?
    
    func viewLoaded() { setupForCurrentState() }
    func viewWillAppear() { setupForCurrentState() }
    
    private func setupForCurrentState() {
        centralManager.delegate = self
        handleBluetoothSetState(state: centralManager.currentState)
    }
    
    func didTapSend(with text: String) {
        guard !text.isEmpty, let pineID = pineID else { return }
        
        currentlySendingMessage = text

        view?.showPopover(with: .init(text: "Отправка сообщения..."))
        
        let connection = PineConnection(pineID: pineID, centralManagerService: centralManager)
        connection.delegate = self
        connection.sendMessage(text: text)
        pineConnection = connection
    }
    
    func didTapARButton() {
        guard let pineID = pineID else { return }
        let presenter = ARLoaderPresenter(pineID: pineID, manager: centralManager)
        let viewController = ARLoaderViewController(presenter: presenter)
        presenter.view = viewController
        view?.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func showBluetoothFail(reason: BluetoothState.DisabledReason) {
        view?.showPopover(with: .init(text: textForDisabledReason(reason: reason)))
    }
    
    private func textForDisabledReason(reason: BluetoothState.DisabledReason) -> String {
        switch reason {
        case .disabled:
            return "Включите bluetooth"
        case .unsupported:
            return "К сожалению, ваше устройство не поддерживается :("
        case .unauthorized:
            return "Для работы приложения необходимо разрешение на использование bluetooth"
        }
    }
    
    private func handleBluetoothSetState(state: BluetoothState) {
        switch state {
        case .enabled:
            handleBluetoothEnabled()
        case let .disabled(disabledReason):
            showBluetoothFail(reason: disabledReason)
        }
    }
    
    private func handleBluetoothEnabled() {
        if !isPineFound {
            startRescan()
            return
        }
        
        if !isMessagesLoaded {
            startMessagesLoading()
            return
        }
        
        view?.hidePopover()
    }
    
    private func handlePineFound() {
        if !isMessagesLoaded {
            startMessagesLoading()
        }
    }
    
    private func startRescan() {
        pineID = nil
        messages = nil
        view?.showPopover(with: .init(text: "Идёт поиск сосны..."))
        centralManager.rescan()
    }
    
    private func startMessagesLoading() {
        messages = nil
        guard let pineID = pineID else { return }
        
        view?.showPopover(with: .init(text: "Загрузка сообщений..."))

        let connection = PineConnection(pineID: pineID, centralManagerService: centralManager)
        connection.delegate = self
        connection.requestMessages()
        pineConnection = connection
    }
}

extension ChatPresenter: CentralManagerServiceDelegate {
    func centralManagerRescanComplete() {
        guard !isPineFound else { return }
        view?.showPopover(with: .init(
            text: "К сожалению, сосну найти не удалось, но можно попробовать ещё раз",
            buttonText: "Попробовать ещё раз",
            buttonAction: { [weak self] in self?.startRescan() }
        ))
    }
    
    func centralManagerRescanFailed() {}
    
    func centralManagerBluetoothStateChanged(newState: BluetoothState) {
        handleBluetoothSetState(state: newState)
    }
    
    func centralManagerDeviceUpdated(id: PeripheralID) {
        if pineID == nil {
            pineID = id
            handlePineFound()
        }
    }
}

extension ChatPresenter: PineConnectionDelegate {
    
    func messagesReceived(list: [Message]?) {
        if let list = list {
            messages = list
            view?.updateMessages(messages: (messages ?? []).map { .init(text: $0.text) })
            view?.hidePopover()
            return
        }
        
        view?.showPopover(with: .init(
            text: "К сожалению, не удалось загрузить сообщения, но можно попробовать ещё раз",
            buttonText: "Попробовать ещё раз",
            buttonAction: { [weak self] in self?.startRescan() }
        ))
    }
    
    func messageSent(isSuccess: Bool) {
        guard !isSuccess else {
            messages?.append(.init(text: currentlySendingMessage ?? ""))
            currentlySendingMessage = nil
            
            view?.resetInput()
            view?.updateMessages(messages: (messages ?? []).map { .init(text: $0.text) })
            view?.hidePopover()
            return
        }
        
        currentlySendingMessage = nil
        view?.showPopover(with: .init(
            text: "К сожалению, не удалось отправить сообщение, но можно попробовать ещё раз",
            buttonText: "Ок",
            buttonAction: { [weak self] in self?.startRescan() }
        ))
    }
    
    func downloadProgressUpdated(totalSize: Int, loaded: Int) {}
    func imagesCountReceived(count: Int?) {}
    func imageReceived(imageData: ImageData?) {}
    func uploadProgressUpdated(totalSize: Int, loaded: Int) {}
    func imageUploaded(isSuccess: Bool) {}
    func worldDownloaded(data: Data?) {}
}
