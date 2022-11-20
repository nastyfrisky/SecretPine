//
//  BluetoothConnection.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 18.11.2022.
//

import CoreBluetooth

enum BluetoothConnectionCloseReason {
    case bluetoothDisabled
    case timeout
    case failed
    case disconnected
}

protocol BluetoothConnectionDelegate: AnyObject {
    func didConnect()
    func didReceivedData(_ data: Data)
    func didSentAllData()
    func didSentData()
    func connectionClosed(reason: BluetoothConnectionCloseReason)
}

private enum State {
    case connecting
    case discoveringServices
    case discoveringCharacteristics
    case readingChannelID
    case openingChannel
    case connected
    case closed
}

protocol BluetoothConnectionManagerOutput: AnyObject {
    func connectionClosed(_ connection: BluetoothConnection, peripheral: CBPeripheral)
}

final class BluetoothConnection: NSObject {
    weak var delegate: BluetoothConnectionDelegate?
    weak var manager: BluetoothConnectionManagerOutput?
    
    var scheduledCount: Int { dataQueue.count }
    
    private var peripheral: CBPeripheral
    private var channelCharacteristic: CBCharacteristic?
    private var channel: CBL2CAPChannel?
    private var state: State = .connecting
    private var dataQueue: Data = Data()
    private var totalTransmitted: Int = 0 {
        didSet {
//            print("Transmitted: \(totalTransmitted)")
        }
    }
    
    private var timeoutTimer: Timer?
    
    init(peripheral: CBPeripheral, centralManager: CBCentralManager) {
        self.peripheral = peripheral
        super.init()
        peripheral.delegate = self
        centralManager.connect(peripheral)
        setTimeout(interval: 3)
    }
    
    func didConnect() {
        guard case .connecting = state else {
            fatalError("DidConnect with incorrect state")
        }

        clearTimeout()
        startServicesDiscovering()
    }
    
    func managerClose(reason: BluetoothConnectionCloseReason) {
        if case .closed = state {
            fatalError("Close when already closed")
        }
        
        clearTimeout()
        clearChannel()
        state = .closed
        delegate?.connectionClosed(reason: reason)
    }
    
    func sendData(data: Data) {
        dataQueue.append(contentsOf: data)
        writeData()
    }
    
    func close() {
        if case .closed = state { return }
        clearTimeout()
        clearChannel()
        state = .closed
        manager?.connectionClosed(self, peripheral: peripheral)
    }
    
    private func writeData() {
        guard dataQueue.count > 0 else { return }
        guard let stream = channel?.outputStream else { return }
        guard stream.hasSpaceAvailable else { return }
        
        let dataQueue = self.dataQueue as NSData
        let written = stream.write(dataQueue.bytes, maxLength: dataQueue.count)
        
        guard written != -1 else {
            closeWithFail()
            return
        }
        
        self.dataQueue = self.dataQueue.dropFirst(written)
        self.totalTransmitted += written
        
        self.delegate?.didSentData()
        
        if dataQueue.isEmpty {
            delegate?.didSentAllData()
        }
    }
    
    private func readData() {
        guard let stream = channel?.inputStream else { return }
        
        let bufferSize = 65536
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        
        repeat {
            let readed = stream.read(buffer, maxLength: bufferSize)
            let data = NSData(bytes: buffer, length: readed)
            delegate?.didReceivedData(data as Data)
        } while stream.hasBytesAvailable
    }
    
    private func closeWithFail() {
        close()
        delegate?.connectionClosed(reason: .failed)
    }
    
    private func setTimeout(interval: TimeInterval) {
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false, block: { [weak self] timer in
            self?.handleTimeout()
        })
    }
    
    private func clearTimeout() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
    private func clearChannel() {
        guard let channel = channel else { return }
        
        channel.inputStream.close()
        channel.outputStream.close()
        channel.inputStream.remove(from: .current, forMode: .default)
        channel.outputStream.remove(from: .current, forMode: .default)
        
        self.channel = nil
    }
    
    private func handleTimeout() {
        if case .closed = state {
            fatalError("Timeout with incorrect state")
        }
        
        state = .closed
        timeoutTimer = nil
        manager?.connectionClosed(self, peripheral: peripheral)
        delegate?.connectionClosed(reason: .timeout)
    }
    
    private func startServicesDiscovering() {
        state = .discoveringServices
        let uuid = CBUUID(nsuuid: UUID(uuidString: "C12E0A2A-1E4A-4124-AB7A-66ADE79633BC")!)
        peripheral.discoverServices([uuid])
        setTimeout(interval: 1)
    }
    
    private func startCharacteristicsDiscovering() {
        guard let service = peripheral.services?.first else {
            closeWithFail()
            return
        }
        
        state = .discoveringCharacteristics
        peripheral.discoverCharacteristics([
            CBUUID(nsuuid: UUID(uuidString: "5E1CE312-A4FD-4D02-A9BC-9D56B28FC351")!)
        ], for: service)
        setTimeout(interval: 1)
    }
    
    private func startReadingChannelID() {
        guard let channelCharacteristic = channelCharacteristic else {
            fatalError("Channel is nil")
        }
        
        state = .readingChannelID
        peripheral.readValue(for: channelCharacteristic)
        setTimeout(interval: 1)
    }
}

extension BluetoothConnection: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard case .discoveringServices = state else {
            fatalError("didDiscoverServices with wrong state")
        }

        clearTimeout()
        startCharacteristicsDiscovering()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard case .discoveringCharacteristics = state else {
            fatalError("didDiscoverCharacteristics with wrong state")
        }
        
        clearTimeout()
        
        guard let characteristic = service.characteristics?.first else {
            closeWithFail()
            return
        }
        
        channelCharacteristic = characteristic
        startReadingChannelID()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else {
            closeWithFail()
            return
        }
        
        clearTimeout()
        
        let channelID = data.withUnsafeBytes { $0.load(as: UInt16.self) }
        print("Opening channel \(channelID)")
        state = .openingChannel
        peripheral.openL2CAPChannel(channelID)
        setTimeout(interval: 1)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        guard let channel = channel, error == nil else {
            closeWithFail()
            return
        }

        clearTimeout()
        
        channel.inputStream.delegate = self
        channel.outputStream.delegate = self
        channel.inputStream.schedule(in: .current, forMode: .default)
        channel.outputStream.schedule(in: .current, forMode: .default)
        channel.inputStream.open()
        channel.outputStream.open()
        
        self.channel = channel
        state = .connected
        delegate?.didConnect()
    }
}

extension BluetoothConnection: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasSpaceAvailable: writeData()
        case .hasBytesAvailable: readData()
        case .errorOccurred: print("error occurred")
        default: break
        }
    }
}
