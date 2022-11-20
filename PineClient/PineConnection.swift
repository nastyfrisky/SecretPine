//
//  PineConnection.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 19.11.2022.
//

import UIKit

protocol PineConnectionDelegate: AnyObject {
    func messagesReceived(list: [Message]?)
    func messageSent(isSuccess: Bool)
    func worldDownloaded(data: Data?)
    func imagesCountReceived(count: Int?)
    func imageReceived(imageData: ImageData?)
    func downloadProgressUpdated(totalSize: Int, loaded: Int)
    func uploadProgressUpdated(totalSize: Int, loaded: Int)
    func imageUploaded(isSuccess: Bool)
}

struct Message: Codable {
    let text: String
}

private enum QueryType: Int {
    case getMessages
    case sendMessage
    case downloadWorld
    case requestImagesCount
    case downloadImage
    case uploadImage
}

final class PineConnection {
    
    weak var delegate: PineConnectionDelegate?
    
    private let pineID: PeripheralID
    private let centralManagerService: CentralManagerService
    private var requestExecutor: RequestExecutor?
    
    private var currentQueryType: QueryType!
    
    init(pineID: PeripheralID, centralManagerService: CentralManagerService) {
        self.pineID = pineID
        self.centralManagerService = centralManagerService
    }
    
    func requestMessages() {
        currentQueryType = .getMessages
        
        var data = Data()
        encode(queryType: .getMessages, to: &data)
        
        let requestExecutor = RequestExecutor(id: pineID, manager: centralManagerService, requestData: data)
        requestExecutor.delegate = self
        self.requestExecutor?.cancelExecution()
        self.requestExecutor = requestExecutor
        requestExecutor.startExecution()
    }
    
    func sendMessage(text: String) {
        currentQueryType = .sendMessage
        
        var data = Data()
        encode(queryType: .sendMessage, to: &data)
        encode(string: text, to: &data)
        
        let requestExecutor = RequestExecutor(id: pineID, manager: centralManagerService, requestData: data)
        requestExecutor.delegate = self
        self.requestExecutor?.cancelExecution()
        self.requestExecutor = requestExecutor
        requestExecutor.startExecution()
    }
    
    func downloadWorld() {
        currentQueryType = .downloadWorld
        
        var data = Data()
        encode(queryType: .downloadWorld, to: &data)
        
        let requestExecutor = RequestExecutor(id: pineID, manager: centralManagerService, requestData: data)
        requestExecutor.delegate = self
        self.requestExecutor?.cancelExecution()
        self.requestExecutor = requestExecutor
        requestExecutor.startExecution()
    }
    
    func requestImagesCount() {
        currentQueryType = .requestImagesCount
        
        var data = Data()
        encode(queryType: .requestImagesCount, to: &data)
        
        let requestExecutor = RequestExecutor(id: pineID, manager: centralManagerService, requestData: data)
        requestExecutor.delegate = self
        self.requestExecutor?.cancelExecution()
        self.requestExecutor = requestExecutor
        requestExecutor.startExecution()
    }
    
    func downloadImage(with index: Int) {
        currentQueryType = .downloadImage
        
        var data = Data()
        encode(queryType: .downloadImage, to: &data)
        encode(int: index, to: &data)
        
        let requestExecutor = RequestExecutor(id: pineID, manager: centralManagerService, requestData: data)
        requestExecutor.delegate = self
        self.requestExecutor?.cancelExecution()
        self.requestExecutor = requestExecutor
        requestExecutor.startExecution()
    }
    
