//
//  PineStreamService.swift
//  BlueStationTest
//
//  Created by Анастасия Ступникова on 19.11.2022.
//

import CoreBluetooth

private enum QueryType: Int {
    case getMessages
    case sendMessage
    case downloadWorld
    case requestImagesCount
    case downloadImage
    case uploadImage
}

final class PineStreamService: NSObject {
    
    private var channel: CBL2CAPChannel
    
    private var receivedData: Data = Data()
    private var dataToSend: Data = Data()
    private let pineDataStorage: PineDataStorage
    
    init(channel: CBL2CAPChannel, dataStorage: PineDataStorage) {
        self.channel = channel
        self.pineDataStorage = dataStorage
        super.init()
        
        channel.inputStream.delegate = self
        channel.outputStream.delegate = self
        channel.inputStream.schedule(in: .current, forMode: .default)
        channel.outputStream.schedule(in: .current, forMode: .default)
        channel.inputStream.open()
        channel.outputStream.open()
    }
    
    deinit {
        channel.inputStream.close()
        channel.outputStream.close()
        channel.inputStream.remove(from: .current, forMode: .default)
        channel.outputStream.remove(from: .current, forMode: .default)
    }
    
    private func readData() {
        guard let stream = channel.inputStream else { return }
        
        let bufferSize = 65536
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        
        let dataCountBeforeRead = receivedData.count
        
        repeat {
            let readed = stream.read(buffer, maxLength: bufferSize)
            let data = NSData(bytes: buffer, length: readed)
            receivedData.append(contentsOf: data)
        } while stream.hasBytesAvailable
        
        buffer.deallocate()
        
        if receivedData.count > dataCountBeforeRead {
            handleReceivedData()
        }
    }
    
    private func handleReceivedData() {
        let size = MemoryLayout<Int32>.size
        guard receivedData.count >= size else { return }
        let dataSize = Data(receivedData.prefix(size)).withUnsafeBytes { $0.load(as: Int32.self) }
        guard receivedData.count - size == dataSize else { return }
        handleRequest()
    }
    
    private func handleRequest() {
        var data = receivedData.dropFirst(4)
        guard let queryType = decodeQueryType(data: &data) else { return }
        
        switch queryType {
        case .getMessages:
            handleGetMessages()
        case .sendMessage:
            handleSendMessage(data: data)
        case .downloadWorld:
            handleDownloadWorld()
        case .requestImagesCount:
            handleRequestImagesCount()
        case .downloadImage:
            handleDownloadImage(data: data)
        case .uploadImage:
            handleUploadImage(data: data)
        }
    }
    
    private func handleGetMessages() {
        var data = Data()
        encode(messages: pineDataStorage.getMessages(), to: &data)
        sendData(data: data)
    }
    
    private func handleSendMessage(data: Data) {
        var data = data
        
        guard let messageText = decodeString(data: &data) else {
            var response = Data()
            encode(int: 555, to: &response)
            sendData(data: response)
            return
        }
        
        pineDataStorage.addMessage(message: .init(text: messageText))
        
        var response = Data()
        encode(int: 1337, to: &response)
        sendData(data: response)
    }
    
    private func handleDownloadWorld() {
        sendData(data: pineDataStorage.getWorldData())
    }
    
    private func handleRequestImagesCount() {
        var data = Data()
        encode(int: pineDataStorage.imagesCount, to: &data)
        sendData(data: data)
    }
    
    private func handleDownloadImage(data: Data) {
        var data = data
        
        guard
            let imageIndex = decodeInt(data: &data),
            let imageData = pineDataStorage.getImageData(by: imageIndex)
        else {
            var response = Data()
            encode(int: 555, to: &response)
            sendData(data: response)
            return
        }
        
        var response = Data()
        encode(int: 1337, to: &response)
        encode(data: imageData.transform, to: &response)
        encode(data: imageData.image, to: &response)
        sendData(data: response)
    }
    
    private func handleUploadImage(data: Data) {
        var data = data
        guard
            let transformData = decodeData(data: &data),
            let imageData = decodeData(data: &data)
        else {
            var response = Data()
            encode(int: 555, to: &response)
            sendData(data: response)
            return
        }
        
        pineDataStorage.addImage(imageData: .init(transform: transformData, image: imageData))
        
        var response = Data()
        encode(int: 1337, to: &response)
        sendData(data: response)
    }
    
    private func decodeQueryType(data: inout Data) -> QueryType? {
        guard let queryRawType = decodeInt(data: &data) else { return nil }
        return QueryType(rawValue: queryRawType)
    }
    
    private func decodeString(data: inout Data) -> String? {
        guard let length = decodeInt(data: &data) else { return nil }
        let result = String(decoding: data.prefix(length), as: UTF8.self)
        data = data.dropFirst(length)
        return result
    }
    
    private func decodeInt(data: inout Data) -> Int? {
        let size = MemoryLayout<Int32>.size
        guard data.count >= size else { return nil }
        let result = Data(data.prefix(size)).withUnsafeBytes { $0.load(as: Int32.self) }
        data = data.dropFirst(size)
        return Int(result)
    }
    
    private func decodeData(data: inout Data) -> Data? {
        guard let dataSize = decodeInt(data: &data) else { return nil }
        guard data.count >= dataSize else { return nil }
        let result = Data(data.prefix(dataSize))
        data = data.dropFirst(dataSize)
        return result
    }
    
    private func encode(messages: [Message], to data: inout Data) {
        encode(int: messages.count, to: &data)
        messages.forEach { encode(message: $0, to: &data) }
    }
    
    private func encode(message: Message, to data: inout Data) {
        encode(string: message.text, to: &data)
    }
    
    private func encode(string: String, to data: inout Data) {
        let stringData = string.data(using: .utf8)!
        encode(int: stringData.count, to: &data)
        data.append(contentsOf: stringData)
    }
    
    private func encode(int: Int, to data: inout Data) {
        var int = Int32(int)
        data.append(contentsOf: Data(
            bytes: &int,
            count: MemoryLayout.size(ofValue: int)
        ))
    }
        
    private func encode(data: Data, to buffer: inout Data) {
        encode(int: data.count, to: &buffer)
        buffer.append(data)
    }
    
    private func sendData(data: Data) {
        var sizeData = Data()
        encode(int: data.count, to: &sizeData)
        
        dataToSend.append(contentsOf: sizeData)
        dataToSend.append(contentsOf: data)
        sendData()
    }
    
    private func sendData() {
        guard !dataToSend.isEmpty else { return }
        guard let stream = channel.outputStream else { return }
        guard stream.hasSpaceAvailable else { return }
        
        let dataToSend = self.dataToSend as NSData
        let written = stream.write(dataToSend.bytes, maxLength: dataToSend.count)
        
        guard written != -1 else { return }
        
        self.dataToSend = self.dataToSend.dropFirst(written)
    }
}

extension PineStreamService: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            print("Stream open completed")
        case .hasSpaceAvailable: sendData()
        case .hasBytesAvailable: readData()
        default: break
        }
    }
}
