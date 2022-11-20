//
//  PineDataStorage.swift
//  BlueStationTest
//
//  Created by Анастасия Ступникова on 19.11.2022.
//

import Foundation

struct StoredImageData {
    let transform: Data
    let image: Data
}

private struct ImageMetaData: Codable {
    let transform: Data
    let path: String
}

private struct StorageData: Codable {
    let messages: [Message]
    let imagesMetaData: [ImageMetaData]
}

final class PineDataStorage {

    private var messagesList: [Message] = []
    private var imagesMetaData: [ImageMetaData] = []
    
    private let fileManager = FileManager.default
    private lazy var filesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
    
    private lazy var worldMapPath: String = filesDirectory.appendingPathExtension("worldMap.bin").path
    private lazy var metadataPath: String = filesDirectory.appendingPathExtension("metadata.bin").path
    
    init() {
        guard let data = fileManager.contents(atPath: metadataPath) else { return }
        let decoder = JSONDecoder()
        guard let storageData = try? decoder.decode(StorageData.self, from: data) else { return }
        messagesList = storageData.messages
        imagesMetaData = storageData.imagesMetaData
    }
    
    var imagesCount: Int { imagesMetaData.count }
    
    func getMessages() -> [Message] { messagesList }
    
    func addMessage(message: Message) {
        messagesList.append(message)
        saveData()
    }
    
    func getWorldData() -> Data {
        fileManager.contents(atPath: worldMapPath)!
    }
    
    func addImage(imageData: StoredImageData) {
        let imagePath = filesDirectory.appendingPathExtension("image-\(UUID()).bin").path
        fileManager.createFile(atPath: imagePath, contents: imageData.image)
        imagesMetaData.append(.init(transform: imageData.transform, path: imagePath))
        saveData()
    }
    
    func getImageData(by index: Int) -> StoredImageData? {
        guard index >= 0, index < imagesMetaData.count else { return nil }
        guard let data = fileManager.contents(atPath: imagesMetaData[index].path) else { return nil }
        return .init(transform: imagesMetaData[index].transform, image: data)
    }
    
    func createWorldMap(data: Data) {
        fileManager.createFile(atPath: worldMapPath, contents: data)
    }
    
    func getWorldMapSize() -> Int? {
        let attributes = try? fileManager.attributesOfItem(atPath: worldMapPath)
        return attributes?[FileAttributeKey.size] as? Int
    }
    
    func clear() {
        try? fileManager.removeItem(atPath: worldMapPath)
        
        imagesMetaData.forEach {
            try? fileManager.removeItem(atPath: $0.path)
        }
        
        try? fileManager.removeItem(atPath: metadataPath)
        
        imagesMetaData = []
        messagesList = []
    }
    
    private func saveData() {
        let storageData = StorageData(messages: messagesList, imagesMetaData: imagesMetaData)
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(storageData) else {
            fatalError("Encoding failed")
        }
        
        fileManager.createFile(atPath: metadataPath, contents: data)
    }
}
