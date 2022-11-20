//
//  RequestExecutor.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 19.11.2022.
//

import Foundation

protocol RequestExecutorDelegate: AnyObject {
    func didExecute(with response: Data)
    func didFailed()
    func downloadProgressUpdated(totalSize: Int, loaded: Int)
    func uploadProgressUpdated(totalSize: Int, loaded: Int)
}

final class RequestExecutor {
    
    weak var delegate: RequestExecutorDelegate?
    
    private var leftAttemptsCount = 5
    
    private let peripheralID: PeripheralID
    private let manager: CentralManagerService
    private var currentConnection: BluetoothConnection?
    private let requestData: Data
    
    private var receiveTimeout: Timer?
    private var receivedData: Data = Data()
    
    init(id: PeripheralID, manager: CentralManagerService, requestData: Data) {
        self.peripheralID = id
        self.manager = manager
        self.requestData = requestData
    }
    
    func startExecution() {
        restartExecution()
    }
    
    func cancelExecution() {
        currentConnection?.close()
    }
    
    private func restartExecution() {
        reconnect()
    }
    
    private func reconnect() {
        currentConnection = nil
        receivedData = Data()
        let result = manager.connect(id: peripheralID)
        switch result {
        case let .success(connection):
            currentConnection = connection
            connection.delegate = self
        case .failure:
            delegate?.didFailed()
        }
    }
    
    private func onTimeout() {
        receiveTimeout = nil
        currentConnection?.close()
        connectionClosed(reason: .timeout)
    }
    
    private func getDataSize() -> Int? {
        let size = MemoryLayout<Int32>.size
        guard receivedData.count >= size else { return nil }
        return Int(receivedData.prefix(size).withUnsafeBytes { $0.load(as: Int32.self) })
    }
    
    private func checkReceiveCompletion() -> Bool {
        guard let dataSize = getDataSize() else { return false }
        return receivedData.count - MemoryLayout<Int32>.size == dataSize
    }
    
    deinit {
        currentConnection?.close()
    }
}

extension RequestExecutor: BluetoothConnectionDelegate {
    func didConnect() {
        var count = Int32(requestData.count)
        let dataSize = Data(bytes: &count, count: MemoryLayout.size(ofValue: count))
        currentConnection?.sendData(data: dataSize)
        currentConnection?.sendData(data: requestData)
    }
    
    func didReceivedData(_ data: Data) {
        receivedData.append(contentsOf: data)
        receiveTimeout?.invalidate()
        
        if let dataSize = getDataSize() {
            delegate?.downloadProgressUpdated(totalSize: dataSize, loaded: receivedData.count)
        }
        
        guard !checkReceiveCompletion() else {
            currentConnection?.close()
            delegate?.didExecute(with: receivedData.dropFirst(4))
            return
        }
        
        receiveTimeout = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { [weak self] _ in
            self?.onTimeout()
        })
    }
    
    func didSentAllData() {
        receiveTimeout?.invalidate()
        receiveTimeout = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { [weak self] _ in
            self?.onTimeout()
        })
    }
    
    func didSentData() {
        delegate?.uploadProgressUpdated(
            totalSize: requestData.count,
            loaded: requestData.count - (currentConnection?.scheduledCount ?? 0)
        )
    }
    
    func connectionClosed(reason: BluetoothConnectionCloseReason) {
        if case .bluetoothDisabled = reason {
            receiveTimeout?.invalidate()
            delegate?.didFailed()
            return
        }
        
        leftAttemptsCount -= 1
        guard leftAttemptsCount > 0 else {
            receiveTimeout?.invalidate()
            delegate?.didFailed()
            return
        }
        
        restartExecution()
    }
}
