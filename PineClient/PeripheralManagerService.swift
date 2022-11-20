//
//  PeripheralManagerService.swift
//  BlueStationTest
//
//  Created by Анастасия Ступникова on 18.11.2022.
//

import CoreBluetooth

protocol PeripheralManagerServiceDelegate: AnyObject {
    
}

final class PeripheralManagerService: NSObject {
    weak var delegate: PeripheralManagerServiceDelegate?
    
    private var centralChannelIDMap: [CBCentral: CBL2CAPPSM] = [:]
    private var channelIDChannelMap: [CBL2CAPPSM: PineStreamService] = [:]
    private var freeChannelID: CBL2CAPPSM?
    
    private var optionalPeripheralManager: CBPeripheralManager?
    private var peripheralManager: CBPeripheralManager {
        if let manager = optionalPeripheralManager { return manager }
        let manager = CBPeripheralManager(delegate: self, queue: nil)
        optionalPeripheralManager = manager
        return manager
    }
    
    private let pineDataStorage: PineDataStorage
    
    init(pineDataStorage: PineDataStorage) {
        self.pineDataStorage = pineDataStorage
        super.init()
        optionalPeripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    private func startAdvertising() {
        let serviceUUID = CBUUID(nsuuid: UUID(uuidString: "C12E0A2A-1E4A-4124-AB7A-66ADE79633BC")!)
        
        let freeChannelCharacteristic = CBMutableCharacteristic(
            type: CBUUID(nsuuid: UUID(uuidString: "5E1CE312-A4FD-4D02-A9BC-9D56B28FC351")!),
            properties: [.read],
            value: nil,
            permissions: [.readable]
        )
        
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [freeChannelCharacteristic]
        peripheralManager.add(service)
        
        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey: "Pine",
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID]
        ])
        
        peripheralManager.publishL2CAPChannel(withEncryption: false)
    }
    
    private func getChannel(for central: CBCentral) -> CBL2CAPPSM? {
//        if let channelID = centralChannelIDMap[central] {
//            peripheralManager.unpublishL2CAPChannel(channelID)
//        }

        let channelID = freeChannelID
        freeChannelID = nil
        peripheralManager.publishL2CAPChannel(withEncryption: false)
        
        if let channelID = channelID {
            centralChannelIDMap[central] = channelID
        }
        
        return channelID
    }
}

extension PeripheralManagerService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            startAdvertising()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard var channelID = getChannel(for: request.central) else {
            peripheral.respond(to: request, withResult: .requestNotSupported)
            return
        }
        
        request.value = Data(bytes: &channelID, count: MemoryLayout<UInt16>.size)
        peripheral.respond(to: request, withResult: .success)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        freeChannelID = PSM
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
        guard let channel = channel else {
            return
        }
        
        channelIDChannelMap[channel.psm] = PineStreamService(channel: channel, dataStorage: pineDataStorage)
        print("Opened channel #\(channel.psm)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didUnpublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        print("Unpublish channel #\(PSM)")
    }
}
