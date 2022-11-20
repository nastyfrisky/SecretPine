//
//  CentralManagerService.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 18.11.2022.
//

import CoreBluetooth

enum BluetoothState {
    enum DisabledReason {
        case disabled
        case unsupported
        case unauthorized
    }
    
    case enabled
    case disabled(DisabledReason)
    
    init(from state: CBManagerState) {
        switch state {
        case .unsupported:
            self = .disabled(.unsupported)
        case .unauthorized:
            self = .disabled(.unauthorized)
        case .poweredOff, .resetting:
            self = .disabled(.disabled)
        case .poweredOn:
            self = .enabled
        default:
            self = .disabled(.unsupported)
        }
    }
}

protocol CentralManagerServiceDelegate: AnyObject {
    func centralManagerRescanComplete()
    func centralManagerRescanFailed()
    func centralManagerBluetoothStateChanged(newState: BluetoothState)
    func centralManagerDeviceUpdated(id: PeripheralID)
}

enum ConnectionError: Error {
    case busy
    case notExists
    case bluetoothDisabled
}

protocol CentralManagerService: AnyObject {
    var delegate: CentralManagerServiceDelegate? { get set }
    var devices: [PeripheralID] { get }
    var currentState: BluetoothState { get }
    func rescan()
    func connect(id: PeripheralID) -> Result<BluetoothConnection, ConnectionError>
}

final class CentralManagerServiceImpl: NSObject {
    weak var delegate: CentralManagerServiceDelegate?
    
    private var optionalCentralManager: CBCentralManager?
    private var centralManager: CBCentralManager {
        if let manager = optionalCentralManager { return manager }
        let manager = CBCentralManager(delegate: self, queue: nil)
        optionalCentralManager = manager
        return manager
    }
    
    private var currentBluetoothState: BluetoothState = .disabled(.disabled)
    private var scanTimer: Timer?
    
    private var peripheralDataMap: [CBPeripheral: PeripheralData] = [:]
    private var dataPeripheralMap: [PeripheralData: CBPeripheral] = [:]
    private var connectionsMap: [CBPeripheral: BluetoothConnection] = [:]
    
    override init() {
        super.init()
        optionalCentralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    private func handleEnabledDisabledTransition() {
        if let scanTimer = scanTimer {
            self.scanTimer = nil
            scanTimer.invalidate()
            delegate?.centralManagerRescanFailed()
        }
        
        connectionsMap.forEach { $0.value.managerClose(reason: .bluetoothDisabled) }
        connectionsMap.removeAll()
    }
    
    private func actualizePeripheral(peripheral: CBPeripheral) {
        if let peripheralData = peripheralDataMap[peripheral] {
            peripheralData.lastActivity = Date()
            delegate?.centralManagerDeviceUpdated(id: peripheralData)
            return
        }
        
        let peripheralData = PeripheralData(name: peripheral.name ?? "Unnamed")
        peripheralDataMap[peripheral] = peripheralData
        dataPeripheralMap[peripheralData] = peripheral
        delegate?.centralManagerDeviceUpdated(id: peripheralData)
    }
}

extension CentralManagerServiceImpl: CentralManagerService {

    var devices: [PeripheralID] { dataPeripheralMap.map { $0.key } }
    var currentState: BluetoothState { currentBluetoothState }
    
    func rescan() {
        guard centralManager.state == .poweredOn else {
            delegate?.centralManagerRescanFailed()
            return
        }
        
        centralManager.scanForPeripherals(withServices: [CBUUID(nsuuid: UUID(
            uuidString: "C12E0A2A-1E4A-4124-AB7A-66ADE79633BC"
        )!)])

        scanTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: { [weak self] timer in
            self?.scanTimer = nil
            self?.centralManager.stopScan()
            self?.delegate?.centralManagerRescanComplete()
        })
    }
    
    func connect(id: PeripheralID) -> Result<BluetoothConnection, ConnectionError> {
        guard centralManager.state == .poweredOn else { return .failure(.bluetoothDisabled) }
        guard let peripheralData = id as? PeripheralData, let peripheral = dataPeripheralMap[peripheralData] else {
            return .failure(.notExists)
        }
        
        guard connectionsMap[peripheral] == nil else { return .failure(.busy) }
        
        let connection = BluetoothConnection(peripheral: peripheral, centralManager: centralManager)
        connectionsMap[peripheral] = connection
        connection.manager = self
        return .success(connection)
    }
}

extension CentralManagerServiceImpl: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let oldState = currentBluetoothState
        currentBluetoothState = BluetoothState(from: central.state)
        
        if case .enabled = oldState, case .disabled = currentBluetoothState {
            handleEnabledDisabledTransition()
        }
        
        delegate?.centralManagerBluetoothStateChanged(newState: currentBluetoothState)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        actualizePeripheral(peripheral: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard let connection = connectionsMap[peripheral] else {
            fatalError("No connection in map")
        }
        
        connection.managerClose(reason: .failed)
        connectionsMap.removeValue(forKey: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let connection = connectionsMap[peripheral] else { return }
        connection.didConnect()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard let connection = connectionsMap[peripheral] else { return }
        connectionsMap.removeValue(forKey: peripheral)
        connection.managerClose(reason: .disconnected)
    }
}

extension CentralManagerServiceImpl: BluetoothConnectionManagerOutput {
    func connectionClosed(_ connection: BluetoothConnection, peripheral: CBPeripheral) {
        guard connectionsMap[peripheral] == connection else {
            fatalError("No connection in map or connections not equal")
        }

        connectionsMap.removeValue(forKey: peripheral)
        centralManager.cancelPeripheralConnection(peripheral)
    }
}