    func uploadImage(imageData: ImageData) {
        currentQueryType = .uploadImage
        
        guard
            let resizedImage = resizeImage(image: imageData.image),
            let resizedImageData = resizedImage.jpegData(compressionQuality: 0.5)
        else {
            didFailed()
            return
        }
        
        var data = Data()
        encode(queryType: .uploadImage, to: &data)
        encode(data: imageData.transform, to: &data)
        encode(data: resizedImageData, to: &data)
        
        let requestExecutor = RequestExecutor(id: pineID, manager: centralManagerService, requestData: data)
        requestExecutor.delegate = self
        self.requestExecutor?.cancelExecution()
        self.requestExecutor = requestExecutor
        requestExecutor.startExecution()
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
    
    private func decodeMessage(data: inout Data) -> Message? {
        guard let text = decodeString(data: &data) else { return nil }
        return Message(text: text)
    }
    
    private func decodeMessages(data: Data) -> [Message]? {
        var data = data

        guard let messagesCount = decodeInt(data: &data) else { return nil }
        
        var messages: [Message] = []
        for _ in 0..<messagesCount {
            guard let message = decodeMessage(data: &data) else { return nil }
            messages.append(message)
        }
        
        return messages
    }
    
    private func decodeImagesCount(data: Data) -> Int? {
        var data = data
        return decodeInt(data: &data)
    }
    
    private func decodeImageData(data: Data) -> ImageData? {
        var data = data
        
        guard let code = decodeInt(data: &data), code == 1337 else { return nil }
        guard let transformData = decodeData(data: &data) else { return nil }
        guard let imageData = decodeData(data: &data) else { return nil }
        guard let image = UIImage(data: imageData) else { return nil }
        
        return .init(transform: transformData, image: image)
    }
    
    private func decodeStatus(data: Data) -> Bool {
        var data = data
        guard let status = decodeInt(data: &data) else { return false }
        return status == 1337
    }
    
    private func decodeData(data: inout Data) -> Data? {
        guard let dataSize = decodeInt(data: &data) else { return nil }
        guard data.count >= dataSize else { return nil }
        let result = Data(data.prefix(dataSize))
        data = data.dropFirst(dataSize)
        return result
    }
    
    private func encode(data: Data, to buffer: inout Data) {
        encode(int: data.count, to: &buffer)
        buffer.append(data)
    }
    
    private func encode(int: Int, to data: inout Data) {
        var int = Int32(int)
        data.append(contentsOf: Data(
            bytes: &int,
            count: MemoryLayout.size(ofValue: int)
        ))
    }

    private func encode(string: String, to data: inout Data) {
        let stringData = string.data(using: .utf8)!
        encode(int: stringData.count, to: &data)
        data.append(contentsOf: stringData)
    }
    
    private func encode(queryType: QueryType, to data: inout Data) {
        encode(int: queryType.rawValue, to: &data)
    }
    
    private func resizeImage(image: UIImage) -> UIImage? {
        let size = image.size
        let targetSize = CGSize(width: 1000, height: 1000)
        
        guard max(size.width, size.height) > 1000 else { return image }
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

extension PineConnection: RequestExecutorDelegate {
    func didExecute(with response: Data) {
        switch currentQueryType {
        case .getMessages:
            delegate?.messagesReceived(list: decodeMessages(data: response))
        case .sendMessage:
            delegate?.messageSent(isSuccess: decodeStatus(data: response))
        case .downloadWorld:
            delegate?.worldDownloaded(data: response)
        case .requestImagesCount:
            delegate?.imagesCountReceived(count: decodeImagesCount(data: response))
        case .downloadImage:
            delegate?.imageReceived(imageData: decodeImageData(data: response))
        case .uploadImage:
            delegate?.imageUploaded(isSuccess: decodeStatus(data: response))
        case nil: break
        }
    }
    
    func didFailed() {
        switch currentQueryType {
        case .getMessages:
            delegate?.messagesReceived(list: nil)
        case .sendMessage:
            delegate?.messageSent(isSuccess: false)
        case .downloadWorld:
            delegate?.worldDownloaded(data: nil)
        case .requestImagesCount:
            delegate?.imagesCountReceived(count: nil)
        case .downloadImage:
            delegate?.imageReceived(imageData: nil)
        case .uploadImage:
            delegate?.imageUploaded(isSuccess: false)
        case nil: break
        }
    }
    
    func downloadProgressUpdated(totalSize: Int, loaded: Int) {
        delegate?.downloadProgressUpdated(totalSize: totalSize, loaded: loaded)
    }
    
    func uploadProgressUpdated(totalSize: Int, loaded: Int) {
        delegate?.uploadProgressUpdated(totalSize: totalSize, loaded: loaded)
    }
}
